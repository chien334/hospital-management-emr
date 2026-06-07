CREATE OR REPLACE FUNCTION sp_acc_post_phrm_getuserwisenetcollection(
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
     exec sp_acc_post_phrm_getuserwisenetcollection '2023-06-18',1
    
     change history
    sn.                auther/timestamp                   description
    1.                 devn/18th june 23                stored procedure to get userwise pharmacy cash collection for post to accounting.
    */
    begin
    RETURN QUERY SELECT 
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
    	select 'PHRM_UserWiseNetCollection' AS "TransactionType"
    		,(
    			select ledgerid
    			from acc_ledger
    			where name = 'ACA_CASH_IN_HAND_CASH'
    			) AS "LedgerId"
    		,0 AS "SubLedgerId"
    		,coalesce(sum(inamount) - sum(outamount), 0) AS "TotalAmount"
    		,string_agg(cashtxnid,',') AS "ReferenceIdCSV"
    		,cast(transactiondate as date) AS "TransactionDate"
    		,'PHARMACY/CASH COLLECTION ON-' || (cast(transactiondate as date))::varchar AS "Description"
    		,1 AS "DisplaySequence"
    		,'PHRM_Income_Voucher' AS "BaseTransactionType"
    	from phrm_employeecashtransaction txn
    	where (transactiondate)::date = p_transactiondate 
    	and coalesce(istransferredtoacc,0) = 0 
    	and transactiontype in (
    			'CashSales'
    			,'Deposit'
    			,'SalesReturn'
    			,'ReturnDeposit'
    			,'depositdeduct'
    			,'CashDiscountGiven'
    			,'CollectionFromReceivable'
    			)
    	group by cast(transactiondate as date)
    		) innerdata;
    end;
END;
$$ LANGUAGE plpgsql;