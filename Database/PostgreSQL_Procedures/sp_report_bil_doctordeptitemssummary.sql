CREATE OR REPLACE FUNCTION sp_report_bil_doctordeptitemssummary(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_doctorid INT DEFAULT NULL,
    p_srvdeptname VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "Date" TIMESTAMP,
    "DoctorId" INT,
    "DoctorName" VARCHAR,
    "PatientName" VARCHAR,
    "PatientCode" VARCHAR,
    "InvoiceNumber" VARCHAR,
    "Price" DECIMAL,
    "Quantity" INT,
    "SubTotal" DECIMAL,
    "DiscountAmount" INT,
    "TotalAmount" DECIMAL,
    "ReturnAmount" DECIMAL,
    "NetAmount" DECIMAL,
    "ServiceDepartmentId" INT,
    "ServiceDepartmentName" VARCHAR,
    "ItemName" VARCHAR
) AS $$
DECLARE
    v_empname VARCHAR := (SELECT  FullName FROM EMP_Employee WHERE EmployeeId = p_doctorid LIMIT 1);
BEGIN
    /*  
    change history  
    s.no.    updatedby/date          remarks  
    1    ramavtar/04sept'18      initail draft  
    2  Ramavtar/30Nov'18   summary added   
    3  ramavtar/17dec'18   change in where condition (checking for credit records)  
    4.  Ramavtar/18Dec'18   getting data for all service dept  
    5.   sud/21feb'19             using new function to get doc-dept-items.  
    6.   sud:13Mar'19            join with fn_bil_getsrvdeptreportingname_doctorsummary to get actual service department name,   
                                 since it's now removed from  FN_BILL_Get_BillingTxnItemSeggregation_ByBillingType_NoProvisional  
    7.   sud:10Aug'20            invoicenumber column added in return data, order by date asc  
    8.	krishna/9thjun'22		changed ProviderId to PerformerId and ProviderName to PerformerName
    9.	Krishna/11thAug'22		add condition for prescriberid and referredbyid with p_doctorid
    10.	krishna/22th,aug'22		handle Return Scenarios
    11.	Krishna/23rd,Aug'22		complete sp revised(changed)
    */  
      
      
     
    
    --<sales part start>
    RETURN QUERY SELECT 
    	 (createdon)::date AS "Date"
    	,p_doctorid AS "DoctorId"
    	,v_empname AS "DoctorName"
    	,invitm.shortname AS "PatientName"
    	,invitm.patientcode AS "PatientCode"
    	,invitm.invoiceno AS "InvoiceNumber"
    	,invitm.price
    	,invitm.quantity AS "Quantity"
    	,invitm.subtotal AS "SubTotal"
    	,invitm.discountamount AS "DiscountAmount"
    	, coalesce(invitm.totalamount,0) AS "TotalAmount"
    	, 0 AS "ReturnAmount"
    	,coalesce(invitm.totalamount, 0) AS "NetAmount"
    	,invitm.servicedepartmentid
    	,invitm.servicedepartmentname
    	,invitm.itemname
    from (
    	select itm.billingtransactionitemid
    		,prescriberid
    		,itm.totalamount AS "TotalAmount"
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
    	where (txn.createdon)::date between p_fromdate and p_todate
    		and serv.servicedepartmentname = coalesce(p_srvdeptname, serv.servicedepartmentname)
    		and (
    			coalesce(itm.prescriberid, 0) = coalesce(p_doctorid, 0)
    			or coalesce(itm.performerid, 0) = coalesce(p_doctorid, 0)
    			or coalesce(itm.referredbyid, 0) = coalesce(p_doctorid, 0)
    			)
    	) invitm
    --<sales part end>
    union all
    
    
    --<return part starts>
    select 
    		
    	(ret.createdon)::date AS "Date"
    	,p_doctorid AS "DoctorId"
    	,v_empname AS "DoctorName"
    	,pat.shortname AS "PatientName"
    	,pat.patientcode AS "PatientCode"
    	,ret.refinvoicenum AS "InvoiceNumber"
    	,rti.price
    	,-rti.retquantity AS "Quantity"
    	,0 AS "SubTotal"
    	,0 AS "DiscountAmount"
    	,0 AS "TotalAmount"
    	, coalesce(rti.rettotalamount,0) AS "ReturnAmount"
    	,-coalesce(rti.rettotalamount,0) AS "NetAmount"
    	,itm.servicedepartmentid
    	,itm.servicedepartmentname
    	,itm.itemname
    		
    	from bil_txn_invoicereturnitems rti
    	inner join bil_txn_billingtransactionitems itm on rti.billingtransactionitemid = itm.billingtransactionitemid
    	inner join bil_txn_invoicereturn ret on rti.billreturnid = ret.billreturnid
    	inner join pat_patient pat on pat.patientid = ret.patientid
    	where (ret.createdon)::date between p_fromdate and p_todate
    		and itm.servicedepartmentname = coalesce(p_srvdeptname, itm.servicedepartmentname)
    		and (
    			coalesce(itm.prescriberid, 0) = coalesce(p_doctorid, 0)
    			or coalesce(itm.performerid, 0) = coalesce(p_doctorid, 0)
    			or coalesce(itm.referredbyid, 0) = coalesce(p_doctorid, 0)
    			);
END;
$$ LANGUAGE plpgsql;