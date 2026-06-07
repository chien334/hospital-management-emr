CREATE OR REPLACE FUNCTION sp_acc_post_bil_getuserwisenetcollection(
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
    "BaseTransactionType" TIMESTAMP,
    "DrCr" VARCHAR,
    "TransactionRefNo" TIMESTAMP
) AS $$
BEGIN
    /*
     exec sp_acc_post_bil_getuserwisenetcollection '2023-06-16',1
    
     change history
    sn.                auther/timestamp                   description
    1.                 devn/11th june 23                stored procedure to get userwise billing cash collection for post to accounting.
    2.                 devn/29th oct 23                 paymentmode wise cash collection segregation.
    */
    
    RETURN QUERY SELECT * from (
    select 
    	innerdata.transactiontype AS "TransactionType"
    	,coalesce(innerdata.ledgerid,0) AS "LedgerId"
    	,innerdata.subledgerid AS "SubLedgerId"
    	,abs(innerdata.totalamount) AS "TotalAmount"
    	,innerdata.referenceidcsv AS "ReferenceIdCSV"
    	,innerdata.transactiondate AS "TransactionDate"
    	,innerdata.description AS "Description"
    	,innerdata.displaysequence AS "DisplaySequence"
    	,innerdata.basetransactiontype AS "BaseTransactionType"
    	,case when innerdata.totalamount >= 0 then 1
    	else 0 end AS "DrCr"
    	,1 AS "TransactionRefNo"
    	from(
    	select 'BIL_UserWiseNetCollection' AS "TransactionType"
    		,map.ledgerid AS "LedgerId"
    		,coalesce(map.subledgerid,0) AS "SubLedgerId"
    		,coalesce(sum(inamount) - sum(outamount), 0) AS "TotalAmount"
    		,string_agg((cashtxnid)::varchar,',') AS "ReferenceIdCSV"
    		,cast(transactiondate as date) AS "TransactionDate"
    		,'BILLING/CASH COLLECTION ON-' || (cast(transactiondate as date))::varchar AS "Description"
    		,1 AS "DisplaySequence"
    		,'BIL_Income_Voucher' AS "BaseTransactionType"
    	from txn_empcashtransaction txn
    	join acc_ledger_mapping map on txn.paymentmodesubcategoryid = map.referenceid
    	where (transactiondate)::date = p_transactiondate
    	and map.ledgertype = 'paymentmodes'
    	and istransferredtoacc = 0 and transactiontype in (
    			'CashSales'
    			,'Deposit'
    			,'SalesReturn'
    			,'ReturnDeposit'
    			,'depositdeduct'
    			,'CashDiscountGiven'
    			,'CollectionFromReceivable'
    			,'SchemeRefund'
    			)
    	group by cast(transactiondate as date),ledgerid,subledgerid
    		) innerdata
    		) groupeddata where groupeddata.totalamount > 0;
END;
$$ LANGUAGE plpgsql;