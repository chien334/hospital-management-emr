CREATE OR REPLACE FUNCTION sp_ssf_invoiceinfo(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_patienttype VARCHAR DEFAULT NULL
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
    v_ssfschemeidscsv VARCHAR := (select STRING_AGG(CAST(SchemeId AS VARCHAR(200)), ',') 
							from BIL_CFG_Scheme where ApiIntegrationName = 'SSF');
    v_billtxnidscsv VARCHAR;
    v_invidscsv VARCHAR;
BEGIN
    /*
    exec sp_ssf_invoiceinfo '2023-07-09','2023-07-09','outpatient'
    filename: sp_ssf_invoiceinfo
    --description: this sp returns 7 tables
       --1. patient information
       --2. billing-invoice information
       --3. billing-invoiceitems information
       --4. pharmacy-invoice information
       --5. pharmacy-invoiceitems information
       --6. lab-reports
       --7. radiology-reports 
       --8. billing invoice returns
       --9. pharmacy invoice returns
    s.no.    updatedby/date                        remarks
    1        dev narayan / 21 sept'22              Initial Draft
    2        Krishna/17thNov'22                    rename patientvisitid to latestpatientvisitid
    3.       krishna/18thnov'22                    Group Details according to PatientId and ClaimCode
    4.       Krishna/24thNov'22                    handle returned invoices and items in ssf invoices to claim
    5.       krishna/15thdec'22                    Fetch Invoice Items of specific priceCategory 
    											   from BIL_MAP_BillCFGItemVsPriceCategory table
    6.       Krishna/16thDec'22                    handle pharmacy return items
    7.		 krishna/27thfeb'23					   Handle Emergency Visits 
    8.		 Sanjeev/5thJune'23					   change joins from pricecategory to scheme, change balanceamount 
    											   to netreceivableamount
                                                   (integration of ssf in claim management)
    9.	    krishna/2ndoct'23						Make it compatible with multiple Schemes of SSF
    10.		Krishna/8thOct'23				        filter non claimed invoices only to display in claim page
    11.     krishna/6thnov'23						Rename InvoiceNo to InvoiceNumber for Pharmacy Invoice
    12.	    Krishna/6thNov'23						read billing and pharmacy invoice returns
    */
    begin
    
    
        
    
        v_billtxnidscsv := (
                select string_agg(cast(billingtransactionid as text), ',')
                from bil_txn_billingtransaction
                where billingtransactionid in (
                        select distinct txn.billingtransactionid
                        from bil_txn_billingtransaction txn
                        join bil_txn_creditbillstatus creditstatus on txn.billingtransactionid = creditstatus.billingtransactionid
                        join bil_txn_billingtransactionitems txnitem on txn.billingtransactionid = txnitem.billingtransactionid
                        left join pat_ssfclaimresponsedetails response on txn.claimcode = response.claimcode
    					inner join (select value as "schemeid" from string_split(v_ssfschemeidscsv,',')) schemeids 
    								on txn.schemeid = schemeids.schemeid
                        where  (txn.createdon)::date between p_fromdate
                                and p_todate
    					and coalesce(response.responsestatus, 0) = 0
                        ) and transactiontype = p_patienttype
                );
        
    
        v_invidscsv := (
                select string_agg(cast(invoiceid as text), ',')
                from (
                    select invoiceid
                    from phrm_txn_invoice
                    where claimcode not in (
                            select claimcode
                            from pat_ssfclaimresponsedetails
                            where responsestatus = 1
                            ) and (createon)::date between p_fromdate
                            and p_todate and visittype = p_patienttype
                    ) tbl
                );
    
        --declare v_ssfpricecategoryid int = (
        --        select pricecategoryid
        --        from bil_cfg_pricecategory
        --        where pricecategoryname = 'SSF'
        --        )
    
        open ref1 for select visit.claimcode
            ,pat.patientid
            ,pat.patientcode
            ,visit.patientvisitid
            ,shortname
            ,gender
            ,dateofbirth
            ,age
            ,pat.countryid
            ,cont.countryname
            ,pat.countrysubdivisionid
    		,coalesce(pat.wardnumber, 0) as "wardnumber"
            ,dist.countrysubdivisionname
            ,concat (
                dist.countrysubdivisionname
                ,pat.address
                ,munc.municipalityname
                ) as address
            ,munc.municipalityname
    		,dept.departmentname
            ,pat.phonenumber
            ,visit.schemeid
    		,visit.departmentid
            ,scheme.schemename
            ,pannumber
            ,patientnamelocal
            ,ins_nshinumber
            ,map.policyno
            ,map.policyholderemployerid
            ,case 
                when map.registrationcase = 'Accident'
                    then 1
                else 2
                end as "schemetype"
            ,dissummary.diagnosis
            ,case 
                when (admission.admissionstatus = 'admitted' or admission.admissionstatus = 'discharged')
                    then '1'
                else '0'
                end as "admitted"
            ,(admission.admissiondate)::date as "admissiondate"
            ,(admission.dischargedate)::date as "dischargedate"
            ,map.policyholderuid
            ,dissummary.casesummary
            ,dtype.dischargetypename
            ,case 
                when dissummary.deathtypeid is null
                    then 0
                else 1
                end as "isdead"
            ,visit.createdon as "visitcreationdate"
            ,case when visit.visittype = 'inpatient' then 'inpatient' else 'outpatient' end as "visittype"
        from pat_patient pat 
        inner join mst_countrysubdivision dist on pat.countrysubdivisionid = dist.countrysubdivisionid
        inner join mst_country cont on dist.countryid = cont.countryid
        
        inner join (
            select *
            from (
                select row_number() over (
                        partition by innerdata.claimcode order by innerdata.patientvisitid desc
                        ) as rownum
                    ,innerdata.patientid
                    ,innerdata.patientvisitid
                    ,innerdata.visittype
                    ,innerdata.createdon
                    ,innerdata.claimcode
                    ,innerdata.schemeid,
    				innerdata.departmentid
                from pat_patientvisits innerdata
                where case 
                        when innerdata.visittype = 'inpatient'
                            then 'inpatient'
                        else 'outpatient'
                        end = p_patienttype and (innerdata.createdon)::date between p_fromdate
                        and p_todate
                ) tbl
            where tbl.rownum = 1
            ) visit on pat.patientid = visit.patientid
        inner join pat_map_patientschemes map on map.patientid = visit.patientid and map.schemeid = visit.schemeid --this is done as we have unique combination of patientid and pricecategoryid in pat_map_pricecategory table
            --map.latestpatientvisitid = visit.patientvisitid 
    	inner join mst_department dept on dept.departmentid = visit.departmentid
    	inner join bil_cfg_scheme scheme on scheme.schemeid = visit.schemeid
        left join mst_municipality munc on pat.municipalityid = munc.municipalityid
        left join adt_patientadmission admission on admission.patientid = pat.patientid and admission.patientvisitid = visit.patientvisitid
        left join adt_dischargesummary dissummary on dissummary.patientvisitid = visit.patientvisitid
        left join adt_dischargetype dtype on dtype.dischargetypeid = dissummary.dischargetypeid
        where pat.patientid in (
                (select patientid from bil_txn_billingtransaction
                            where billingtransactionid in (select value from string_split(v_billtxnidscsv, ',')))
                union all 
                (select patientid from phrm_txn_invoice
                            where invoiceid in (select value from string_split(v_invidscsv, ','))))
                and case 
                when visittype = 'inpatient'
                    then 'inpatient'
                else 'outpatient'
                end = p_patienttype and (visit.createdon)::date between p_fromdate
                and p_todate;
        return next ref1;
    
        --table:2--invoice information-----
        open ref2 for select *
        from (
            select txn.invoiceno as "invoicenumber"
                ,txn.invoicecode
                ,txn.invoicecode || (txn.invoiceno)::varchar as "invoicenumformatted"
                ,txn.createdon as "transactiondate"
                ,txn.fiscalyearid
                ,txn.paymentmode
                ,txn.paymentdetails
                ,txn.billstatus
                ,txn.transactiontype
                ,txn.invoicetype
                ,coalesce(txn.printcount, 0) as "printcount"
                ,--txn.subtotal - 
                tbl3.totalsubtotal as "subtotal"
                ,txn.discountamount
                ,txn.taxableamount
                ,txn.nontaxableamount
                ,--txn.totalamount - 
                tbl3.totalamount as "totalamount"
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
                ,txn.packageid
                ,pkg.billingpackagename as "packagename"
                ,coalesce(txn.depositavailable, 0) as "depositavailable"
                ,coalesce(txn.depositused, 0) as "depositused"
                ,coalesce(txn.depositreturnamount, 0) as "depositreturnamount"
                ,coalesce(txn.depositbalance, 0) as "depositbalance"
                ,(tbl3.totalamount - coalesce(creditstatus.netreceivableamount,0)) as "receivedamount" --txn.receivedamount
                ,creditstatus.netreceivableamount
                ,txn.patientid
                ,(txn.createdon)::date as "invoicedate"
                ,tbl3.quantity as "quantity"
            from bil_txn_billingtransaction txn 
            left join (
                select tbl2.billingtransactionid
                    ,sum(coalesce(totalquantity, 0)) as "quantity"
                    ,sum(coalesce(totalsubtotal, 0)) as "totalsubtotal"
                    ,sum(coalesce(totalamount, 0)) as "totalamount"
                from (
                    select itms.billingtransactionid
                        ,itms.billingtransactionitemid
                        ,sum(coalesce(itms.quantity, 0)) - sum(coalesce(tbl1.returnquantity, 0)) as "totalquantity"
                        ,sum(coalesce(itms.subtotal, 0)) - sum(coalesce(tbl1.retsubtotal, 0)) as "totalsubtotal"
                        ,sum(coalesce(itms.totalamount, 0)) - sum(coalesce(tbl1.rettotal, 0)) as "totalamount"
                    from (
                        select billingtransactionitemid
                            ,sum(coalesce(retquantity, 0)) as "returnquantity"
                            ,sum(coalesce(retsubtotal, 0)) as "retsubtotal"
                            ,sum(coalesce(rettotalamount, 0)) as "rettotal"
                        from bil_txn_invoicereturnitems
                        where (createdon)::date between p_fromdate
                                and p_todate
                        group by billingtransactionitemid
                        ) tbl1
                    right join bil_txn_billingtransactionitems itms on tbl1.billingtransactionitemid = itms.billingtransactionitemid
                    where (itms.createdon)::date between p_fromdate
                            and p_todate
                    group by itms.billingtransactionitemid
                        ,itms.billingtransactionid
                    ) tbl2
                group by tbl2.billingtransactionid
                having sum(coalesce(totalquantity, 0)) > 0
                ) tbl3 on tbl3.billingtransactionid = txn.billingtransactionid
            left join bil_txn_creditbillstatus creditstatus on txn.billingtransactionid = creditstatus.billingtransactionid
            inner join rbac_user usr on txn.createdby = usr.employeeid
            inner join bil_cfg_counter cntr on txn.counterid = cntr.counterid
            left join bil_mst_credit_organization crorg on txn.organizationid = crorg.organizationid
            left join bil_cfg_packages pkg on txn.packageid = pkg.billingpackageid
            where txn.billingtransactionid in (
                    select value
                    from string_split(v_billtxnidscsv, ',')
                    )
            ) tbl
        where tbl.quantity > 0;
        return next ref2;
    
        --table:3--invoiceitems information-----
        open ref3 for select *
        from (
            select item.billingtransactionitemid
    			,item.iscopayment
    			,item.discountpercent
    			,item.itemcode
                ,item.patientid
                ,item.servicedepartmentid
                ,item.itemid
                ,servicedepartmentname
                ,itemname
                ,item.price
                ,coalesce(quantity, 0) - coalesce(ret.retquantity, 0) as "quantity"
                ,coalesce(subtotal, 0) - coalesce(ret.retsubtotal, 0) as "subtotal"
                ,discountamount
                ,coalesce(totalamount, 0) - coalesce(ret.rettotal, 0) as "totalamount"
                ,performerid
                ,performername
                ,item.prescriberid
                ,case 
                    when item.prescriberid is null
                        then ''
                    else emp.fullname
                    end as requestedbyname
                ,item.pricecategory
                ,billingtransactionid
                ,map.itemlegalname
                ,map.itemlegalcode as "servicecode"
            from bil_txn_billingtransactionitems item 
            left join (
                select billingtransactionitemid
                    ,sum(coalesce(retquantity, 0)) as "retquantity"
                    ,sum(coalesce(retsubtotal, 0)) as "retsubtotal"
                    ,sum(coalesce(rettotalamount, 0)) as "rettotal"
                from bil_txn_invoicereturnitems
                group by billingtransactionitemid
                ) ret on item.billingtransactionitemid = ret.billingtransactionitemid
            left join emp_employee emp on item.prescriberid = emp.employeeid
            inner join bil_cfg_pricecategory cat on cat.pricecategoryid = item.pricecategoryid
            left join bil_map_pricecategoryserviceitem map on item.serviceitemid = map.serviceitemid and item.servicedepartmentid = map.servicedepartmentid and map.pricecategoryid = cat.pricecategoryid
            where billingtransactionid in (
                    select value
                    from string_split(v_billtxnidscsv, ',')
                    )
            ) tbl
        where tbl.quantity > 0;
        return next ref3;
    
    
        --need to handle returns properly
        open ref4 for select * from (
        select 
            inv.invoiceprintid as "invoicenumber",
            'PH' || (inv.invoiceprintid)::varchar as "invoicenumformatted",
            (inv.totalamount - coalesce(retinv.rettotalamount,0)) as "totalamount",
            (inv.totalamount - coalesce(creditstatus.netreceivableamount,0)) as "receivedamount",
            creditstatus.netreceivableamount,
            inv.claimcode,
            inv.patientid,
            inv.invoiceid,
            inv.createon as "invoicedate"
        from phrm_txn_invoice inv
        left join (
            select sum(coalesce(totalamount,0)) as "rettotalamount"
                ,invoiceid
            from phrm_txn_invoicereturn
            group by invoiceid
            ) retinv on retinv.invoiceid = inv.invoiceid
        join phrm_txn_creditbillstatus creditstatus on creditstatus.invoiceid = inv.invoiceid
        join pat_patientvisits visit on visit.patientvisitid = inv.patientvisitid
    	join bil_cfg_scheme scheme on scheme.schemeid = visit.schemeid
    	inner join (select value as "schemeid" from string_split(v_ssfschemeidscsv,',')) schemeids 
    								on scheme.schemeid = schemeids.schemeid
        --join bil_cfg_pricecategory pricecat on visit.pricecategoryid = pricecat.pricecategoryid
        where --scheme.schemeid in (v_ssfschemeidscsv) and 
    	(inv.createon)::date between p_fromdate
                and p_todate and inv.visittype = p_patienttype and inv.invoiceid in (
                select value
                from string_split(v_invidscsv, ',')
                )
            )tbl where tbl.netreceivableamount > 0;
        return next ref4;
    
        --table:5--phrm invoiceitems information-----
        open ref5 for select saleprice as "unitprice"
            ,'ADJ02' as "servicecode"
            ,invitms.patientid as "patientid"
            ,coalesce(quantity, 0) - coalesce(retitms.retqty, 0) as "quantity"
            ,inv.claimcode as "claimcode"
            ,inv.invoiceid
    		,invitms.itemname
        from phrm_txn_invoice inv
        join phrm_txn_invoiceitems invitms on inv.invoiceid = invitms.invoiceid
        left join (
            select sum(coalesce(returnedqty, 0)) as "retqty"
                ,invoiceitemid
            from phrm_txn_invoicereturnitems
            group by invoiceitemid
            ) retitms on retitms.invoiceitemid = invitms.invoiceitemid
    		join bil_cfg_scheme scheme on scheme.schemeid = inv.schemeid
    		inner join (select value as "schemeid" from string_split(v_ssfschemeidscsv,',')) schemeids 
    								on scheme.schemeid = schemeids.schemeid
        --join bil_cfg_pricecategory pricecat on invitms.pricecategoryid = pricecat.pricecategoryid
        where --scheme.schemeid in (v_ssfschemeidscsv) and 
    	(inv.createon)::date between p_fromdate
                and p_todate and inv.visittype = p_patienttype and inv.invoiceid in (
                select value
                from string_split(v_invidscsv, ',')
                );
        return next ref5;
    
        --table: 6 -- lab reports--------------------
        open ref6 for select req.patientid
            ,string_agg(req.requisitionid, ',') as "requisitionidcsv"
            ,txn.claimcode
        from bil_txn_billingtransaction txn
        join bil_txn_billingtransactionitems billitem on txn.billingtransactionid = billitem.billingtransactionid
        join lab_testrequisition req on billitem.serviceitemid = req.serviceitemid 
    	and billitem.billingtransactionitemid = req.billingtransactionitemid
    	and billitem.patientvisitid = req.patientvisitid
        where txn.billingtransactionid in (
                select value
                from string_split(v_billtxnidscsv, ',')
                ) and servicedepartmentid in (
                select servicedepartmentid
                from bil_mst_servicedepartment
                where integrationname = 'LAB'
                )
    			and req.labreportid is not null
    			and req.orderstatus = 'report-generated'
        group by req.patientid
            ,req.labreportid
            ,txn.claimcode;
        return next ref6;
    
        --table: 7 -- radiology reports--------------------
        open ref7 for select req.patientid
            ,req.imagingrequisitionid as "requisitionidcsv"
            ,txn.claimcode
        from bil_txn_billingtransaction txn
        join bil_txn_billingtransactionitems billitem on txn.billingtransactionid = billitem.billingtransactionid
        join rad_patientimagingrequisition req on billitem.serviceitemid = req.serviceitemid
    	and billitem.billingtransactionitemid = req.billingtransactionitemid
    	and billitem.patientvisitid = req.patientvisitid
        where txn.billingtransactionid in (
                select value
                from string_split(v_billtxnidscsv, ',')
                ) and servicedepartmentid in (
                select servicedepartmentid
                from bil_mst_servicedepartment
                where integrationname = 'Radiology'
                ) 
    			and req.isreportsaved = 1
        group by req.patientid
        ,req.imagingrequisitionid
        ,txn.claimcode;
        return next ref7;
    
    	--table 8: billinginvoicereturns
    	open ref8 for select 
    		ret.billreturnid as "returnid",
    		ret.creditnotenumber as "creditnotenumber",
    		concat('CRN', (ret.creditnotenumber)::varchar) as "creditnotenumberformatted",
    		ret.totalamount,
    		txn.claimcode,
    		ret.patientid,
    		'Billing' as "modulename"
    	from bil_txn_billingtransaction txn 
    		inner join (select value from string_split(v_billtxnidscsv, ',')) innertxn on txn.billingtransactionid = innertxn.value
    		inner join bil_txn_invoicereturn  ret on txn.billingtransactionid = ret.billingtransactionid;
        return next ref8;
    
    	--table 9: pharmacyinvoicereturns
    	open ref9 for select 
    		ret.invoicereturnid as "returnid",
    		ret.creditnoteid as "creditnotenumber",
    		concat('CR-PH', (ret.creditnoteid)::varchar) as "creditnotenumberformatted",
    		ret.totalamount,
    		txn.claimcode,
    		ret.patientid,
    		'Pharmacy' as "modulename"
    	from phrm_txn_invoice txn 
    		inner join (select value from string_split(v_invidscsv, ',')) innertxn on txn.invoiceid = innertxn.value
    		inner join phrm_txn_invoicereturn  ret on txn.invoiceid = ret.invoicereturnid;
        return next ref9;
    end;
END;
$$ LANGUAGE plpgsql;