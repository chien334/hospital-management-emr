CREATE OR REPLACE FUNCTION sp_acc_post_bil_opd_getoutpatientdepositreturns(
    p_transactiondate DATE,
    p_hospitalid INT
)
RETURNS TABLE (
    "TransactionType" TIMESTAMP,
    "LedgerId" INT,
    "SubLedgerId" INT,
    "TotalAmount" DECIMAL,
    "ReferenceIdCSV" INT,
    "TransactionDate" TIMESTAMP,
    "Description" TIMESTAMP,
    "DisplaySequence" VARCHAR,
    "DrCr" VARCHAR,
    "BaseTransactionType" TIMESTAMP,
    "TransactionRefNo" TIMESTAMP
) AS $$
BEGIN
    /*
     exec sp_acc_post_bil_opd_getoutpatientdepositreturns '2023-06-15',1
    
     change history
    sn.                auther/timestamp                   description
    1.                 devn/15th june 23                initial draft of sp to get opd billing deposit(return + depositdeduct) transactions.
    2.                 devn/4th sept 23                 remove outpatient/inpatient segregation.
    */
    
    RETURN QUERY SELECT 
    	transactiontype
    	,coalesce(ledgerid,0) AS "LedgerId"
    	,coalesce((select subledgerid from acc_mst_subledger where ledgerid= innertable.ledgerid and subledgername ='OPD'),0) AS "SubLedgerId"
    	,sum(totalamount) AS "TotalAmount"
    	,string_agg(referenceid, ',') AS "ReferenceIdCSV"
    	,transactiondate AS "TransactionDate"
    	,description
    	,1 AS "DisplaySequence"
    	,1 AS "DrCr"
    	,'BIL_Income_Voucher' AS "BaseTransactionType"
    	,1 AS "TransactionRefNo"
    from (
    	select 
    		depositid as referenceid
    		,'BIL_OPD_DepositAdjustment' AS "TransactionType"
    		,deposit.outamount AS "TotalAmount"
    		,cast(deposit.createdon as date) AS "TransactionDate"
    		,'Deposit Adjusted for ' || (cast(deposit.createdon as date))::varchar AS "Description"
    		,(select ledgerid from acc_ledger 
    			where name ='LCL_PATIENT_DEPOSITS_(LIABILITY)_ADVANCE_FROM_PATIENT') AS "LedgerId"
    	from bil_txn_deposit deposit
    		where (deposit.createdon)::date = p_transactiondate
    	and deposit.modulename = 'Billing' 
    	and coalesce(deposit.isdepositsync,0) = 0 
    	--and deposit.visittype = 'outpatient'
    	and deposit.transactiontype in('ReturnDeposit','depositdeduct')
    	) innertable
    group by innertable.ledgerid
    	,transactiondate
    	,description
    	,transactiontype;
END;
$$ LANGUAGE plpgsql;