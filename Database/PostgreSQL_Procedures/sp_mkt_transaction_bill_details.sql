DROP FUNCTION IF EXISTS sp_mkt_transaction_bill_details(integer);

CREATE OR REPLACE FUNCTION sp_mkt_transaction_bill_details(
    p_billingtransactionid integer
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref refcursor := 'ref';
BEGIN
    OPEN ref FOR
    SELECT 
        itms."BillingTransactionId",
        itms."ItemName",
        itms."Quantity",
        COALESCE(retitms."RetQuantity", 0) AS "RetQuantity",
        itms."Quantity" - COALESCE(retitms."RetQuantity", 0) AS "NetQuantity",
        itms."TotalAmount",
        COALESCE(retitms."RetTotalAmount", 0) AS "RetTotalAmount",
        itms."TotalAmount" - COALESCE(retitms."RetTotalAmount", 0) AS "NetTotalAmount"
    FROM (
        SELECT * 
        FROM "BIL_TXN_BillingTransactionItems"
        WHERE "BillingTransactionId" = p_billingtransactionid
    ) itms
    LEFT JOIN (
        SELECT 
            "BillingTransactionItemId",
            SUM(COALESCE("RetTotalAmount", 0)) AS "RetTotalAmount", 
            SUM(COALESCE("RetQuantity", 0)) AS "RetQuantity"
        FROM "BIL_TXN_InvoiceReturnItems"
        GROUP BY "BillingTransactionItemId"
    ) retitms ON itms."BillingTransactionItemId" = retitms."BillingTransactionItemId";

    RETURN NEXT ref;
END;
$$ LANGUAGE plpgsql;