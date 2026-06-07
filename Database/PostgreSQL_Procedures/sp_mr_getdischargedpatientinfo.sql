CREATE OR REPLACE FUNCTION sp_mr_getdischargedpatientinfo(
    p_fromdate DATE,
    p_todate DATE
)
RETURNS TABLE (
    "VisitCode" VARCHAR,
    "PatientVisitId" INT,
    "PatientId" INT,
    "PatientAdmissionId" INT,
    "AdmittedDate" TIMESTAMP,
    "DischargedDate" TIMESTAMP,
    "DischargedBy" VARCHAR,
    "PatientCode" VARCHAR,
    "AdmittingDoctorId" INT,
    "AdmittingDoctorName" VARCHAR,
    "Address" VARCHAR,
    "AdmissionStatus" TIMESTAMP,
    "BillStatusOnDischarge" TIMESTAMP,
    "Name" VARCHAR,
    "DateOfBirth" TIMESTAMP,
    "PhoneNumber" TIMESTAMP,
    "Gender" VARCHAR,
    "IsSubmitted" BOOLEAN,
    "IsPoliceCase" BOOLEAN,
    "DischargeSummaryId" INT,
    "IsInsurancePatient" BOOLEAN,
    "MedicalRecordId" INT,
    "Department" VARCHAR,
    "GuardianName" VARCHAR,
    "GuardianRelation" TIMESTAMP,
    "IsSelected" BOOLEAN,
    "BedId" INT,
    "PatientBedInfoId" INT,
    "WardId" INT,
    "Ward" VARCHAR,
    "BedFeatureId" INT,
    "Action" TIMESTAMP,
    "StartedOn" TIMESTAMP,
    "BedFeature" VARCHAR,
    "BedCode" VARCHAR,
    "BedNumber" VARCHAR,
    "ICDCode" VARCHAR
) AS $$
BEGIN
    /*
    sp name:sp_mr_getdischargedpatientinfo
    created: sud/01feb'23
    Description: Get dischargedpatient information for Medical Record
    Remarks:	
    Exec Example: EXEC SP_MR_GetDischargedPatientInfo '2022-01-01','2022-01-31'
    CHANGE HISTORY:
    1. Sud/01Feb'23			created
    2. nirmala/25sep'23     Fetch ICDCode
    
    */
    
    --Create a Temp table to store Latest PatientBedInfoId of each PatientVisitId (i.e: AdmittedVisits)--
    DROP TABLE IF EXISTS temp_MR_PatientLatestBedInfo;CREATE TEMP TABLE temp_MR_PatientLatestBedInfo AS SELECT 
    	PatientVisitId, 
    	MAX(PatientBedInfoId) as LatestPatientBedInfoId
    
    FROM 
    	ADT_TXN_PatientBedInfo 
    GROUP BY PatientVisitId;
    RETURN QUERY SELECT 
    	vis.VisitCode,
    	vis.PatientVisitId,
    	vis.PatientId,
    	adm.PatientAdmissionId,
    	adm.AdmissionDate AS "AdmittedDate",
    	adm.DischargeDate AS "DischargedDate",
    	adm.DischargedBy AS "DischargedBy", --Taking ID since it is taking ID in the LINQ
    	pat.PatientCode,
    	adm.AdmittingDoctorId,
    	admDocEmp.FullName AS "AdmittingDoctorName",
    	pat.Address,
    	adm.AdmissionStatus,
    	adm.BillStatusOnDischarge,
    	pat.ShortName AS "Name",
    	pat.DateOfBirth,
    	pat.PhoneNumber,
    	pat.Gender,
    	dischSumm.IsSubmitted AS "IsSubmitted",
    	adm.IsPoliceCase,
    	COALESCE(dischSumm.DischargeSummaryId,0) AS "DischargeSummaryId",
    	adm.IsInsurancePatient,
    	mr.MedicalRecordId AS "MedicalRecordId",
    	dept.DepartmentName AS "Department",
    	adm.CareOfPersonName AS "GuardianName",
    	adm.CareOfPersonRelation AS "GuardianRelation",
    	0 AS "IsSelected",  --Hardcoded False since it's used only in client side	
    	bedinfo.bedid,
        bedinfo.patientbedinfoid,
        bedinfo.wardid,
    	ward.wardname AS "Ward",
    	bedinfo.bedfeatureid,
    	bedinfo.action,
        bedinfo.startedon,
    	bf.bedfeaturename AS "BedFeature",
    	bed.bedcode,
    	bed.bednumber,
    	diagnosis.icdcode
    from 
    adt_patientadmission adm 
    	inner join pat_patientvisits vis  on adm.patientvisitid=vis.patientvisitid
    	inner join pat_patient pat   on adm.patientid=pat.patientid
    	inner join temp_mr_patientlatestbedinfo  lastbedinfo  on vis.patientvisitid = lastbedinfo.patientvisitid
    	inner join adt_txn_patientbedinfo bedinfo  on lastbedinfo.latestpatientbedinfoid = bedinfo.patientbedinfoid and vis.patientvisitid = bedinfo.patientvisitid
    	inner join adt_mst_ward ward on bedinfo.wardid = ward.wardid
    	inner join adt_bed bed on bedinfo.bedid=bed.bedid
    	inner join adt_mst_bedfeature bf on bedinfo.bedfeatureid=bf.bedfeatureid
    	left join emp_employee admdocemp on adm.admittingdoctorid=admdocemp.employeeid
    	left join adt_dischargesummary dischsumm on dischsumm.patientvisitid = adm.patientvisitid
    	left join mr_recordsummary mr  on adm.patientvisitid=mr.patientvisitid
    	left join mst_department dept on vis.departmentid=dept.departmentid
    	left join (select string_agg(icd.icd10code, ', ') AS "ICDCode",diag.patientvisitid from mr_txn_inpatient_diagnosis 
        diag inner join mst_icd10 icd on diag.icd10id = icd.icd10id group by diag.patientvisitid) as diagnosis
    	on adm.patientvisitid = diagnosis.patientvisitid
    where 
    adm.admissionstatus='discharged'
      and (adm.dischargedate)::date between p_fromdate and p_todate
    order by adm.dischargedate desc;
END;
$$ LANGUAGE plpgsql;