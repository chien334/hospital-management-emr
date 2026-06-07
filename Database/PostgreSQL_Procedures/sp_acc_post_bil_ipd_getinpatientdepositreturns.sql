CREATE OR REPLACE FUNCTION sp_acc_post_bil_ipd_getinpatientdepositreturns(
    p_transactiondate DATE,
    p_hospitalid INT
)
RETURNS TABLE (
    "*" VARCHAR
) AS $$
BEGIN
    DROP TABLE IF EXISTS v_emptytable;
    CREATE TEMP TABLE v_emptytable (
        Name VARCHAR(255)
    );
    /*
     exec sp_acc_post_bil_ipd_getinpatientdepositreturns '2023-06-15',1
    
     change history
    sn.                auther/timestamp                   description
    1.                 devn/15th june 23                initial draft of sp to get ipd billing deposit(return + depositdeduct) transactions.
    2.                 devn/4th sept 23                 remove outpatient/inpatient segregation.
    */
    
        
    
        -- return the empty table
        RETURN QUERY SELECT * from v_emptytable;
    --body of this sp has been commented because we are removing outpatient/inpatient segregation..
    /*select 
    	transactiontype
    	,coalesce(ledgerid,0) as ledgerid
    	,coalesce((select subledgerid from acc_mst_subledger where ledgerid= innertable.ledgerid and subledgername ='IPD'),0) as subledgerid
    	,sum(totalamount) as totalamount
    	,string_agg(referenceid, ',') as referenceidcsv
    	,transactiondate as transactiondate
    	,description
    	,1 as displaysequence
    	,1 as drcr
    	,'BIL_Income_Voucher' as basetransactiontype
    	,1 as transactionrefno
    from (
    	select 
    		depositid as referenceid
    		,'BIL_IPD_DepositAdjustment' as transactiontype
    		,deposit.outamount as totalamount
    		,cast(deposit.createdon as date) as transactiondate
    		,'IPD Deposit Adjusted for ' + convert(varchar(100), cast(deposit.createdon as date)) as description
    		,(select ledgerid from acc_ledger 
    			where name ='LCL_PATIENT_DEPOSITS_(LIABILITY)_ADVANCE_FROM_PATIENT') as ledgerid
    	from bil_txn_deposit deposit
    		where convert(date, deposit.createdon) = p_transactiondate
    	and deposit.modulename = 'Billing' 
    	and coalesce(deposit.isdepositsync,0) = 0 
    	and deposit.visittype = 'inpatient'
    	and deposit.transactiontype in('ReturnDeposit','depositdeduct')
    	) innertable
    group by innertable.ledgerid
    	,transactiondate
    	,description
    	,transactiontype
    */
END;
$$ LANGUAGE plpgsql;