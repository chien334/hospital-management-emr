CREATE OR REPLACE FUNCTION sp_phrm_getdispensaryavailablestock(
    p_dispensaryid integer,
    p_pricecategoryid integer DEFAULT NULL
)
RETURNS TABLE (
    "ItemId" integer,
    "BatchNo" character varying,
    "ExpiryDate" timestamp without time zone,
    "ItemName" character varying,
    "SalePrice" numeric,
    "NormalSalePrice" numeric,
    "Unit" character varying,
    "CostPrice" numeric,
    "AvailableQuantity" double precision,
    "IsActive" boolean,
    "GenericName" character varying,
    "GenericId" integer,
    "IsNarcotic" boolean,
    "IsVATApplicable" boolean,
    "SalesVATPercentage" double precision
) AS $$
DECLARE
    v_IsPhrmRateDifferent boolean := false;
BEGIN
    IF p_pricecategoryid IS NOT NULL THEN
        SELECT COALESCE("IsPharmacyRateDifferent", false) INTO v_IsPhrmRateDifferent
        FROM "BIL_CFG_PriceCategory"
        WHERE "PriceCategoryId" = p_pricecategoryid;
    END IF;

    IF NOT v_IsPhrmRateDifferent THEN
        RETURN QUERY
        SELECT
            storeStock."ItemId",
            mststock."BatchNo",
            mststock."ExpiryDate",
            mstitem."ItemName",
            mststock."SalePrice",
            mststock."SalePrice" AS "NormalSalePrice",
            uom."UOMName" AS "Unit",
            mststock."CostPrice" AS "CostPrice",
            SUM(storeStock."AvailableQuantity") AS "AvailableQuantity",
            mstitem."IsActive",
            g."GenericName",
            g."GenericId",
            mstitem."IsNarcotic",
            mstitem."IsVATApplicable",
            mstitem."SalesVATPercentage"
        FROM
            "PHRM_TXN_StoreStock" storeStock
            INNER JOIN "PHRM_MST_Item" mstitem ON storeStock."ItemId" = mstitem."ItemId"
            INNER JOIN "PHRM_MST_Stock" mststock ON storeStock."StockId" = mststock."StockId"
            INNER JOIN "PHRM_MST_UnitOfMeasurement" uom ON mstitem."UOMId" = uom."UOMId"
            INNER JOIN "PHRM_MST_Generic" g ON mstitem."GenericId" = g."GenericId"
        WHERE
            storeStock."StoreId" = p_dispensaryid 
            AND storeStock."AvailableQuantity" > 0
            AND storeStock."IsActive" = true
            AND mstitem."IsActive" = true
        GROUP BY
            storeStock."ItemId",
            mststock."BatchNo",
            mststock."ExpiryDate",
            mstitem."ItemName",
            mststock."SalePrice",
            uom."UOMName",
            mststock."CostPrice",
            mstitem."IsActive",
            g."GenericName",
            g."GenericId",
            mstitem."IsNarcotic",
            mstitem."IsVATApplicable",
            mstitem."SalesVATPercentage";
    ELSE
        RETURN QUERY
        SELECT
            storeStock."ItemId",
            mststock."BatchNo",
            mststock."ExpiryDate",
            mstitem."ItemName",
            COALESCE(priceMap."Price", 0) AS "SalePrice",
            mststock."SalePrice" AS "NormalSalePrice",
            uom."UOMName" AS "Unit",
            mststock."CostPrice" AS "CostPrice",
            SUM(storeStock."AvailableQuantity") AS "AvailableQuantity",
            mstitem."IsActive",
            g."GenericName",
            g."GenericId",
            mstitem."IsNarcotic",
            mstitem."IsVATApplicable",
            mstitem."SalesVATPercentage"
        FROM
            "PHRM_TXN_StoreStock" storeStock
            INNER JOIN "PHRM_MST_Item" mstitem ON storeStock."ItemId" = mstitem."ItemId"
            INNER JOIN "PHRM_MST_Stock" mststock ON storeStock."StockId" = mststock."StockId"
            INNER JOIN "PHRM_MST_UnitOfMeasurement" uom ON mstitem."UOMId" = uom."UOMId"
            INNER JOIN "PHRM_MST_Generic" g ON mstitem."GenericId" = g."GenericId"
            INNER JOIN "PHRM_MAP_MSTItemPriceCategory" priceMap ON storeStock."ItemId" = priceMap."ItemId" AND priceMap."PriceCategoryId" = p_pricecategoryid
        WHERE
            storeStock."StoreId" = p_dispensaryid 
            AND storeStock."AvailableQuantity" > 0
            AND storeStock."IsActive" = true
            AND mstitem."IsActive" = true
        GROUP BY
            storeStock."ItemId",
            mststock."BatchNo",
            mststock."ExpiryDate",
            mstitem."ItemName",
            priceMap."Price",
            mststock."SalePrice",
            uom."UOMName",
            mststock."CostPrice",
            mstitem."IsActive",
            g."GenericName",
            g."GenericId",
            mstitem."IsNarcotic",
            mstitem."IsVATApplicable",
            mstitem."SalesVATPercentage";
    END IF;
END;
$$ LANGUAGE plpgsql;