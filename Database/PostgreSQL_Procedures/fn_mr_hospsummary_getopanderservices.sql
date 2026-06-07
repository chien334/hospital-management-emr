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
    SELECT parametervalue INTO v_emgdepts_code_csv 
    FROM core_cfg_parameters 
    WHERE parametergroupname = 'GovReports' AND parametername = 'HospSummary_EmergencyDeptsCodeCSV';

    RETURN QUERY
    WITH er_depts AS (
        SELECT departmentid 
        FROM mst_department 
        WHERE UPPER(departmentcode) IN (
            SELECT UPPER(trim(x)) 
            FROM unnest(string_to_array(COALESCE(v_emgdepts_code_csv, ''), ',')) x
        )
    ),
    opd_depts AS (
        SELECT departmentid 
        FROM mst_department 
        WHERE UPPER(departmentcode) NOT IN (
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
            public.getdobagerange(pat.dateofbirth, v.visitdate) AS age_range,
            SUM(CASE WHEN pat.gender = 'Female' AND LOWER(v.appointmenttype) = 'new' THEN 1 ELSE 0 END) AS new_female,
            SUM(CASE WHEN pat.gender = 'Male' AND LOWER(v.appointmenttype) = 'new' THEN 1 ELSE 0 END) AS new_male,
            SUM(CASE WHEN pat.gender = 'Female' AND LOWER(v.appointmenttype) != 'new' THEN 1 ELSE 0 END) AS old_female,
            SUM(CASE WHEN pat.gender = 'Male' AND LOWER(v.appointmenttype) != 'new' THEN 1 ELSE 0 END) AS old_male
        FROM pat_patientvisits v
        INNER JOIN pat_patient pat ON v.patientid = pat.patientid
        INNER JOIN opd_depts dept ON v.departmentid = dept.departmentid
        WHERE v.visittype != 'inpatient'
          AND v.isactive = TRUE
          AND v.billingstatus != 'returned'
          AND v.visitdate::DATE BETWEEN p_fromdate AND p_todate
        GROUP BY public.getdobagerange(pat.dateofbirth, v.visitdate)
    ),
    er_patients AS (
        SELECT 
            public.getdobagerange(pat.dateofbirth, v.visitdate) AS age_range,
            SUM(CASE WHEN pat.gender = 'Female' THEN 1 ELSE 0 END) AS er_female,
            SUM(CASE WHEN pat.gender = 'Male' THEN 1 ELSE 0 END) AS er_male
        FROM pat_patientvisits v
        INNER JOIN pat_patient pat ON v.patientid = pat.patientid
        INNER JOIN er_depts dept ON v.departmentid = dept.departmentid
        WHERE v.visittype != 'inpatient'
          AND v.isactive = TRUE
          AND v.billingstatus != 'returned'
          AND v.visitdate::DATE BETWEEN p_fromdate AND p_todate
        GROUP BY public.getdobagerange(pat.dateofbirth, v.visitdate)
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
