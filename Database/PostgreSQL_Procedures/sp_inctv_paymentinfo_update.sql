CREATE OR REPLACE FUNCTION sp_inctv_paymentinfo_update(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_employeeid INT DEFAULT NULL,
    p_paymentinfoid INT DEFAULT NULL
)
RETURNS TABLE (
    "Result" VARCHAR
) AS $$
BEGIN
    
    	update inctv_txn_incentivefractionitem set ispaymentprocessed=1, paymentinfoid=p_paymentinfoid
    	where incentivereceiverid = p_employeeid and (transactiondate)::date between p_fromdate and p_todate;
    	
    	RETURN QUERY SELECT 'success' AS "Result";
END;
$$ LANGUAGE plpgsql;