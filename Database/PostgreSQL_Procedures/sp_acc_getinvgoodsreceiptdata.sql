DROP FUNCTION IF EXISTS sp_acc_getinvgoodsreceiptdata();

CREATE OR REPLACE FUNCTION sp_acc_getinvgoodsreceiptdata(

)
RETURNS SETOF refcursor AS $$
DECLARE
    ref refcursor := 'ref';
BEGIN
    OPEN ref FOR
    WITH GroupedGR AS (
        SELECT 
            (gri."CreatedOn")::date AS "CreatedDate",
            SUM(gri."TotalAmount" - gri."VATAmount") AS "RawTotalAmount",
            SUM(gri."VATAmount") AS "VAT"
        FROM "INV_TXN_GoodsReceipt" gr
        JOIN "INV_TXN_GoodsReceiptItems" gri ON gr."GoodsReceiptID" = gri."GoodsReceiptId"
        WHERE gr."IsTransferredToACC" = false OR gr."IsTransferredToACC" IS NULL
        GROUP BY (gri."CreatedOn")::date
    )
    SELECT 
        ROUND("RawTotalAmount"::numeric, 2) AS "TotalAmount",
        "VAT",
        "CreatedDate" AS "CreatedOn",
        'Inventory Goods Receipt entries to accounting on ' || "CreatedDate"::varchar AS "Remarks",
        (
            SELECT STRING_AGG((g."GoodsReceiptID")::varchar, ',') 
            FROM "INV_TXN_GoodsReceipt" AS g
            WHERE "CreatedDate" = (g."CreatedOn")::date
        ) AS "ReferenceIds"
    FROM GroupedGR;

    RETURN NEXT ref;
END;
$$ LANGUAGE plpgsql;