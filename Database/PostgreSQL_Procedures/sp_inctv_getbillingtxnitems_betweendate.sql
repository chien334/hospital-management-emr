CREATE OR REPLACE FUNCTION sp_inctv_getbillingtxnitems_betweendate(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL
)
RETURNS TABLE (
    "PatientId" INT,
    "PatientName" VARCHAR,
    "PatientCode" VARCHAR,
    "InvoiceNo" VARCHAR,
    "TransactionDate" TIMESTAMP,
    "BillingTransactionId" INT,
    "BillingTransactionItemId" INT,
    "ServiceDepartmentName" VARCHAR,
    "ItemName" VARCHAR,
    "ItemId" INT,
    "Quantity" INT,
    "TotalAmount" DECIMAL,
    "AssignedToEmpName" VARCHAR,
    "ReferredByEmpName" VARCHAR,
    "FractionCount" INT,
    "PriceCategoryName" VARCHAR,
    "PriceCategoryId" INT
) AS $$
#variable_conflict use_column
BEGIN
    /*
     file: sp_inctv_getbillingtxnitems_betweendate
     description:  to get billing transaction items for fraction,
     conditions/checks: 
       1. returned items are removed.
       2. joining with employee table twice for assigned and referredby employee
       3. fractioncount (number) is the count of fractionitem  in incentive_fractionitem table for billingtransactionitemid
            
     remarks: this can later be extended and used in billing -> edit doctor as well since the fields are preety much similar.
     change history:
     s.no.    changedate/by					remarks
     1.      10apr'20/Sud					Initial Draft 
     2.      11June2020/Pratik				GroupDistribution Impacts on Existing Functionalities 
     3.		 22ndSept'23/krishna					read pricecategory 
    */
    
    RETURN QUERY SELECT
        pat."PatientId"::INT, 
        pat."ShortName"::VARCHAR AS "PatientName", 
        pat."PatientCode"::VARCHAR,
        (fyear."FiscalYearFormatted" || '-' || biltxn."InvoiceCode" || CAST(biltxn."InvoiceNo" AS VARCHAR(20)))::VARCHAR AS "InvoiceNo", 
        biltxn."CreatedOn"::TIMESTAMP AS "TransactionDate",  
        biltxn."BillingTransactionId"::INT, 
        txnitm."BillingTransactionItemId"::INT AS "BillingTransactionItemId", 
        txnitm."ServiceDepartmentName"::VARCHAR, 
        txnitm."ItemName"::VARCHAR,
        txnitm."ItemId"::INT,
        txnitm."Quantity"::INT , 
        txnitm."TotalAmount"::DECIMAL,
        txnitm."PerformerName"::VARCHAR AS "AssignedToEmpName", 
        emp2."FullName"::VARCHAR AS "ReferredByEmpName", 
        COALESCE(inctvtxnitm.frccount, 0)::INT AS "FractionCount",
        pricecat."PriceCategoryName"::VARCHAR,
        pricecat."PriceCategoryId"::INT
    FROM "BIL_CFG_FiscalYears" fyear, 
         "PAT_Patient" pat,
         "BIL_TXN_BillingTransaction" biltxn 
    JOIN "BIL_TXN_BillingTransactionItems" txnitm ON biltxn."BillingTransactionId" = txnitm."BillingTransactionId"
    INNER JOIN "BIL_CFG_PriceCategory" pricecat ON txnitm."PriceCategoryId" = pricecat."PriceCategoryId"
    LEFT JOIN "EMP_Employee" emp2 ON txnitm."PrescriberId" = emp2."EmployeeId"
    LEFT JOIN (
        SELECT f."BillingTransactionItemId" AS "SubItemId", COUNT(*)::INT AS "frccount" 
        FROM "INCTV_TXN_IncentiveFractionItem" f
        WHERE f."IsActive" = TRUE 
        GROUP BY f."BillingTransactionItemId"
    ) inctvtxnitm ON txnitm."BillingTransactionItemId" = inctvtxnitm."SubItemId"
    WHERE biltxn."FiscalYearId" = fyear."FiscalYearId"
      AND biltxn."PatientId" = pat."PatientId"
      AND (biltxn."CreatedOn")::DATE BETWEEN (p_fromdate)::DATE AND (p_todate)::DATE
      AND COALESCE(biltxn."ReturnStatus", FALSE) = FALSE;
END;
$$ LANGUAGE plpgsql;