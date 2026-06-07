DROP FUNCTION IF EXISTS sp_danphe_audit_list() CASCADE;
CREATE OR REPLACE FUNCTION sp_danphe_audit_list()
RETURNS TABLE (
    "AuditId" INT,
    "InsertedDate" TIMESTAMP,
    "DbContext" VARCHAR,
    "MachineUserName" VARCHAR,
    "MachineName" VARCHAR,
    "DomainName" VARCHAR,
    "CallingMethodName" VARCHAR,
    "ChangedByUserId" VARCHAR,
    "ChangedByUserName" VARCHAR,
    "Table_Database" VARCHAR,
    "ActionName" VARCHAR,
    "Table_Name" VARCHAR,
    "PrimaryKey" VARCHAR,
    "ColumnValues" VARCHAR
) AS $$
BEGIN
    RETURN QUERY 
    SELECT 
        0 AS "AuditId",
        '1970-01-01 00:00:00'::timestamp AS "InsertedDate",
        ''::varchar AS "DbContext",
        ''::varchar AS "MachineUserName",
        ''::varchar AS "MachineName",
        ''::varchar AS "DomainName",
        ''::varchar AS "CallingMethodName",
        ''::varchar AS "ChangedByUserId",
        ''::varchar AS "ChangedByUserName",
        ''::varchar AS "Table_Database",
        ''::varchar AS "ActionName",
        dist.table_name::varchar AS "Table_Name",
        ''::varchar AS "PrimaryKey",
        ''::varchar AS "ColumnValues"
    FROM (
        SELECT DISTINCT table_name FROM "fn_danphe_audit"()
    ) dist;
END;
$$ LANGUAGE plpgsql;