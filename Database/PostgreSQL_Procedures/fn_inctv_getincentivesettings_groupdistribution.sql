CREATE OR REPLACE FUNCTION fn_inctv_getincentivesettings_groupdistribution()
RETURNS TABLE (
    "FromEmployeeId" INT,
    "ToEmployeeId" INT,
    "ToEmployeeName" VARCHAR,
    "DistributionPercent" DOUBLE PRECISION,
    "ServiceItemId" INT,
    "ServiceDepartmentId" INT,
    "IntegrationItemId" INT,
    "ItemName" VARCHAR,
    "IncentiveType" VARCHAR,
    "TDSPercent" DOUBLE PRECISION,
    "PriceCategoryId" INT,
    "PriceCategoryName" VARCHAR,
    "BillingTypesApplicable" VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT grpDist."FromEmployeeId",
           grpDist."DistributeToEmployeeId" AS "ToEmployeeId",
           toEmp."FullName"::VARCHAR AS "ToEmployeeName",
           grpDist."DistributionPercent",
           grpDist."ServiceItemId",
           cfgPrice."ServiceDepartmentId",
           cfgPrice."IntegrationItemId",
           cfgPrice."ItemName"::VARCHAR,
           grpDist."IncentiveType"::VARCHAR,
           inctvInfo."TDSPercent",
           empBilMap."PriceCategoryId",
           pricCat."PriceCategoryName"::VARCHAR,
           empBilMap."BillingTypesApplicable"::VARCHAR
    FROM "INCTV_CFG_ItemGroupDistribution" grpDist
    INNER JOIN "EMP_Employee" fromEmp ON grpDist."FromEmployeeId" = fromEmp."EmployeeId"
    INNER JOIN "EMP_Employee" toEmp ON grpDist."DistributeToEmployeeId" = toEmp."EmployeeId"
    INNER JOIN "INCTV_EmployeeIncentiveInfo" inctvInfo ON grpDist."FromEmployeeId" = inctvInfo."EmployeeId"
    INNER JOIN "BIL_MST_ServiceItem" cfgPrice ON grpDist."ServiceItemId" = cfgPrice."ServiceItemId"
    INNER JOIN "INCTV_MAP_EmployeeBillItemsMap" empBilMap ON grpDist."EmployeeBillItemsMapId" = empBilMap."EmployeeBillItemsMapId"
    INNER JOIN "BIL_CFG_PriceCategory" pricCat ON empBilMap."PriceCategoryId" = pricCat."PriceCategoryId"
    WHERE grpDist."IsActive" = TRUE
      AND empBilMap."IsActive" = TRUE;
END;
$$ LANGUAGE plpgsql;
