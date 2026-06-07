CREATE OR REPLACE FUNCTION sp_bil_getinvoicedetailsforprint(
    p_invoicenumber INT,
    p_fiscalyearid INT,
    p_billingtxnidinput INT DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
    ref3 refcursor := 'cursor3';
    ref4 refcursor := 'cursor4';
    ref5 refcursor := 'cursor5';
    ref6 refcursor := 'cursor6';
    v_patientid INT;
    v_patientvisitid INT;
    v_billtxnid INT;
    v_currentschemeid INT;
BEGIN
    /*  
    filename: sp_bil_getinvoicedetailsforprint  
    description:   
     * to get patientinformation, invoiceinformation, invoiceitemsinformation,   
      visitinformation and deposit lists for duplicate print of all types of invoices   
      generated from billing "normal billing, insurancebilling, ip/op, all.."  
     * returns five tables  
    change history  
    s.no.    updatedby/date                        remarks  
    1.      sud/18may'21                        Initial Draft  
    2.      Sud/15Sep'21                        new input parameter billingtxnid is also passed,   
                                                there are duplicate fiscalyear+invoicenumber combinations in big hospitals having many			     counters..  
    										billingtxnid is unique, so we'll pass that from Client>Server>DB so that we'll get only one record.  
    3.    sud/20dec'21						 Added  so that this thread doesn't wait to complete other transaction.  
    										  added only in the transaction tables, not required in master/configuration tables.  
    4.    pratik/27dec'2021					 Added price category in item select (Used to show in invoice print)  
    5.    Dev /30Jan' 2022					 added municipality name in patient info section.  
    6.   krishna/ 25th,jul'22				 Added PaymentDetails in InvoiceInfo
    7.	 Krishna/ 05th,Sept'22				 add receivedamount in the select query of invoiceinfo
    8.   dev/ 11th,oct'22                    Add SSFPolicyNo in PatientInfo
    9.	 Sanjeev/ 15th,Feb'23				 add wardnumber in patientinfo
    10.	 sanjeev/ 22nd,feb'23				 Update condition for selectinig SSFPolicyNo in PatientInfo 
    										 (i.e. Select PolicyNo as SSFPolicyNo for SSF Patient)
    										 Add Policy Number (Select PolicyNo as PolicyNo for ECHS Patient)
    11.	 Krishna/16thMarch'23				 rename pat_map_pricecategory to pat_map_patientschemes and pat_cfg_membershiptype to 
    										 bil_cfg_scheme
    12.  krishna/22ndmarch'23			     Remove Inner JOIN with BIL_CFG_Scheme in Patient Information and add it to Invoice
    										 information
    13.	 Krishna/21stApril'23				 change deposittype to transactiontype and amount to inamount and outamount
    14.	 krishna/1stjune'23					 Added ItemCode,IsCoPayment, and DiscountPercent in Items select
    15.	 Krishna/24thJune'23				 read departmentname in visit information select query
    16.	 krishna/9thaug'23					 Read OtherCurrencyDetail
    17.	 Krishna/10thAug'23				     add billinginvoicesummary table
    */  
    begin  
     
      
    if (coalesce(p_billingtxnidinput,0)!=0)  
    then  
     select patientid, billingtransactionid, patientvisitid, schemeid into v_patientid, v_billtxnid, v_patientvisitid, v_currentschemeid from bil_txn_billingtransaction   
     where billingtransactionid=p_billingtxnidinput;  
      
    else  
      
     select patientid, billingtransactionid, patientvisitid, schemeid into v_patientid, v_billtxnid, v_patientvisitid, v_currentschemeid from bil_txn_billingtransaction   
     where fiscalyearid=p_fiscalyearid and invoiceno=p_invoicenumber;  
    end if;  
      
      
    --table:1--patient information-----  
    open ref1 for select 
      pat.patientid, 
      pat.patientcode, 
      shortname,
      gender, 
      dateofbirth, 
      age,  
      pat.countryid,   
      cont.countryname,  
      pat.countrysubdivisionid, 
      pat.wardnumber,
      dist.countrysubdivisionname,  
      pat.address,  
      munc.municipalityname,  
      pat.phonenumber,  
      pannumber,  
      patientnamelocal,
      patmap.policyno as "policyno"--select policyno as policyno for echs patient--
      from pat_patient pat  
      inner join mst_countrysubdivision dist on pat.countrysubdivisionid = dist.countrysubdivisionid 
      inner join mst_country cont on dist.countryid = cont.countryid
      left join mst_municipality munc on pat.municipalityid = munc.municipalityid 
      left join pat_map_patientschemes patmap on pat.patientid = patmap.patientid and patmap.schemeid = v_currentschemeid
      where pat.patientid = v_patientid;
        return next ref1;
      
    --table:2--invoice information-----  
    open ref2 for select  txn.invoiceno as "invoicenumber",  
            txn.invoicecode,  
            fy.fiscalyearformatted||'-'||  txn.invoicecode||(txn.invoiceno)::varchar as "invoicenumformatted",  
      txn.createdon as "transactiondate",  
      txn.fiscalyearid,  
      fy.fiscalyearformatted as fiscalyear,  
      txn.paymentmode,  
      txn.paymentdetails,  
      txn.billstatus,  
      txn.transactiontype,  
      txn.invoicetype,  
      coalesce(txn.printcount,0) as "printcount",  
      txn.subtotal,  
      txn.discountamount,  
      txn.taxableamount,  
      txn.nontaxableamount,  
      txn.totalamount,  
            txn.billingtransactionid,  
      txn.paiddate as "paiddate",   
      txn.tender,  
      txn.change,  
      txn.remarks,  
      coalesce(txn.isinsurancebilling,0) as "isinsurancebilling",  
      txn.claimcode,  
      txn.organizationid as "crorganizationid",  
      crorg.organizationname as "creditorganizationname",  
      usr.username,  
      cntr.counterid,  
      cntr.countername,  
      txn.labtypename,  
      coalesce(txn.receivedamount,0) as "receivedamount",
      txn.packageid,   
      pkg.billingpackagename as "packagename",  
      coalesce(txn.depositavailable,0) as "depositavailable",  
      coalesce(txn.depositused,0) as "depositused",  
      coalesce(txn.depositreturnamount,0) as "depositreturnamount",  
      coalesce(txn.depositbalance,0) as "depositbalance",
      scheme.schemeid,
      scheme.schemename,
      txn.othercurrencydetail
    from bil_txn_billingtransaction txn   
    inner join bil_cfg_fiscalyears fy  
         on txn.fiscalyearid = fy.fiscalyearid  
    inner join rbac_user usr  
        on txn.createdby = usr.employeeid  
      
     inner join bil_cfg_counter cntr  
      on txn.counterid=cntr.counterid
     inner join bil_cfg_scheme scheme
     on scheme.schemeid = txn.schemeid
    left join bil_mst_credit_organization crorg   
        on txn.organizationid = crorg.organizationid  
    left join bil_cfg_packages pkg  
     on txn.packageid = pkg.billingpackageid  
    where billingtransactionid = v_billtxnid;
        return next ref2;  
      
    --table:3--invoiceitems information-----  
    open ref3 for select   
    billingtransactionitemid, servicedepartmentid, itemid,  
    servicedepartmentname,itemcode, itemname, price, quantity, subtotal,discountpercent, discountamount, totalamount,  
    performerid, performername, item.prescriberid, case when item.prescriberid is null then '' else emp.fullname end as requestedbyname,  
    item.pricecategory, iscopayment  
    from bil_txn_billingtransactionitems item   
    left join emp_employee emp on item.prescriberid = emp.employeeid  
    where billingtransactionid = v_billtxnid;
        return next ref3;  
      
    --table:4--visit information-----  
    open ref4 for select vis.patientvisitid,  
     vis.visitcode,  
     vis.performerid as consultingdoctorid,  
     vis.performername as consultingdoctor,  
     adm.admissiondate,  
     adm.dischargedate,  
     bedinfo.wardname,  
     bedinfo.bednumber,  
     bedinfo.bedcode,
     dep.departmentname
      
    from pat_patientvisits vis   
       inner join mst_department dep on dep.departmentid = vis.departmentid
       left join adt_patientadmission adm   
            on vis.patientvisitid=adm.patientvisitid  
       left join (  
         select   bi.patientvisitid, ward.wardname, bed.bednumber, bed.bedcode  
         from adt_txn_patientbedinfo  bi   
         inner join adt_mst_ward ward   
           on bi.wardid=ward.wardid  
         inner join adt_bed bed   
           on bi.bedid=bed.bedid  
         where patientvisitid=v_patientvisitid  
         order by patientbedinfoid desc limit 1  
       )bedinfo  on vis.patientvisitid = bedinfo.patientvisitid  
      
    where vis.patientvisitid = v_patientvisitid;
        return next ref4;  
      
    --table:5--deposits list -----  
    open ref5 for select   
      dep.depositid, dep.receiptno, fy.fiscalyearformatted,  
      fy.fiscalyearformatted||'-DR'||(receiptno)::varchar as "depositreceiptnoformattted",  
      dep.transactiontype, dep.inamount, dep.outamount, dep.createdon, usr.username  
    from bil_txn_deposit dep   
     inner join bil_cfg_fiscalyears fy on dep.fiscalyearid=fy.fiscalyearid  
     inner join rbac_user usr on dep.createdby = usr.employeeid  
    where patientvisitid=v_patientvisitid;
        return next ref5;  
    
    --table: 6 billinginvoicesummary
    open ref6 for select
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
    		 where billingtransactionid = v_billtxnid) itms
    		 inner join bil_mst_servicedepartment servdep on itms.servicedepartmentid = servdep.servicedepartmentid
    		 group by itms.servicedepartmentid, itms.servicedepartmentname
    )grp;
        return next ref6;
    end;
END;
$$ LANGUAGE plpgsql;