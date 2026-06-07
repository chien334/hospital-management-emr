-- 4-parameter version
DROP FUNCTION IF EXISTS sp_danphe_audit(timestamp, timestamp, varchar, varchar) CASCADE;
CREATE OR REPLACE FUNCTION public.sp_danphe_audit(
    p_fromdate timestamp without time zone DEFAULT NULL::timestamp without time zone, 
    p_todate timestamp without time zone DEFAULT NULL::timestamp without time zone, 
    p_table_name character varying DEFAULT NULL::character varying, 
    p_username character varying DEFAULT NULL::character varying
)
 RETURNS TABLE(
    "AuditId" integer, 
    "InsertedDate" timestamp without time zone, 
    "DbContext" character varying, 
    "MachineUserName" character varying, 
    "MachineName" character varying, 
    "DomainName" character varying, 
    "CallingMethodName" character varying, 
    "ChangedByUserId" character varying, 
    "ChangedByUserName" character varying, 
    "Table_Database" character varying, 
    "ActionName" character varying, 
    "Table_Name" character varying, 
    "PrimaryKey" character varying, 
    "ColumnValues" character varying
)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY 
    SELECT 
        tbl1.auditid AS "AuditId",
        tbl1.inserteddate AS "InsertedDate",
        tbl1.dbcontext::varchar AS "DbContext",
        tbl1.machineusername::varchar AS "MachineUserName",
        tbl1.machinename::varchar AS "MachineName",
        tbl1.domainname::varchar AS "DomainName",
        tbl1.callingmethodname::varchar AS "CallingMethodName",
        tbl1.changedbyuserid::varchar AS "ChangedByUserId",
        tbl1.changedbyusername::varchar AS "ChangedByUserName",
        tbl1.table_database::varchar AS "Table_Database",
        tbl1.actionname::varchar AS "ActionName",
        tbl1.table_name::varchar AS "Table_Name",
        tbl1.primarykey::varchar AS "PrimaryKey",
        tbl1.columnvalues::varchar AS "ColumnValues"
    FROM fn_danphe_audit() tbl1
    INNER JOIN "RBAC_User" tbl2 ON LOWER(tbl1.changedbyusername) = LOWER(tbl2."UserName")
    WHERE (tbl1.inserteddate::date BETWEEN p_fromdate::date AND p_todate::date)
      AND (p_table_name IS NULL OR p_table_name = '' OR tbl1.table_name = p_table_name)
      AND (p_username IS NULL OR p_username = '' OR tbl2."UserName" = p_username);
END;
$function$;

-- 5-parameter version matching C# parameter order
DROP FUNCTION IF EXISTS sp_danphe_audit(timestamp, timestamp, varchar, varchar, varchar) CASCADE;
CREATE OR REPLACE FUNCTION public.sp_danphe_audit(
    p_fromdate timestamp without time zone, 
    p_todate timestamp without time zone, 
    p_username character varying,
    p_table_name character varying, 
    p_action character varying
)
 RETURNS TABLE(
    "AuditId" integer, 
    "InsertedDate" timestamp without time zone, 
    "DbContext" character varying, 
    "MachineUserName" character varying, 
    "MachineName" character varying, 
    "DomainName" character varying, 
    "CallingMethodName" character varying, 
    "ChangedByUserId" character varying, 
    "ChangedByUserName" character varying, 
    "Table_Database" character varying, 
    "ActionName" character varying, 
    "Table_Name" character varying, 
    "PrimaryKey" character varying, 
    "ColumnValues" character varying
)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY 
    SELECT 
        tbl1.auditid AS "AuditId",
        tbl1.inserteddate AS "InsertedDate",
        tbl1.dbcontext::varchar AS "DbContext",
        tbl1.machineusername::varchar AS "MachineUserName",
        tbl1.machinename::varchar AS "MachineName",
        tbl1.domainname::varchar AS "DomainName",
        tbl1.callingmethodname::varchar AS "CallingMethodName",
        tbl1.changedbyuserid::varchar AS "ChangedByUserId",
        tbl1.changedbyusername::varchar AS "ChangedByUserName",
        tbl1.table_database::varchar AS "Table_Database",
        tbl1.actionname::varchar AS "ActionName",
        tbl1.table_name::varchar AS "Table_Name",
        tbl1.primarykey::varchar AS "PrimaryKey",
        tbl1.columnvalues::varchar AS "ColumnValues"
    FROM fn_danphe_audit() tbl1
    INNER JOIN "RBAC_User" tbl2 ON LOWER(tbl1.changedbyusername) = LOWER(tbl2."UserName")
    WHERE (tbl1.inserteddate::date BETWEEN p_fromdate::date AND p_todate::date)
      AND (p_table_name IS NULL OR p_table_name = '' OR tbl1.table_name = p_table_name)
      AND (p_username IS NULL OR p_username = '' OR tbl2."UserName" = p_username)
      AND (p_action IS NULL OR p_action = '' OR tbl1.actionname = p_action);
END;
$function$;