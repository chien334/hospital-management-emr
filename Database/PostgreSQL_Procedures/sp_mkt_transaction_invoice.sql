DROP FUNCTION IF EXISTS sp_mkt_transaction_invoice(date, date);
DROP FUNCTION IF EXISTS sp_mkt_transaction_invoice(timestamp without time zone, timestamp without time zone);

CREATE OR REPLACE FUNCTION sp_mkt_transaction_invoice(
    p_fromdate timestamp,
    p_todate timestamp
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref refcursor := 'ref';
BEGIN
    OPEN ref FOR
    SELECT 
         bt."BillingTransactionId"
        ,bt."CreatedOn"
        ,bt."InvoiceNo"
        ,pat."PatientCode"
        ,pv."PatientVisitId"
        ,pat."PatientId"
        ,pat."ShortName"
        ,bt."FiscalYearId"
        ,CONCAT(fy."FiscalYearFormatted", '-', bt."InvoiceCode", bt."InvoiceNo") AS "InvoiceNoFormatted"
        ,CONCAT(pat."Age", '/', pat."Gender") AS "Age"
        ,pat."Gender"
        ,bt."TotalAmount"
        ,COALESCE(bt."RetTotalAmount", 0) AS "ReturnCashAmount"
        ,COALESCE(bt."TotalAmount", 0) - COALESCE(bt."RetTotalAmount", 0) AS "NetAmount"
        ,COUNT(rc."BillingTransactionId")::integer AS "ReferralCount"
    FROM (
        SELECT 
            txn."BillingTransactionId", 
            txn."CreatedOn", 
            txn."InvoiceNo", 
            txn."TotalAmount", 
            ret."RetTotalAmount", 
            txn."PatientId", 
            txn."PatientVisitId", 
            txn."FiscalYearId", 
            txn."InvoiceCode" 
        FROM (
            SELECT * FROM "BIL_TXN_BillingTransaction" 
            WHERE "CreatedOn"::date BETWEEN p_fromdate::date AND p_todate::date
        ) txn
        LEFT JOIN (
            SELECT "BillingTransactionId", SUM(COALESCE("TotalAmount", 0)) AS "RetTotalAmount" 
            FROM "BIL_TXN_InvoiceReturn"
            GROUP BY "BillingTransactionId"
        ) ret ON txn."BillingTransactionId" = ret."BillingTransactionId"
    ) bt
    LEFT JOIN (
        SELECT * FROM "MKT_TXN_ReferralCommission" 
        WHERE "IsActive" = true
    ) rc ON rc."BillingTransactionId" = bt."BillingTransactionId"
    INNER JOIN "PAT_Patient" pat ON bt."PatientId" = pat."PatientId"
    INNER JOIN "PAT_PatientVisits" pv ON bt."PatientVisitId" = pv."PatientVisitId"
    INNER JOIN "BIL_CFG_FiscalYears" fy ON bt."FiscalYearId" = fy."FiscalYearId"
    GROUP BY 
         bt."BillingTransactionId"
        ,bt."CreatedOn"
        ,bt."InvoiceNo"
        ,pat."PatientCode"
        ,pv."PatientVisitId"
        ,pat."PatientId"
        ,pat."ShortName"
        ,pat."Age"
        ,pat."Gender"
        ,bt."FiscalYearId"
        ,bt."TotalAmount"
        ,bt."RetTotalAmount"
        ,bt."InvoiceCode"
        ,fy."FiscalYearFormatted"
    ORDER BY bt."CreatedOn" DESC;

    RETURN NEXT ref;
END;
$$ LANGUAGE plpgsql;