CREATE OR REPLACE FUNCTION sp_adt_getalladmittedpatients(
    p_admissionstatus text DEFAULT 'admitted',
    p_patientvisitid integer DEFAULT 0
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref refcursor := 'ref';
    v_admissionstatus text := COALESCE(p_admissionstatus, 'admitted');
    v_patientvisitid integer := COALESCE(p_patientvisitid, 0);
BEGIN
    OPEN ref FOR
    WITH LatestBedInfos AS (
        SELECT "PatientVisitId", MAX("PatientBedInfoId") as "LatestPatientBedInfoId"
        FROM "ADT_TXN_PatientBedInfo"
        GROUP BY "PatientVisitId"
    )
    SELECT 
        visit."VisitCode",
        visit."PatientVisitId",
        adm."PatientId",
        adm."PatientAdmissionId",
        adm."AdmissionDate" AS "AdmittedDate",
        adm."DischargeDate",
        adm."DischargedBy",
        pat."PatientCode",
        adm."AdmittingDoctorId",
        COALESCE(doc."FullName", '') as "AdmittingDoctorName",
        COALESCE(pat."Address", '') as "Address",
        adm."AdmissionStatus",
        adm."BillStatusOnDischarge",
        pat."ShortName" AS "NAME",
        pat."DateOfBirth",
        COALESCE(pat."PhoneNumber", '') as "PhoneNumber",
        pat."Gender",
        summary."IsSubmitted",
        COALESCE(summary."DischargeSummaryId", 0) AS "DischargeSummaryId",
        dep."DepartmentId",
        dep."DepartmentName" AS "Department",
        adm."CareOfPersonName" AS "GuardianName",
        adm."CareOfPersonRelation" AS "GuardianRelation",
        CASE
            WHEN adm."AdmissionCase" = 'Police Case' THEN 1
            ELSE 0
        END as "IsPoliceCase",
        CASE WHEN adm."IsInsurancePatient" IS NULL THEN 0 ELSE (CASE WHEN adm."IsInsurancePatient" = TRUE THEN 1 ELSE 0 END) END as "IsInsurancePatient",
        --Patient Bed Infos--
        PBI."BedId",
        PBI."PatientBedInfoId",
        PBI."WardId",
        PBI."BedFeatureId",
        PBI."StartedOn",
        PBI."BedOnHoldEnabled",
        PBI."ReceivedBy",
        WD."WardName" AS "Ward",
        B."BedFeatureName" AS "BedFeature",
        BED."BedCode",
        BED."BedNumber",
        UPPER(LEFT(PBI."Action", 1)) || LOWER(SUBSTRING(PBI."Action", 2, LENGTH(PBI."Action"))) AS "Action"
    FROM
        "ADT_PatientAdmission" adm
        INNER JOIN "PAT_PatientVisits" visit ON adm."PatientVisitId" = visit."PatientVisitId"
        INNER JOIN "PAT_Patient" pat ON pat."PatientId" = adm."PatientId"
        INNER JOIN "MST_Department" dep ON visit."DepartmentId" = dep."DepartmentId"
        INNER JOIN LatestBedInfos LBI ON visit."PatientVisitId" = LBI."PatientVisitId"
        INNER JOIN "ADT_TXN_PatientBedInfo" PBI ON LBI."LatestPatientBedInfoId" = PBI."PatientBedInfoId" AND visit."PatientVisitId" = PBI."PatientVisitId"
        INNER JOIN "ADT_Bed" BED ON PBI."BedId" = BED."BedID"
        INNER JOIN "ADT_MST_Ward" WD ON PBI."WardId" = WD."WardID"
        INNER JOIN "ADT_MST_BedFeature" B ON B."BedFeatureId" = PBI."BedFeatureId"
        LEFT JOIN "ADT_DischargeSummary" summary ON adm."PatientVisitId" = summary."PatientVisitId"
        LEFT JOIN "EMP_Employee" doc ON adm."AdmittingDoctorId" = doc."EmployeeId"
    WHERE 
        LOWER(adm."AdmissionStatus") = LOWER(v_admissionstatus) AND
        (v_patientvisitid = 0 OR adm."PatientVisitId" = v_patientvisitid)
    ORDER BY adm."AdmissionDate" DESC;

    RETURN NEXT ref;
END;
$$ LANGUAGE plpgsql;
