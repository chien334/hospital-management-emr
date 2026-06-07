CREATE OR REPLACE FUNCTION sp_acc_post_bil_ipd_getinpatientsales(
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
     exec sp_acc_post_bil_ipd_getinpatientsales '2023-08-18',1
    
     change history
    sn.                auther/timestamp                   description
    1.                 devn/12th june 23                initial draft of sp to get ipd billing sales.
    2.                 devn/4th sept 23                 remove outpatient/inpatient segregation.
    */
    
        
    
        -- return the empty table
        RETURN QUERY SELECT * from v_emptytable;
    --body of this sp has been commented because we are removing outpatient/inpatient segregation..
    /*select 
    	transactiontype
    	,coalesce(ledgerid,0) as ledgerid
    	,coalesce(subledgerid,0) as subledgerid
    	,sum(subtotal) as totalamount
    	,string_agg(convert(text,referenceid), ',') as referenceidcsv
    	,transactiondate as transactiondate
    	,description
    	,1 as displaysequence
    	,0 as drcr
    	,'BIL_Income_Voucher' as basetransactiontype
    	,1 as transactionrefno
    from (
    	select 
    		billingtransactionitemid 'ReferenceId'
    		,'BIL_IPD_Sales' transactiontype
    		,itm.subtotal as "subtotal"
    		,cast(txn.createdon as date) 'TransactionDate'
    		,'IPD Collection for ' + convert(varchar(100), cast(txn.createdon as date)) as description
    		,(
    			select fn_acc_getincomeledgerid(servicedepartmentid, serviceitemid, p_hospitalid,'inpatient')
    			) as ledgerid
    		,(
    			select "fn_acc_getincomesubledgerid"(servicedepartmentid, serviceitemid, p_hospitalid,'inpatient')
    			) as subledgerid
    	from bil_txn_billingtransactionitems itm
    		,bil_txn_billingtransaction txn
    	where txn.billingtransactionid = itm.billingtransactionid and convert(date, txn.createdon) = p_transactiondate
    	and itm.billingtransactionid is not null 
    	and itm.billingtype = 'inpatient' 
    	and coalesce(itm.iscashbillsync, 0) = 0
    	) innertable
    group by innertable.ledgerid
    	,innertable.subledgerid
    	,transactiondate
    	,description
    	,transactiontype
    */
END;
$$ LANGUAGE plpgsql;