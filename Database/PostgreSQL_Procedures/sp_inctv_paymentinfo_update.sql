CREATE OR REPLACE FUNCTION sp_inctv_paymentinfo_update(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_employeeid INT DEFAULT NULL,
    p_paymentinfoid INT DEFAULT NULL
)
RETURNS TABLE (
    result VARCHAR
) AS $$
BEGIN
    UPDATE "INCTV_TXN_IncentiveFractionItem" 
    SET "IsPaymentProcessed" = TRUE, "PaymentInfoId" = p_paymentinfoid
    WHERE "IncentiveReceiverId" = p_employeeid 
      AND "TransactionDate"::DATE BETWEEN p_fromdate AND p_todate;

    RETURN QUERY SELECT 'success'::VARCHAR AS result;
END;
$$ LANGUAGE plpgsql;
