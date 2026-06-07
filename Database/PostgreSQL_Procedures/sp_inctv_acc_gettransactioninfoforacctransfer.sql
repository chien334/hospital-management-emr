CREATE OR REPLACE FUNCTION sp_inctv_acc_gettransactioninfoforacctransfer(
    p_transactiondate DATE
)
RETURNS TABLE (
    "TransactionDate" TIMESTAMP,
    "EmployeeId" INT,
    "EmployeeName" VARCHAR,
    "TransactionType" TIMESTAMP,
    "TotalAmount" DECIMAL,
    "TotalTDS" DECIMAL,
    "Remarks" VARCHAR,
    "ReferenceIds" INT
) AS $$
BEGIN
    /*
    	 file: sp_inctv_acc_gettransactioninfoforacctransfer
    	 description: to get the list doctor's TotalAmount and TDSAmont for given date for Accounting Transfer.
    	 Remarks:
    		* These data will be used in accounting to create a single voucher for that day, where Both Consultant and TDS will be in Credit part.
    		* only those data which are not transferred to accounting will be returned (columnname:  IsTransferToAcc)
    	 Change History:
    	 S.No.   Author/Date               Remarks
    	 1.      Sud/15Mar'20             initial draft
    
    	*/
    	
     
    	RETURN QUERY SELECT 
    	 (transactiondate)::date AS "TransactionDate",
    	  incentivereceiverid AS "EmployeeId",
    	  emp.fullname AS "EmployeeName",
    
    	  'ConsultantIncentive' AS "TransactionType",
    	sum(coalesce(incentiveamount,0)-coalesce(tdsamount,0)) AS "TotalAmount",
    	sum(coalesce(tdsamount,0)) AS "TotalTDS",
    
    	null AS "Remarks",
    	(select string_agg(cast(inctvtxnitemid as varchar), ',') from inctv_txn_incentivefractionitem innertbl 
    	where innertbl.incentivereceiverid= outertbl.incentivereceiverid
    		  and (innertbl.transactiondate)::date = (outertbl.transactiondate)::date) 
    
    	AS "ReferenceIds"
    
    	from inctv_txn_incentivefractionitem outertbl inner join emp_employee emp
    	   on outertbl.incentivereceiverid=emp.employeeid
    
    	where (outertbl.transactiondate)::date=p_transactiondate
    	  and coalesce(istransfertoacc,0) = 0
    	  and coalesce(outertbl.isactive,0) = 1
    
    	group by incentivereceiverid, (transactiondate)::date, emp.fullname
    	order by (outertbl.transactiondate)::date;
END;
$$ LANGUAGE plpgsql;