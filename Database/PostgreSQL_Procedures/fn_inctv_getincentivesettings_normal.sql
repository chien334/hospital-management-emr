CREATE OR REPLACE FUNCTION fn_inctv_getincentivesettings_normal()
RETURNS TABLE (
    "ServiceItemId" INT,
    "EmployeeIncentiveInfoId" INT,
    "ServiceDepartmentId" INT,
    "IntegrationItemId" INT,
    "ItemName" VARCHAR,
    "PriceCategoryId" INT,
    "PriceCategoryName" VARCHAR,
    "EmployeeId" INT,
    "FullName" VARCHAR,
    "PerformerPercent" DOUBLE PRECISION,
    "PrescriberPercent" DOUBLE PRECISION,
    "ReferrerPercent" DOUBLE PRECISION,
    "TDSPercent" DOUBLE PRECISION,
    "BillingTypesApplicable" VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT empBillItmMap."ServiceItemId",
           empInctvInfo."EmployeeIncentiveInfoId",
           serviceItem."ServiceDepartmentId",
           serviceItem."IntegrationItemId",
           serviceItem."ItemName"::VARCHAR,
           priceCat."PriceCategoryId",
           priceCat."PriceCategoryName"::VARCHAR,
           emp."EmployeeId",
           emp."FullName"::VARCHAR,
           empBillItmMap."PerformerPercent",
           empBillItmMap."PrescriberPercent",
           empBillItmMap."ReferrerPercent",
           empInctvInfo."TDSPercent",
           empBillItmMap."BillingTypesApplicable"::VARCHAR
    FROM "INCTV_EmployeeIncentiveInfo" empInctvInfo
    INNER JOIN "INCTV_MAP_EmployeeBillItemsMap" empBillItmMap ON empInctvInfo."EmployeeId" = empBillItmMap."EmployeeId"
    INNER JOIN "BIL_MST_ServiceItem" serviceItem ON empBillItmMap."ServiceItemId" = serviceItem."ServiceItemId"
    INNER JOIN "BIL_CFG_PriceCategory" priceCat ON empBillItmMap."PriceCategoryId" = priceCat."PriceCategoryId"
    INNER JOIN "EMP_Employee" emp ON empInctvInfo."EmployeeId" = emp."EmployeeId"
    WHERE empInctvInfo."IsActive" = TRUE
      AND empBillItmMap."IsActive" = TRUE
      AND COALESCE(empBillItmMap."HasGroupDistribution", FALSE) = FALSE;
END;
$$ LANGUAGE plpgsql;
