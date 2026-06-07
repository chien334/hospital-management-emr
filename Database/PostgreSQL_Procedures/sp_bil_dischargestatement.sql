CREATE OR REPLACE FUNCTION sp_bil_dischargestatement(
    p_patientid INT DEFAULT NULL,
    p_dischargestatementid INT DEFAULT NULL,
    p_patientvisitid INT DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
    ref3 refcursor := 'cursor3';
    ref4 refcursor := 'cursor4';
    ref5 refcursor := 'cursor5';
    ref6 refcursor := 'cursor6';
    ref7 refcursor := 'cursor7';
    ref8 refcursor := 'cursor8';
    ref9 refcursor := 'cursor9';
    v_billingtransactionid INT := NULL;
BEGIN
    /*
    filename: "sp_bil_dischargestatement"
    createdby/date: rohit/1mar'23
    Description: To get the discharge statement details 
    			 Table 1: PatientInformation
    			 Table 2: InvoiceInformation
    			 Table 3: InvoiceItems
    			 Table 4: VisitInformation
    			 Table 5: DepositLists
    			 Table 6: PharmacyInvoiceItems
    			 Table 7: DischargeDetails
    			 Table 8: BillingSummaryViewUsingServiceDepartment
    			 Table 9: PharmacySummaryView
    Remarks:    
    Change History
    S.No.    UpdatedBy/Date                        Remarks
    1       Rohit/28Feb'23                        created the script
    2		rohit/24apr'23						  PAT_MAP_PriceCategory ->PAT_MAP_PatientSchemes, PAT_CFG_MembershipType 
    											  Table -> BIL_CFG_Scheme
    3		Krishna/27thApril'23				  change deposittype to transactiontype and segregate amount to inamount
    											  and outamount
    4		krishna/15thjuly'23					  Read ServiceCategoryName,ServiceCategoryCode and IntegrationItemId 
    											  in InvoiceItems
    5	    Krishna/9thAug'23				      read othercurrencydetail
    6	    krishna/10thaug'23				      Add BillingSummary and PharmacySummary tables
    7		Krishna/13thOct'23					  read iscopayment for items
    */
    begin
    	
    
    	select txnitm.billingtransactionid into v_billingtransactionid from bil_txn_billingtransaction txn 
    	inner join bil_txn_billingtransactionitems txnitm on txn.billingtransactionid = txnitm.billingtransactionid
    	where txnitm.dischargestatementid = p_dischargestatementid limit 1;
    
    --table 1: patientinformation
    open ref1 for select 
    		 pat.patientid
    		,pat.patientcode
    		,shortname
    		,gender
    		,dateofbirth
    		,age
    		,pat.countryid
    		,cont.countryname
    		,pat.countrysubdivisionid
    		,dist.countrysubdivisionname
    		,pat.address
    		,munc.municipalityname
    		,pat.phonenumber
    		,memb.schemeid
    		,memb.schemename
    		,pannumber
    		,patientnamelocal
    		,ins_nshinumber
    		,patmapscheme.policyno as "policyno"
    from (select patientid, patientcode, shortname, gender, dateofbirth, age, countryid, countrysubdivisionid, address,
    			 phonenumber, pannumber, patientnamelocal, ins_nshinumber, municipalityid
    			from pat_patient  where patientid = p_patientid) pat 
    inner join (select * from pat_patientvisits  where patientvisitid = p_patientvisitid) patvisit 
    			on pat.patientid = patvisit.patientid
    inner join bil_cfg_scheme memb on patvisit.schemeid = memb.schemeid
    inner join mst_countrysubdivision dist on pat.countrysubdivisionid = dist.countrysubdivisionid
    inner join mst_country cont on dist.countryid = cont.countryid
    left join mst_municipality munc on pat.municipalityid = munc.municipalityid
    left join pat_map_patientschemes patmapscheme 
    			on patmapscheme.schemeid = patvisit.schemeid and patmapscheme.patientid = patvisit.patientid;
        return next ref1;
    
    --table 2: invoiceinformation
    open ref2 for select txn.invoiceno as "invoicenumber"
    		,txn.invoicecode
    		,fy.fiscalyearformatted || '-' || txn.invoicecode || (txn.invoiceno)::varchar as "invoicenumformatted"
    		,txn.createdon as "transactiondate"
    		,txn.fiscalyearid
    		,fy.fiscalyearformatted as fiscalyear
    		,txn.paymentmode
    		,txn.paymentdetails
    		,txn.billstatus
    		,txn.transactiontype
    		,txn.invoicetype
    		,coalesce(txn.printcount, 0) as "printcount"
    		,txn.subtotal
    		,txn.discountamount
    		,txn.taxableamount
    		,txn.nontaxableamount
    		,txn.totalamount
    		,txn.billingtransactionid
    		,txn.paiddate as "paiddate"
    		,txn.tender
    		,txn.change
    		,txn.remarks
    		,coalesce(txn.isinsurancebilling, 0) as "isinsurancebilling"
    		,txn.claimcode
    		,txn.organizationid as "crorganizationid"
    		,crorg.organizationname as "crorganizationname"
    		,usr.username
    		,cntr.counterid
    		,cntr.countername
    		,txn.labtypename
    		,coalesce(txn.receivedamount, 0) as "receivedamount"
    		,txn.packageid
    		,pkg.billingpackagename as "packagename"
    		,coalesce(txn.depositavailable, 0) as "depositavailable"
    		,coalesce(txn.depositused, 0) as "depositused"
    		,coalesce(txn.depositreturnamount, 0) as "depositreturnamount"
    		,coalesce(txn.depositbalance, 0) as "depositbalance"
    		,txn.othercurrencydetail
    from (select invoiceno, invoicecode, createdon, fiscalyearid, paymentmode, paymentdetails, billstatus, transactiontype, invoicetype,
    			 printcount, subtotal, discountamount, taxableamount, nontaxableamount, totalamount, billingtransactionid, paiddate, 
    			 tender, change, remarks, isinsurancebilling, claimcode, organizationid, labtypename, receivedamount, packageid,
    			 depositavailable, depositused, depositreturnamount, depositbalance, othercurrencydetail, createdby, counterid
    	  from bil_txn_billingtransaction  where billingtransactionid = v_billingtransactionid) txn 
    inner join bil_cfg_fiscalyears fy on txn.fiscalyearid = fy.fiscalyearid
    inner join rbac_user usr on txn.createdby = usr.employeeid
    inner join bil_cfg_counter cntr on txn.counterid = cntr.counterid
    left join bil_mst_credit_organization crorg on txn.organizationid = crorg.organizationid
    left join bil_cfg_packages pkg on txn.packageid = pkg.billingpackageid;
        return next ref2;
    
    --table 3: invoiceitems
    open ref3 for select billingtransactionitemid
    		,item.servicedepartmentid
    		,item.itemcode
    		,item.integrationitemid
    		,item.itemid
    		,servicedepartmentname
    		,item.itemname
    		,item.iscopayment
    		,price
    		,quantity
    		,subtotal
    		,discountamount
    		,totalamount
    		,performerid
    		,performername
    		,item.prescriberid
    		,case 
    			when item.prescriberid is null
    				then ''
    			else emp.fullname
    			end as requestedbyname
    		,item.pricecategory
    		,item.createdon as "billdate"
    		,servcat.servicecategorycode
    		,servcat.servicecategoryname
    from (select billingtransactionitemid,servicedepartmentid, servicedepartmentname,
    			itemcode,itemname,integrationitemid,itemid,price, quantity, subtotal, discountamount,
    			totalamount, performerid, performername, prescriberid, serviceitemid, pricecategory, createdon, iscopayment
    			from bil_txn_billingtransactionitems 
    		where billingtransactionid = v_billingtransactionid) item 
    inner join bil_mst_serviceitem mstservitm on item.serviceitemid = mstservitm.serviceitemid
    left join bil_mst_servicecategory servcat on mstservitm.servicecategoryid = servcat.servicecategoryid
    left join emp_employee emp on item.prescriberid = emp.employeeid;
        return next ref3;
    	
    --table 4: visitinformation
    open ref4 for select vis.patientvisitid
    		,vis.visitcode
    		,vis.performerid as consultingdoctorid
    		,vis.performername as consultingdoctor
    		,adm.admissiondate
    		,adm.dischargedate
    		,bedinfo.wardname
    		,bedinfo.bednumber
    		,bedinfo.bedcode
    		,vis.visittype
    from (select patientvisitid, visitcode, performerid, performername, visittype 
    	  from pat_patientvisits  where patientvisitid = p_patientvisitid) vis 
    left join adt_patientadmission adm  on vis.patientvisitid = adm.patientvisitid
    left join (select  bi.patientvisitid,ward.wardname,bed.bednumber,bed.bedcode
    		    from (select wardid, bedid,patientvisitid,patientbedinfoid
    				  from adt_txn_patientbedinfo  where patientvisitid = p_patientvisitid) bi
    		    inner join adt_mst_ward ward on bi.wardid = ward.wardid
    		    inner join adt_bed bed on bi.bedid = bed.bedid
    		    order by patientbedinfoid desc limit 1
    		) bedinfo on vis.patientvisitid = bedinfo.patientvisitid;
        return next ref4;
    
    --table 5: depositlists
    open ref5 for select dep.depositid
    		,dep.receiptno
    		,fy.fiscalyearformatted
    		,fy.fiscalyearformatted || '-DR' || (receiptno)::varchar as "depositreceiptnoformattted"
    		,dep.transactiontype
    		,dep.inamount
    		,dep.outamount
    		,dep.createdon
    		,usr.username
    from (select depositid, receiptno, transactiontype, inamount, outamount, createdon, createdby, fiscalyearid
    	  from bil_txn_deposit  where patientvisitid = p_patientvisitid) dep 
    inner join bil_cfg_fiscalyears fy on dep.fiscalyearid = fy.fiscalyearid
    inner join rbac_user usr on dep.createdby = usr.employeeid;
        return next ref5;
    
    --table 6: pharmacyinvoiceitems
    open ref6 for select invitm.createdon as "billdate"
    		,invitm.itemid
    		,invitm.itemname
    		,itm.itemcode
    		,invitm.expirydate
    		,invitm.batchno
    		,quantity
    		,saleprice
    		,subtotal
    		,totaldisamt
    		,vatamount
    		,totalamount
    from (select itemid, itemname, expirydate,batchno,quantity, saleprice, subtotal, totaldisamt, vatamount, totalamount, createdon
    		from phrm_txn_invoiceitems  where dischargestatementid = p_dischargestatementid) invitm 
    inner join phrm_mst_item itm on invitm.itemid = itm.itemid;
        return next ref6;
    	
    --table 7: dischargedetails
    open ref7 for select dischargestatementid
    		,statementdate
    		,statementno
    		,statementtime
    from bil_txn_dischargestatement
    where dischargestatementid = p_dischargestatementid;
        return next ref7;
    
    --table 8: billingsummaryviewusingservicedepartment
    open ref8 for select
    	grp.groupname,
    	grp.subtotal,
    	grp.discountamount,
    	grp.totalamount
    from (
    select 
    	itms.servicedepartmentname as "groupname", 
    	(sum(coalesce(itms.subtotal, 0)))::decimal(16,4) as "subtotal",
    	(sum(coalesce(itms.discountamount, 0)))::decimal(16,4) as "discountamount", 
    	(sum(coalesce(itms.totalamount, 0)))::decimal(16,4) as "totalamount" 
    from 
    		(select servicedepartmentid, servicedepartmentname,billingtransactionitemid,
    			  subtotal, discountamount, totalamount from bil_txn_billingtransactionitems 
    		 where billingtransactionid = v_billingtransactionid) itms
    		 inner join bil_mst_servicedepartment servdep on itms.servicedepartmentid = servdep.servicedepartmentid
    		 group by itms.servicedepartmentid, itms.servicedepartmentname
    )grp;
        return next ref8;
    
    --table 9: pharmacysummaryview
    open ref9 for select 
    	'Pharmacy Items' as "groupname",
    	(sum(coalesce(subtotal,0)))::decimal(16,4) as "subtotal",
    	(sum(coalesce(totaldisamt,0)))::decimal(16,4) as "discountamount",
    	(sum(coalesce(totalamount, 0)))::decimal(16,4) as "totalamount"
    from phrm_txn_invoiceitems  
    where dischargestatementid = p_dischargestatementid
    group by dischargestatementid;
        return next ref9;
    end;
END;
$$ LANGUAGE plpgsql;