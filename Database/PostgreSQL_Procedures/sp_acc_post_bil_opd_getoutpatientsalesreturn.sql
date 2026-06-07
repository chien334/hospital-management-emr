CREATE OR REPLACE FUNCTION sp_acc_post_bil_opd_getoutpatientsalesreturn(
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
     exec sp_acc_post_bil_opd_getoutpatientsalesreturn '2023-06-15',1
    
     change history
    sn.                auther/timestamp                   description
    1.                 devn/13th june 23                initial draft of sp to get opd billing sale return.
    2.                 devn/4th sept 23                 remove outpatient/inpatient segregation.
    */
    
    	RETURN QUERY SELECT transactiontype
    		,coalesce(ledgerid, 0) AS "LedgerId"
    		,coalesce(subledgerid, 0) AS "SubLedgerId"
    		,sum(subtotal) AS "TotalAmount"
    		,string_agg(referenceid, ',') AS "ReferenceIdCSV"
    		,transactiondate AS "TransactionDate"
    		,description
    		,1 AS "DisplaySequence"
    		,1 AS "DrCr"
    		,'BIL_Income_Voucher' AS "BaseTransactionType"
    		,1 AS "TransactionRefNo"
    	from (
    		select itm.billreturnitemid as referenceid
    			,'BIL_OPD_SaleReturn' AS "TransactionType"
    			,itm.retsubtotal as "subtotal"
    			,cast(itm.createdon as date) AS "TransactionDate"
    			,'Service Sale Refund for ' || (cast(itm.createdon as date))::varchar AS "Description"
    			,(
    				select fn_acc_getincomeledgerid(servicedepartmentid, serviceitemid, p_hospitalid, 'outpatient')
    				) AS "LedgerId"
    			,(
    				select "fn_acc_getincomesubledgerid"(servicedepartmentid, serviceitemid, p_hospitalid, 'outpatient')
    				) AS "SubLedgerId"
    		from bil_txn_invoicereturnitems itm
    		join bil_txn_invoicereturn txn on itm.billreturnid = txn.billreturnid
    		where txn.billreturnid = itm.billreturnid and (txn.createdon)::date = p_transactiondate and coalesce(itm.iscashbillsynctoacc, 0) = 0
    		--and itm.billingtype = 'outpatient'
    		) innertable
    	group by innertable.ledgerid
    		,innertable.subledgerid
    		,transactiondate
    		,description
    		,transactiontype;
END;
$$ LANGUAGE plpgsql;