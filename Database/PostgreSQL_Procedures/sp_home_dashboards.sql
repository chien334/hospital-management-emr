-- 1. SP_DSB_Home_DashboardStatistics
CREATE OR REPLACE FUNCTION sp_dsb_home_dashboardstatistics()
RETURNS TABLE (
    "TotalPatient" BIGINT,
    "TodayPatient" BIGINT,
    "YestardayPatient" BIGINT,
    "ConsultantsCount" BIGINT,
    "MedicalOfficersCount" BIGINT,
    "AnaesthetistsCount" BIGINT,
    "TotalDoctorsCount" BIGINT,
    "TotalAppts" BIGINT,
    "NewAppts" BIGINT,
    "ReferralAppts" BIGINT,
    "FollowUpAppts" BIGINT,
    "CancelAppts" BIGINT,
    "ReturnAppts" BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pat.count AS "TotalPatient",
        today_pat.count AS "TodayPatient",
        yestarday_pat.count AS "YestardayPatient",
        COALESCE(docs.ConsultantsCount, 0)::BIGINT AS "ConsultantsCount",
        COALESCE(docs.MedicalOfficersCount, 0)::BIGINT AS "MedicalOfficersCount",
        COALESCE(docs.AnaesthetistsCount, 0)::BIGINT AS "AnaesthetistsCount",
        COALESCE(docs.TotalDoctorsCount, 0)::BIGINT AS "TotalDoctorsCount",
        COALESCE(appt.TotalAppts, 0)::BIGINT AS "TotalAppts",
        COALESCE(appt.NewAppts, 0)::BIGINT AS "NewAppts",
        COALESCE(appt.ReferralAppts, 0)::BIGINT AS "ReferralAppts",
        COALESCE(appt.FollowUpAppts, 0)::BIGINT AS "FollowUpAppts",
        COALESCE(appt.CancelAppts, 0)::BIGINT AS "CancelAppts",
        COALESCE(retAppts.ReturnAppts, 0)::BIGINT AS "ReturnAppts"
    FROM 
        (SELECT COUNT(*) AS count FROM "PAT_Patient") pat,
        (SELECT COUNT(*) AS count FROM "PAT_Patient" WHERE "CreatedOn"::DATE = CURRENT_DATE) today_pat,
        (SELECT COUNT(*) AS count FROM "PAT_Patient" WHERE "CreatedOn"::DATE = (CURRENT_DATE - INTERVAL '1 day')::DATE) yestarday_pat,
        (
            SELECT  
                SUM(CASE WHEN "EmployeeRoleName" = 'Doctor' THEN 1 ELSE 0 END) AS ConsultantsCount,
                SUM(CASE WHEN "EmployeeRoleName" = 'M.O.' THEN 1 ELSE 0 END) AS MedicalOfficersCount,
                SUM(CASE WHEN "EmployeeRoleName" = 'Anaesthetist' THEN 1 ELSE 0 END) AS AnaesthetistsCount,
                SUM(CASE WHEN "EmployeeRoleName" IN ('Doctor', 'M.O.', 'Anaesthetist') THEN 1 ELSE 0 END) AS TotalDoctorsCount
            FROM "EMP_Employee" emp
            LEFT JOIN "EMP_EmployeeRole" eRole ON emp."EmployeeRoleId" = eRole."EmployeeRoleId"
        ) docs,
        (
            SELECT 
                SUM(1) AS TotalAppts,
                SUM(CASE WHEN ("AppointmentType" = 'New' OR "AppointmentType" = 'Transfer') THEN 1 ELSE 0 END) AS NewAppts,
                SUM(CASE WHEN "AppointmentType" = 'Referral' THEN 1 ELSE 0 END) AS ReferralAppts,
                SUM(CASE WHEN "AppointmentType" = 'Followup' THEN 1 ELSE 0 END) AS FollowUpAppts,
                SUM(CASE WHEN "AppointmentType" = 'New' AND "BillingStatus" = 'cancel' THEN 1 ELSE 0 END) AS CancelAppts
            FROM "PAT_PatientVisits" 
            WHERE "VisitType" = 'outpatient' AND "VisitDate"::DATE = CURRENT_DATE AND "BillingStatus" != 'returned'
        ) appt,
        (
            SELECT COUNT(*) AS ReturnAppts
            FROM "PAT_PatientVisits" 
            WHERE "VisitType" = 'outpatient' AND "VisitDate"::DATE = CURRENT_DATE AND "BillingStatus" = 'returned'
        ) retAppts;
END;
$$ LANGUAGE plpgsql;

-- 2. SP_DSB_Home_PatientDistributionMap_Nepal
CREATE OR REPLACE FUNCTION sp_dsb_home_patientdistributionmap_nepal()
RETURNS TABLE (
    "MapAreaCode" VARCHAR,
    "PatientCount" BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        A."MapAreaCode"::VARCHAR, 
        COALESCE(B.PatientCount, 0)::BIGINT AS "PatientCount"
    FROM 
    (
        SELECT DISTINCT csd."MapAreaCode" 
        FROM "MST_CountrySubDivision" csd
        WHERE csd."CountryId" = (SELECT "CountryId" FROM "MST_Country" WHERE "CountryName" = 'Nepal') 
          AND csd."MapAreaCode" IS NOT NULL
    ) A
    LEFT JOIN 
    (
        SELECT csd."MapAreaCode", COUNT(pat."PatientId") AS PatientCount 
        FROM "MST_CountrySubDivision" csd
        JOIN "PAT_Patient" pat ON pat."CountrySubDivisionId" = csd."CountrySubDivisionId"
        WHERE pat."CountryId" = (SELECT "CountryId" FROM "MST_Country" WHERE "CountryName" = 'Nepal')
        GROUP BY csd."MapAreaCode"
    ) B
    ON A."MapAreaCode" = B."MapAreaCode";
END;
$$ LANGUAGE plpgsql;

-- 3. SP_DSB_Home_DeptWiseAppointmentCount
CREATE OR REPLACE FUNCTION sp_dsb_home_deptwiseappointmentcount(
    todaysdate TIMESTAMP
)
RETURNS TABLE (
    "DepartmentName" VARCHAR,
    "AppointmentCount" BIGINT
) AS $$
BEGIN
    IF (todaysdate IS NOT NULL) THEN
        RETURN QUERY
        SELECT 
            ms."DepartmentName"::VARCHAR, 
            COUNT(*)::BIGINT AS "AppointmentCount"
        FROM "PAT_PatientVisits" vis
        JOIN "MST_Department" ms ON ms."DepartmentId" = vis."DepartmentId"
        WHERE vis."BillingStatus" != 'returned'
          AND vis."VisitDate"::DATE = todaysdate::DATE 
          AND vis."VisitType" != 'inpatient'
        GROUP BY ms."DepartmentName";
    END IF;
END;
$$ LANGUAGE plpgsql;
