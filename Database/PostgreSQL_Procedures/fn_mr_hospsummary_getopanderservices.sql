DROP FUNCTION IF EXISTS public.fn_mr_hospsummary_getopanderservices(DATE, DATE) CASCADE;

CREATE OR REPLACE FUNCTION public.fn_mr_hospsummary_getopanderservices(
    p_fromdate DATE,
    p_todate DATE
)
RETURNS TABLE (
    "AgeRange" VARCHAR,
    "FemaleNew_Out" INT,
    "MaleNew_Out" INT,
    "FemaleTotal_Out" INT,
    "MaleTotal_Out" INT,
    "Female_ER" INT,
    "Male_ER" INT,
    "FemaleOld_Out" INT,
    "MaleOld_Out" INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_emgdepts_code_csv VARCHAR(200);
BEGIN
    SELECT "ParameterValue" INTO v_emgdepts_code_csv 
    FROM "CORE_CFG_Parameters" 
    WHERE "ParameterGroupName" = 'GovReports' AND "ParameterName" = 'HospSummary_EmergencyDeptsCodeCSV';

    RETURN QUERY
    WITH er_depts AS (
        SELECT "DepartmentId" 
        FROM "MST_Department" 
        WHERE UPPER("DepartmentCode") IN (
            SELECT UPPER(trim(x)) 
            FROM unnest(string_to_array(COALESCE(v_emgdepts_code_csv, ''), ',')) x
        )
    ),
    opd_depts AS (
        SELECT "DepartmentId" 
        FROM "MST_Department" 
        WHERE UPPER("DepartmentCode") NOT IN (
            SELECT UPPER(trim(x)) 
            FROM unnest(string_to_array(COALESCE(v_emgdepts_code_csv, ''), ',')) x
        )
    ),
    age_groups AS (
        SELECT '0-9 Years'::VARCHAR AS age_range, 1 AS seq UNION ALL
        SELECT '10-14 Years', 2 UNION ALL
        SELECT '15-19 Years', 3 UNION ALL
        SELECT '20-59 Years', 4 UNION ALL
        SELECT '60-69 Years', 5 UNION ALL
        SELECT '>=70 Years', 6
    ),
    opd_patients AS (
        SELECT 
            public.getdobagerange(pat."DateOfBirth", v."VisitDate") AS age_range,
            SUM(CASE WHEN pat."Gender" = 'Female' AND LOWER(v."AppointmentType") = 'new' THEN 1 ELSE 0 END)::INT AS new_female,
            SUM(CASE WHEN pat."Gender" = 'Male' AND LOWER(v."AppointmentType") = 'new' THEN 1 ELSE 0 END)::INT AS new_male,
            SUM(CASE WHEN pat."Gender" = 'Female' AND LOWER(v."AppointmentType") != 'new' THEN 1 ELSE 0 END)::INT AS old_female,
            SUM(CASE WHEN pat."Gender" = 'Male' AND LOWER(v."AppointmentType") != 'new' THEN 1 ELSE 0 END)::INT AS old_male
        FROM "PAT_PatientVisits" v
        INNER JOIN "PAT_Patient" pat ON v."PatientId" = pat."PatientId"
        INNER JOIN opd_depts dept ON v."DepartmentId" = dept."DepartmentId"
        WHERE v."VisitType" != 'inpatient'
          AND v."IsActive" = TRUE
          AND v."BillingStatus" != 'returned'
          AND v."VisitDate"::DATE BETWEEN p_fromdate AND p_todate
        GROUP BY public.getdobagerange(pat."DateOfBirth", v."VisitDate")
    ),
    er_patients AS (
        SELECT 
            public.getdobagerange(pat."DateOfBirth", v."VisitDate") AS age_range,
            SUM(CASE WHEN pat."Gender" = 'Female' THEN 1 ELSE 0 END)::INT AS er_female,
            SUM(CASE WHEN pat."Gender" = 'Male' THEN 1 ELSE 0 END)::INT AS er_male
        FROM "PAT_PatientVisits" v
        INNER JOIN "PAT_Patient" pat ON v."PatientId" = pat."PatientId"
        INNER JOIN er_depts dept ON v."DepartmentId" = dept."DepartmentId"
        WHERE v."VisitType" != 'inpatient'
          AND v."IsActive" = TRUE
          AND v."BillingStatus" != 'returned'
          AND v."VisitDate"::DATE BETWEEN p_fromdate AND p_todate
        GROUP BY public.getdobagerange(pat."DateOfBirth", v."VisitDate")
    )
    SELECT 
        ag.age_range::VARCHAR AS "AgeRange",
        COALESCE(op.new_female, 0)::INT AS "FemaleNew_Out",
        COALESCE(op.new_male, 0)::INT AS "MaleNew_Out",
        (COALESCE(op.new_female, 0) + COALESCE(op.old_female, 0))::INT AS "FemaleTotal_Out",
        (COALESCE(op.new_male, 0) + COALESCE(op.old_male, 0))::INT AS "MaleTotal_Out",
        COALESCE(er.er_female, 0)::INT AS "Female_ER",
        COALESCE(er.er_male, 0)::INT AS "Male_ER",
        COALESCE(op.old_female, 0)::INT AS "FemaleOld_Out",
        COALESCE(op.old_male, 0)::INT AS "MaleOld_Out"
    FROM age_groups ag
    LEFT JOIN opd_patients op ON ag.age_range = op.age_range
    LEFT JOIN er_patients er ON ag.age_range = er.age_range
    ORDER BY ag.seq;
END;
$$;
