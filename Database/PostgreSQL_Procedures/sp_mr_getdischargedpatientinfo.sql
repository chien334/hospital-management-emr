DROP FUNCTION IF EXISTS sp_mr_getdischargedpatientinfo(DATE, DATE) CASCADE;
DROP FUNCTION IF EXISTS sp_mr_getdischargedpatientinfo(VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS sp_mr_getdischargedpatientinfo(TEXT, TEXT) CASCADE;

CREATE OR REPLACE FUNCTION sp_mr_getdischargedpatientinfo(
    p_fromdate VARCHAR DEFAULT NULL,
    p_todate VARCHAR DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref refcursor := 'ref';
BEGIN
    -- Create a Temp table to store Latest PatientBedInfoId of each PatientVisitId (i.e: AdmittedVisits)
    DROP TABLE IF EXISTS temp_MR_PatientLatestBedInfo;
    CREATE TEMP TABLE temp_MR_PatientLatestBedInfo AS 
    SELECT 
        "PatientVisitId", 
        MAX("PatientBedInfoId") AS "LatestPatientBedInfoId"
    FROM 
        "ADT_TXN_PatientBedInfo"
    GROUP BY "PatientVisitId";

    OPEN ref FOR
    SELECT 
        vis."VisitCode",
        vis."PatientVisitId",
        vis."PatientId",
        adm."PatientAdmissionId",
        adm."AdmissionDate" AS "AdmittedDate",
        adm."DischargeDate" AS "DischargedDate",
        adm."DischargedBy" AS "DischargedBy", 
        pat."PatientCode",
        adm."AdmittingDoctorId",
        admDocEmp."FullName" AS "AdmittingDoctorName",
        pat."Address",
        adm."AdmissionStatus",
        adm."BillStatusOnDischarge",
        pat."ShortName" AS "Name",
        pat."DateOfBirth",
        pat."PhoneNumber",
        pat."Gender",
        dischSumm."IsSubmitted" AS "IsSubmitted",
        adm."IsPoliceCase",
        COALESCE(dischSumm."DischargeSummaryId", 0) AS "DischargeSummaryId",
        adm."IsInsurancePatient",
        mr."MedicalRecordId" AS "MedicalRecordId",
        dept."DepartmentName" AS "Department",
        adm."CareOfPersonName" AS "GuardianName",
        adm."CareOfPersonRelation" AS "GuardianRelation",
        0 AS "IsSelected",  -- Hardcoded False since it's used only in client side
        bedinfo."BedId" AS "BedId",
        bedinfo."PatientBedInfoId" AS "PatientBedInfoId",
        bedinfo."WardId" AS "WardId",
        ward."WardName" AS "Ward",
        bedinfo."BedFeatureId" AS "BedFeatureId",
        bedinfo."Action" AS "Action",
        bedinfo."StartedOn" AS "StartedOn",
        bf."BedFeatureName" AS "BedFeature",
        bed."BedCode" AS "BedCode",
        bed."BedNumber" AS "BedNumber",
        diagnosis."ICDCode"
    FROM 
        "ADT_PatientAdmission" adm 
        INNER JOIN "PAT_PatientVisits" vis ON adm."PatientVisitId" = vis."PatientVisitId"
        INNER JOIN "PAT_Patient" pat ON adm."PatientId" = pat."PatientId"
        INNER JOIN temp_MR_PatientLatestBedInfo lastbedinfo ON vis."PatientVisitId" = lastbedinfo."PatientVisitId"
        INNER JOIN "ADT_TXN_PatientBedInfo" bedinfo ON lastbedinfo."LatestPatientBedInfoId" = bedinfo."PatientBedInfoId" AND vis."PatientVisitId" = bedinfo."PatientVisitId"
        INNER JOIN "ADT_MST_Ward" ward ON bedinfo."WardId" = ward."WardID"
        INNER JOIN "ADT_Bed" bed ON bedinfo."BedId" = bed."BedID"
        INNER JOIN "ADT_MST_BedFeature" bf ON bedinfo."BedFeatureId" = bf."BedFeatureId"
        LEFT JOIN "EMP_Employee" admDocEmp ON adm."AdmittingDoctorId" = admDocEmp."EmployeeId"
        LEFT JOIN "ADT_DischargeSummary" dischSumm ON dischSumm."PatientVisitId" = adm."PatientVisitId"
        LEFT JOIN "MR_RecordSummary" mr ON adm."PatientVisitId" = mr."PatientVisitId"
        LEFT JOIN "MST_Department" dept ON vis."DepartmentId" = dept."DepartmentId"
        LEFT JOIN (
            SELECT 
                string_agg(icd."ICD10Code", ', ') AS "ICDCode", 
                diag."PatientVisitId" 
            FROM "MR_TXN_Inpatient_Diagnosis" diag 
            INNER JOIN "MST_ICD10" icd ON diag."ICD10ID" = icd."ICD10ID" 
            GROUP BY diag."PatientVisitId"
        ) AS diagnosis ON adm."PatientVisitId" = diagnosis."PatientVisitId"
    WHERE 
        LOWER(adm."AdmissionStatus") = 'discharged'
        AND (adm."DischargeDate")::date BETWEEN (p_fromdate)::date AND (p_todate)::date
    ORDER BY adm."DischargeDate" DESC;

    RETURN NEXT ref;
END;
$$ LANGUAGE plpgsql;