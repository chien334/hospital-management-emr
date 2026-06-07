CREATE OR REPLACE FUNCTION sp_acc_getallemployee_ledgerlist(
    p_hospitalid INT
)
RETURNS TABLE (
    "LedgerId" INT,
    "EmployeeId" INT,
    "LedgerName" VARCHAR,
    "LedgerCode" VARCHAR,
    "LedgerGroupName" VARCHAR
) AS $$
#variable_conflict use_column
BEGIN
    RETURN QUERY 
    SELECT led."LedgerId", 
           consledmap."ReferenceId" AS "EmployeeId",
           led."LedgerName"::VARCHAR, 
           led."Code"::VARCHAR AS "LedgerCode", 
           ledgrp."LedgerGroupName"::VARCHAR
    FROM "ACC_Ledger" led
    INNER JOIN "ACC_MST_LedgerGroup" ledgrp ON led."LedgerGroupId" = ledgrp."LedgerGroupId"
    INNER JOIN (
        SELECT * 
        FROM "ACC_Ledger_Mapping" 
        WHERE "LedgerType" = 'consultant' 
          AND "HospitalId" = p_hospitalid
    ) consledmap ON led."LedgerId" = consledmap."LedgerId"
    WHERE led."HospitalId" = p_hospitalid 
      AND ledgrp."HospitalId" = p_hospitalid;
END;
$$ LANGUAGE plpgsql;