CREATE OR REPLACE FUNCTION sp_report_bil_departmentitemsummary(
    p_todate TIMESTAMP DEFAULT NULL,
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_srvdeptname VARCHAR DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
BEGIN
    /*  
    change history  
    s.no. updatedby/date			remarks  
    1  ramavtar/11sept'18		Initial Draft  
    2  Ramavtar/30Nov'18		added summary and filtered report data for provisional and cancel  
    3  sud/13mar'19				Changed to function FN_BILL_Get_BillingTxnItemSeggregation_ByBillingType_NoProvisional   
                                      from: FN_BIL_GetTxnItemsInfoWithDateSeparation_DepartmentSummary  
    4. Dinesh/27th May'19		added referreddoctorname   
    5. krishna/8thjun'22		Changed ProviderName to PerformerName
    6. Krishna/23,Aug'22		changed the sp for department summary (removed the dependency of function from the sp)
    */  
      
    
    open ref1 for select * from (
    
    --<sales part start>
    select 
    	 (createdon)::date as "date"
    	,coalesce(invitm.performername,'No Doctor') as "performername"
    	,coalesce(invitm.prescribername,'No Doctor') as "prescribername"
    	,invitm.shortname as "patientname"
    	,invitm.patientcode as "patientcode"
    	,invitm.invoiceno as "invoicenumber"
    	,invitm.price
    	,invitm.quantity as "quantity"
    	,invitm.subtotal as "subtotal"
    	,invitm.discountamount
    	, coalesce(invitm.totalamount,0) as "totalamount"
    	, 0 as "returnamount"
    	,coalesce(invitm.totalamount, 0) as "netamount"
    	,invitm.servicedepartmentid
    	,invitm.servicedepartmentname
    	,invitm.itemname
    from (
    	select 
    		 perfemp.fullname as "performername"
    		,presemp.fullname as "prescribername"
    		,itm.totalamount as "totalamount"
    		,serv.servicedepartmentid
    		,serv.servicedepartmentname
    		,itm.itemname
    		,pat.shortname
    		,txn.invoiceno
    		,itm.subtotal
    		,itm.discountamount
    		,pat.patientcode
    		,itm.price
    		,itm.quantity
    		,txn.createdon as "createdon"
    	from bil_txn_billingtransactionitems itm
    	inner join bil_txn_billingtransaction txn on itm.billingtransactionid = txn.billingtransactionid
    	inner join bil_mst_servicedepartment serv on serv.servicedepartmentid = itm.servicedepartmentid
    	inner join pat_patient pat on pat.patientid = itm.patientid
    	left join emp_employee perfemp on perfemp.employeeid = itm.performerid
    	left join emp_employee presemp on presemp.employeeid = itm.prescriberid
    	where (txn.createdon)::date between p_fromdate and p_todate
    		and serv.servicedepartmentname = coalesce(p_srvdeptname, serv.servicedepartmentname)
    		
    	) invitm
    --<sales part end>
    union all
    
    
    --<return part starts>
    select 
    		
    	(ret.createdon)::date as "date"
    	,coalesce(perfemp.fullname,'No Doctor') as "performername"
    	,coalesce(presemp.fullname,'No Doctor') as "prescribername"
    	,pat.shortname as "patientname"
    	,pat.patientcode as "patientcode"
    	,ret.refinvoicenum as "invoicenumber"
    	,rti.price
    	,-rti.retquantity as "quantity"
    	,0 as "subtotal"
    	,0 as "discountamount"
    	,0 as "totalamount"
    	, coalesce(rti.rettotalamount,0) as "returnamount"
    	,-coalesce(rti.rettotalamount,0) as "netamount"
    	,itm.servicedepartmentid
    	,itm.servicedepartmentname
    	,itm.itemname
    		
    	from bil_txn_invoicereturnitems rti
    	inner join bil_txn_billingtransactionitems itm on rti.billingtransactionitemid = itm.billingtransactionitemid
    	inner join bil_txn_invoicereturn ret on rti.billreturnid = ret.billreturnid
    	inner join pat_patient pat on pat.patientid = ret.patientid
    	left join emp_employee perfemp on perfemp.employeeid = itm.performerid
    	left join emp_employee presemp on presemp.employeeid = itm.prescriberid
    	where (ret.createdon)::date between p_fromdate and p_todate
    		and itm.servicedepartmentname = coalesce(p_srvdeptname, itm.servicedepartmentname)
    	
    	)tbl
    	order by tbl.date desc;
        return next ref1;
    --<return part end>
     
    --table2: provisional, cancel, credit amounts for summary  
     open ref2 for select   
      sum(case when billstatus='provisional' then provisionalamount else 0 end) as "provisionalamount",  
      sum(case when billstatus='cancelled' then cancelledamount else 0 end) as "cancelledamount",  
      sum(case when billstatus='credit' then creditamount else 0 end) as "creditamount",  
      (select sum(coalesce(advancereceived,0)) from fn_bil_getdepositnprovisionalbetndaterange(p_fromdate,p_todate)) as "advancereceived",  
      (select sum(coalesce(advancesettled,0)) from fn_bil_getdepositnprovisionalbetndaterange(p_fromdate,p_todate)) as "advancesettled"  
     from fn_bil_gettxnitemsinfowithdateseparation_departmentsummary(p_fromdate, p_todate)  
     where servicedepartmentname = coalesce(p_srvdeptname,servicedepartmentname);
        return next ref2;
END;
$$ LANGUAGE plpgsql;