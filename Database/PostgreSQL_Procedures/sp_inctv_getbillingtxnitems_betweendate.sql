CREATE OR REPLACE FUNCTION sp_inctv_getbillingtxnitems_betweendate(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL
)
RETURNS TABLE (
    "PatientId" INT,
    "PatientName" VARCHAR,
    "PatientCode" VARCHAR,
    "InvoiceNo" VARCHAR,
    "TransactionDate" TIMESTAMP,
    "BillingTransactionId" INT,
    "BillingTransactionItemId" INT,
    "ServiceDepartmentName" VARCHAR,
    "ItemName" VARCHAR,
    "ItemId" INT,
    "Quantity" INT,
    "TotalAmount" DECIMAL,
    "AssignedToEmpName" VARCHAR,
    "ReferredByEmpName" VARCHAR,
    "FractionCount" TIMESTAMP,
    "PriceCategoryName" DECIMAL,
    "PriceCategoryId" INT
) AS $$
BEGIN
    /*
     file: sp_inctv_getbillingtxnitems_betweendate
     description:  to get billing transaction items for fraction,
     conditions/checks: 
       1. returned items are removed.
       2. joining with employee table twice for assigned and referredby employee
       3. fractioncount (number) is the count of fractionitem  in incentive_fractionitem table for billingtransactionitemid
            
     remarks: this can later be extended and used in billing -> edit doctor as well since the fields are preety much similar.
     change history:
     s.no.    changedate/by					remarks
     1.      10apr'20/Sud					Initial Draft 
     2.      11June2020/Pratik				GroupDistribution Impacts on Existing Functionalities 
     3.		 22ndSept'23/krishna					read pricecategory 
    */
    
    
    RETURN QUERY SELECT
         pat.patientid, 
    	 pat.shortname AS "PatientName", 
    	 pat.patientcode,
    	 fyear.fiscalyearformatted ||'-'||biltxn.invoicecode || cast(biltxn.invoiceno as varchar(20))AS "InvoiceNo", 
    	 biltxn.createdon AS "TransactionDate",  
    	 biltxn.billingtransactionid, 
    	 txnitm.billingtransactionitemid AS "BillingTransactionItemId", 
    	 txnitm.servicedepartmentname, 
    	 txnitm.itemname,
    	 txnitm.itemid,
    	 txnitm.quantity , 
    	 txnitm.totalamount,
    	 txnitm.performername AS "AssignedToEmpName", 
    	 emp2.fullname AS "ReferredByEmpName", 
    	 inctvtxnitm.frccount AS "FractionCount",
    	 pricecat.pricecategoryname,
    	 pricecat.pricecategoryid
    from  bil_cfg_fiscalyears fyear, 
    	pat_patient pat,
        bil_txn_billingtransaction biltxn 
    	     join bil_txn_billingtransactionitems txnitm
    	on biltxn.billingtransactionid = txnitm.billingtransactionid
    	inner join bil_cfg_pricecategory pricecat on txnitm.pricecategoryid = pricecat.pricecategoryid
    	    --left join emp_employee emp1 
    		   --on txnitm.providerid = emp1.employeeid  -- for assignedtodoctor
            left join emp_employee emp2
    		   on txnitm.prescriberid= emp2.employeeid
        left join (select billingtransactionitemid, count(*) as "frccount"  from inctv_txn_incentivefractionitem where isactive=1 group by billingtransactionitemid ) inctvtxnitm
    	    on txnitm.billingtransactionitemid = inctvtxnitm.billingtransactionitemid
    
    where 
    	    biltxn.fiscalyearid = fyear.fiscalyearid 
    	and biltxn.patientid=pat.patientid
    	and (biltxn.createdon)::date between p_fromdate and p_todate
    	and coalesce(biltxn.returnstatus,0) = 0;
END;
$$ LANGUAGE plpgsql;