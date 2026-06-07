DROP FUNCTION IF EXISTS sp_report_hdsk_employeeinfo();

CREATE OR REPLACE FUNCTION sp_report_hdsk_employeeinfo()
RETURNS TABLE (
    "EmployeeName" VARCHAR,
    "Designation" VARCHAR,
    "DepartmentName" VARCHAR,
    "ContactNumber" VARCHAR,
    "Extension" SMALLINT,
    "SpeedDial" SMALLINT,
    "OfficeHour" VARCHAR,
    "RoomNumber" VARCHAR
) AS $$
BEGIN
    RETURN QUERY 
    SELECT 
        CAST(COALESCE(emp."Salutation", '') || ' ' || emp."FirstName" || COALESCE(' ' || emp."MiddleName", '') || ' ' || emp."LastName" AS VARCHAR) AS "EmployeeName",
        CAST(emrl."EmployeeRoleName" AS VARCHAR) AS "Designation", 
        CAST(dep."DepartmentName" AS VARCHAR) AS "DepartmentName",
        CAST(emp."ContactNumber" AS VARCHAR) AS "ContactNumber", 
        emp."Extension", 
        emp."SpeedDial", 
        CAST(COALESCE(emp."OfficeHour", '0') AS VARCHAR) AS "OfficeHour", 
        CAST(emp."RoomNo" AS VARCHAR) AS "RoomNumber"
    FROM "EMP_Employee" emp
    LEFT JOIN "EMP_EmployeeRole" emrl ON emrl."EmployeeRoleId" = emp."EmployeeRoleId" 
    INNER JOIN "MST_Department" dep ON dep."DepartmentId" = emp."DepartmentId";
END;
$$ LANGUAGE plpgsql;