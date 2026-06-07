CREATE OR REPLACE FUNCTION sp_acc_getsuspenseaccountreconciliationdetail(
    p_suspenseaccountledgerid INT,
    p_bankledgerid INT
)
RETURNS TABLE (
    "VoucherNumber" VARCHAR,
    "LedgerId" INT,
    "SubLedgerId" INT,
    "DrCr" VARCHAR,
    "Amount" DECIMAL
) AS $$
BEGIN
    /*
    --change history
    s.n.          author/date                 description
    1.            devn/30th,june'23           initial draft to get suspense a/c reconciliation detail.
    */
    begin
    	RETURN QUERY SELECT vouchernumber AS "VoucherNumber"
    		,partyledgerid AS "LedgerId"
    		,partysubledgerid AS "SubLedgerId"
    		,case when drcr = 1 then 0
    			else 1 end AS "DrCr"
    		,bankbalance AS "Amount"
    	from acc_txn_bank_reconciliation reconcile
    	left join acc_map_bankandsuspenseaccountreconciliation map on reconcile.vouchernumber = map.bankreconciliationvouchernumber
    	where map.bankandsuspenseaccountreconciliationid is null 
    	and reconcile.partyledgerid = p_suspenseaccountledgerid 
    	and ledgerid = p_bankledgerid;
    end;
END;
$$ LANGUAGE plpgsql;