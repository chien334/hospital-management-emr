CREATE OR REPLACE FUNCTION sp_report_bill_counternuserscollectiondaily(
    p_fromdate TIMESTAMP,
    p_todate TIMESTAMP
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'ref1';
    ref2 refcursor := 'ref2';
BEGIN
    -- Table 1: User Day Collection
    OPEN ref1 FOR
    SELECT 
        cash."TransactionDate"::DATE AS "BillDate",
        cash."EmployeeId" AS "EmployeeId",
        emp."FullName" AS "EmployeeName",
        SUM(COALESCE(cash."InAmount", 0) - COALESCE(cash."OutAmount", 0)) AS "UserDayCollection"
    FROM "TXN_EmpCashTransaction" cash
    INNER JOIN "EMP_Employee" emp ON cash."EmployeeId" = emp."EmployeeId"
    WHERE cash."TransactionDate"::DATE BETWEEN p_fromdate::DATE AND p_todate::DATE
      AND cash."TransactionType" NOT IN ('HandoverGiven')
    GROUP BY cash."TransactionDate"::DATE, cash."EmployeeId", emp."FullName";
    RETURN NEXT ref1;

    -- Table 2: Counter Day Collection
    OPEN ref2 FOR
    SELECT 
        cash."TransactionDate"::DATE AS "BillDate",
        cash."CounterID" AS "CounterID",
        cntr."CounterName" AS "CounterName",
        SUM(COALESCE(cash."InAmount", 0) - COALESCE(cash."OutAmount", 0)) AS "CounterDayCollection"
    FROM "TXN_EmpCashTransaction" cash
    INNER JOIN "BIL_CFG_Counter" cntr ON cash."CounterID" = cntr."CounterId"
    WHERE cash."TransactionDate"::DATE BETWEEN p_fromdate::DATE AND p_todate::DATE
      AND cash."TransactionType" NOT IN ('HandoverGiven')
    GROUP BY cash."TransactionDate"::DATE, cash."CounterID", cntr."CounterName";
    RETURN NEXT ref2;
END;
$$ LANGUAGE plpgsql;
