CREATE OR REPLACE FUNCTION sp_acc_post_inv_getgoodreceiptpurchasetransactions(
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
DECLARE
    v_vatparam VARCHAR;
    v_isvatregistered BOOLEAN;
BEGIN
    /*
     exec sp_acc_post_inv_getgoodreceiptpurchasetransactions '2023-06-22',1
     change history
    sn.                auther/timestamp                   description
    1.                 devn/22th june 23                initial draft of sp to get inventory good receipt (purchase) transactions.
    2.                 devn/29th oct 23                 include vatamount depending on parameter whether hospital is vatregistered or not.
    */
    
    
    v_vatparam := (select parametervalue 
                                     from core_cfg_parameters 
    								 where parametergroupname ='Accounting' and parametername='VatRegisteredHospital');
    v_isvatregistered := iif(v_vatparam = 'true', 1, 0);
    RETURN QUERY SELECT 
    	transactiontype
    	,coalesce(ledgerid,0) AS "LedgerId"
    	,coalesce((select  subledgerid from acc_mst_subledger where ledgerid = innertable.ledgerid and isdefault = 1 limit 1),0) AS "SubLedgerId"
    	,sum(totalamount) AS "TotalAmount"
    	,string_agg(referenceid, ',') AS "ReferenceIdCSV"
    	,transactiondate AS "TransactionDate"
    	,description
    	,1 AS "DisplaySequence"
    	,1 AS "DrCr"
    	,'INV_Purchase' AS "BaseTransactionType"
    	,goodsreceiptid AS "TransactionRefNo"
    from (
    	select 
    		goodsreceiptid as referenceid
    		,'INV_GoodReceipt_Purchase' AS "TransactionType"
    		,case when v_isvatregistered = 1 then (gr.totalamount - gr.vattotal) else gr.totalamount end AS "TotalAmount"
    		,cast(gr.createdon as date) AS "TransactionDate"
    		,'Inventory GRN: ' || (gr.goodsreceiptno)::varchar ||' for-' || (cast(gr.goodsreceiptdate as date))::varchar || '/' || upper(gr.paymentmode) ||' Purchase.' AS "Description"
    		,(select ledgerid from acc_ledger where name='ACA_MERCHANDISE_INVENTORYMERCHANDISE_INVENTORY') AS "LedgerId"
    		,0 AS "SubLedgerId"
    		,gr.goodsreceiptid
    	from inv_txn_goodsreceipt gr
    		where (gr.goodsreceiptdate)::date = p_transactiondate
    	and coalesce(gr.istransferredtoacc,0) = 0 
    	and gr.iscancel != 1
    	) innertable
    group by innertable.ledgerid
    	,innertable.subledgerid
    	,transactiondate
    	,description
    	,transactiontype
    	,innertable.goodsreceiptid;
END;
$$ LANGUAGE plpgsql;