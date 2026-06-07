CREATE OR REPLACE FUNCTION sp_acc_post_bil_ipd_getinpatientsalesreturn(
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
     exec sp_acc_post_bil_ipd_getinpatientsalesreturn '2023-06-13',1
    
     change history
    sn.                auther/timestamp                   description
    1.                 devn/13th june 23                initial draft of sp to get ipd billing sale return.
    2.                 devn/4th sept 23                 remove outpatient/inpatient segregation.
    */
    
        
    
        -- return the empty table
        RETURN QUERY SELECT * from v_emptytable;
    --body of this sp has been commented because we are removing outpatient/inpatient segregation..
    	/*select transactiontype
    		,coalesce(ledgerid, 0) as ledgerid
    		,coalesce(subledgerid, 0) as subledgerid
    		,sum(subtotal) as totalamount
    		,string_agg(convert(text,referenceid), ',') as referenceidcsv
    		,transactiondate as transactiondate
    		,description
    		,1 as displaysequence
    		,1 as drcr
    		,'BIL_Income_Voucher' as basetransactiontype
    		,1 as transactionrefno
    	from (
    		select itm.billreturnitemid as referenceid
    			,'BIL_IPD_SaleReturn' transactiontype
    			,itm.retsubtotal as "subtotal"
    			,cast(txn.createdon as date) 'TransactionDate'
    			,'IPD Refund for ' + convert(varchar(100), cast(txn.createdon as date)) as description
    			,(
    				select fn_acc_getincomeledgerid(servicedepartmentid, serviceitemid, p_hospitalid, 'inpatient')
    				) as ledgerid
    			,(
    				select "fn_acc_getincomesubledgerid"(servicedepartmentid, serviceitemid, p_hospitalid, 'inpatient')
    				) as subledgerid
    		from bil_txn_invoicereturnitems itm
    		join bil_txn_invoicereturn txn on itm.billreturnid = txn.billreturnid
    		where txn.billreturnid = itm.billreturnid 
    		and convert(date, txn.createdon) = p_transactiondate 
    		and coalesce(itm.iscashbillsynctoacc, 0) = 0 
    		and itm.billingtype = 'inpatient'
    		) innertable
    	group by innertable.ledgerid
    		,innertable.subledgerid
    		,transactiondate
    		,description
    		,transactiontype
    */
END;
$$ LANGUAGE plpgsql;