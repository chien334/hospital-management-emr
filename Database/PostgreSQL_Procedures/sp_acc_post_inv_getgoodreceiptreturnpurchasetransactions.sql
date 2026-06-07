CREATE OR REPLACE FUNCTION sp_acc_post_inv_getgoodreceiptreturnpurchasetransactions(
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
     exec sp_acc_post_inv_getgoodreceiptreturnpurchasetransactions '2023-06-22',1
     change history
    sn.                auther/timestamp                   description
    1.                 devn/22th june 23                initial draft of sp to get inventory good receipt return (purchase) transactions.
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
    	,0 AS "DrCr"
    	,'INV_PurchaseReturn' AS "BaseTransactionType"
    	,returntovendorid AS "TransactionRefNo"
    from (
    	select 
    		returntovendorid as referenceid
    		,'INV_GoodReceiptReturn_Purchase' AS "TransactionType"
    		,case when v_isvatregistered = 1 then (grreturn.totalamount - grreturn.vattotal) else grreturn.totalamount end  AS "TotalAmount"
    		,cast(grreturn.createdon as date) AS "TransactionDate"
    		,'CRN: ' || (grreturn.creditnoteid)::varchar ||' for-' || (cast(grreturn.createdon as date))::varchar AS "Description"
    		,(select ledgerid from acc_ledger where name='ACA_MERCHANDISE_INVENTORYMERCHANDISE_INVENTORY') AS "LedgerId"
    		,0 AS "SubLedgerId"
    		,grreturn.returntovendorid
    	from inv_txn_returntovendor grreturn
    		where (grreturn.returndate)::date = p_transactiondate
    	and coalesce(grreturn.istransferredtoacc,0) = 0 
    	) innertable
    group by innertable.ledgerid
    	,innertable.subledgerid
    	,transactiondate
    	,description
    	,transactiontype
    	,innertable.returntovendorid;
END;
$$ LANGUAGE plpgsql;