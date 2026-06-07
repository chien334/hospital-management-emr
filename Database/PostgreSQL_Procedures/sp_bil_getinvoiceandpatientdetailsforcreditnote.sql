CREATE OR REPLACE FUNCTION sp_bil_getinvoiceandpatientdetailsforcreditnote(
    p_invoicenumber INT,
    p_fiscalyearid INT
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
    ref3 refcursor := 'cursor3';
    ref4 refcursor := 'cursor4';
    v_patientid INT;
    v_patientvisitid INT;
    v_billtxnid INT;
BEGIN
    /*
    filename: sp_bil_getinvoiceandpatientdetailsforcreditnote
    description: 
     * to get patientinformation, invoiceinformation, remaininginvoiceitems information 
        and alreadyreturned items information for credit note.
     * remaining invoice items is needed since we can only return the remaining qty if some qty is already returned.
     * returns four tables
    
    usage: exec sp_bil_getinvoiceandpatientdetailsforcreditnote 2,6
    change history
    s.no.    updatedby/date                        remarks
    1.      sud/1may'21                 Initial Draft
    2.		Krishna/19thNOV'21			made changes to get the settlementid and cashdisocunt from settlement table.
    3.		krishna/2jun'22				changed ProviderId to PerformerId and RequestedBy to PrescriberId
    4.		Krishna/23rdNov'22			read pricecategoryid, pricecategoryname, claimcode
    5.		krishna/9thapril'23			Change Join with PAT_CFG_MembershipType to BIL_CFG_Scheme
    6.      Sud/16Apr'23                rename itemid of invoicereturnitem to serviceitemid and it's impact handling
    7.		Krishna/25thApril'23		read isbillingcopayment as iscopayment
    8.		krishna/11thmay'23			Read CoPayCashAmount and CoPayCreditAmount from BillingTransactionItems table
    9.		Krishna/18thJune'23		    read organizationid in invoice information
    */
    
     
     
    
    select patientid, patientvisitid, billingtransactionid into v_patientid, v_patientvisitid, v_billtxnid from bil_txn_billingtransaction 
    where invoiceno=p_invoicenumber and fiscalyearid=p_fiscalyearid;
    
    --select v_patientid, v_patientvisitid, v_billtxnid
    
    open ref1 for select  
    pat.patientid, pat.patientcode, pat.shortname,
    pat.dateofbirth,pat.gender, cont.countryname, dist.countrysubdivisionname, pat.address
    from pat_patient pat  inner join mst_countrysubdivision dist
                             on pat.countrysubdivisionid=dist.countrysubdivisionid
                         inner join mst_country cont
    					   on dist.countryid=cont.countryid
    where patientid=v_patientid;
        return next ref1;
    
    open ref2 for select txn.patientid, txn.billingtransactionid, txn.invoicecode, txn.invoiceno, txn.paymentmode
    , txn.createdon as "invoicedate",  
    fy.fiscalyearformatted||'-'||txn.invoicecode||(txn.invoiceno)::varchar as "invoicenoformatted",
    txn.subtotal, txn.discountamount, txn.taxtotal, txn.totalamount, txn.billstatus,
    txn.transactiontype, txn.invoicetype, txn.isinsurancebilling, txn.insuranceproviderid,
    usr.username,coalesce(txn.settlementid,0) as "settlementid",
    coalesce(stl.discountamount,0) as "cashdiscount", scheme.schemeid,scheme.schemename, 
    pricecat.pricecategoryid, pricecat.pricecategoryname, txn.claimcode, scheme.isbillingcopayment as "iscopayment", txn.organizationid 
    
    from bil_txn_billingtransaction txn 
              inner join bil_cfg_fiscalyears fy on txn.fiscalyearid = fy.fiscalyearid
               inner join bil_cfg_scheme scheme on txn.schemeid = scheme.schemeid 
               left join bil_mst_credit_organization crorg
                    on txn.organizationid=crorg.organizationid
               left join rbac_user usr on txn.createdby=usr.employeeid
    		   
    		   left join bil_txn_settlements stl  on txn.settlementid = stl.settlementid
    		   left join pat_patientvisits visits  on visits.patientvisitid = txn.patientvisitid
    		   left join bil_cfg_pricecategory pricecat on pricecat.pricecategoryid = visits.pricecategoryid
    where billingtransactionid = v_billtxnid;
        return next ref2;
    
    open ref3 for select  
    	itm.billingtransactionitemid,
    	itm.billingtransactionid,
    	itm.patientid,
    	itm.servicedepartmentid,
    	itm.serviceitemid, --sud:16apr'23
    	itm.ItemCode,--sud:16Apr'23
    	itm.itemname,--sud:16apr'23
    	itm.Price,
    	itm.Quantity-COALESCE(ret.RetQuantity,0) AS "RemainingQty",
    	itm.Price*(itm.Quantity-COALESCE(ret.RetQuantity,0))  AS "SubTotal",
        itm.DiscountAmount/itm.Quantity AS "DiscountAmtPerUnit",
    	--Remaining DiscountAmt= DiscPerUnit * RemainingQty
        (itm.DiscountAmount/itm.Quantity)*(itm.Quantity-COALESCE(ret.RetQuantity,0)) AS "DiscountAmount",
    	COALESCE(itm.Tax,0)/itm.Quantity  AS "TaxAmtPerUnit",
    	(COALESCE(itm.Tax,0)/itm.Quantity)*(itm.Quantity-COALESCE(ret.RetQuantity,0)) AS "TaxAmount",
        itm.TotalAmount/itm.Quantity AS "TotalAmtPerUnit",
    	(itm.TotalAmount/itm.Quantity) * (itm.Quantity-COALESCE(ret.RetQuantity,0)) AS "TotalAmount",
    	itm.DiscountPercent,
    	itm.PerformerId,
    	itm.BillStatus,
    	itm.RequisitionId,
    	itm.RequisitionDate,
    	itm.PrescriberId,
    	itm.PatientVisitId,
    	itm.BillingPackageId,
    	itm.CreatedBy,
    	itm.CreatedOn,
    	itm.BillingType,
    	itm.RequestingDeptId,
    	itm.VisitType,
    	itm.PriceCategory,
    	itm.PriceCategoryId,--sud:16Apr'23
    	itm.patientinsurancepackageid,
    	itm.isinsurance,
    	itm.discountschemeid,
    	itm.labtypename,
    	itm.orderstatus,
    	itm.copaymentcashamount as "copaycashamount",
    	itm.copaymentcreditamount as "copaycreditamount"
    
    from bil_txn_billingtransactionitems itm 
      left join ( select billingtransactionitemid, sum(retquantity) as "retquantity" 
    	  from  bil_txn_invoicereturnitems 
    	  group by billingtransactionitemid
    	  ) ret
    
     on itm.billingtransactionitemid=ret.billingtransactionitemid
    where itm.billingtransactionid=v_billtxnid
    and (itm.quantity-coalesce(ret.retquantity,0)) > 0;
        return next ref3;  --remainingqty more than zero
    
     
     
    open ref4 for select crnote.billreturnid,
      crnote.createdon as "creditnotedate",
     crnote.creditnotenumber,
     crnote.fiscalyearid,
     fy.fiscalyearformatted||'-CR-'||(crnote.creditnotenumber)::varchar as "creditnotenumformatted",
    
     retitm.billingtransactionitemid,
     retitm.billingtransactionid,
     retitm.servicedepartmentid,
     retitm.serviceitemid,  --sud:16apr'23--columnname is changed now
     retitm.itemname,
     retitm.retquantity,
     retitm.retsubtotal,
     retitm.retdiscountamount,
     retitm.rettotalamount
    
    from bil_txn_invoicereturnitems retitm  
      inner join bil_txn_invoicereturn crnote 
           on retitm.billreturnid=crnote.billreturnid
     inner join bil_cfg_fiscalyears fy
         on crnote.fiscalyearid = fy.fiscalyearid
    where retitm.billingtransactionid = v_billtxnid;
        return next ref4;
END;
$$ LANGUAGE plpgsql;