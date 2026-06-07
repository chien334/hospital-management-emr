CREATE OR REPLACE FUNCTION sp_adt_getalladmittedpatients(
    p_admissionstatus VARCHAR DEFAULT 'admitted',
    p_patientvisitid INT DEFAULT NULL
)
RETURNS TABLE (
    "VisitCode" VARCHAR,
    "PatientVisitId" INT,
    "PatientId" INT,
    "PatientAdmissionId" INT,
    "AdmittedDate" TIMESTAMP,
    "DischargeDate" TIMESTAMP,
    "DischargedBy" VARCHAR,
    "PatientCode" VARCHAR,
    "AdmittingDoctorId" INT,
    "AdmittingDoctorName" VARCHAR,
    "Address" VARCHAR,
    "AdmissionStatus" TIMESTAMP,
    "BillStatusOnDischarge" TIMESTAMP,
    "NAME" VARCHAR,
    "DateOfBirth" TIMESTAMP,
    "PhoneNumber" TIMESTAMP,
    "Gender" VARCHAR,
    "IsSubmitted" BOOLEAN,
    "DischargeSummaryId" INT,
    "DepartmentId" INT,
    "Department" VARCHAR,
    "GuardianName" VARCHAR,
    "GuardianRelation" TIMESTAMP,
    "IsPoliceCase" BOOLEAN,
    "IsInsurancePatient" BOOLEAN,
    "BedId" INT,
    "PatientBedInfoId" INT,
    "WardId" INT,
    "BedFeatureId" INT,
    "StartedOn" TIMESTAMP,
    "BedOnHoldEnabled" TIMESTAMP,
    "ReceivedBy" VARCHAR,
    "Ward" VARCHAR,
    "BedFeature" VARCHAR,
    "BedCode" VARCHAR,
    "BedNumber" VARCHAR,
    "Action" TIMESTAMP
) AS $$
BEGIN
    /*
    sp name:	sp_adt_getalladmittedpatients
    author:		krishna bogati/sanjit raj shakya
    createdon:	2021-12-22
    remarks:	created sp to replace linq query from api in admission controller
    exec example: exec sp_adt_getalladmittedpatients @p_admissionstatus = 'admitted', p_patientvisitid = 0
    change/history:
    1. krishna 13th,jan'22				AdmissionDate changed to AdmittedDate(EMR:4762)
    
    */
    BEGIN
        -- body of the stored procedure
        DROP TABLE IF EXISTS temp_latestBedInfos;CREATE TEMP TABLE temp_latestBedInfos AS SELECT 
    		PBI.PatientVisitId, 
    		MAX(PBI.PatientBedInfoId) as LatestPatientBedInfoId
    	
    	FROM 
    		ADT_TXN_PatientBedInfo PBI
    	GROUP BY PBI.PatientVisitId;
    
    	RETURN QUERY SELECT 
    		visit.VisitCode,
    		visit.PatientVisitId,
    		adm.PatientId,
    		adm.PatientAdmissionId,
    		adm.AdmissionDate AS "AdmittedDate",
    		adm.DischargeDate,
    		adm.DischargedBy,
    		pat.PatientCode,
    		adm.AdmittingDoctorId,
    		COALESCE(doc.FullName, '') AS "AdmittingDoctorName",
    		COALESCE(pat.Address,'') AS "Address",
    		adm.AdmissionStatus,
    		adm.BillStatusOnDischarge,
    		pat.ShortName AS "NAME",
    		pat.DateOfBirth,
    		COALESCE(pat.PhoneNumber,'') AS "PhoneNumber",
    		pat.Gender,
    		summary.IsSubmitted,
    		COALESCE(summary.DischargeSummaryId, 0) AS "DischargeSummaryId",
    		dep.DepartmentId,
    		dep.DepartmentName AS "Department",
    		adm.CareOfPersonName AS "GuardianName",
    		adm.CareOfPersonRelation AS "GuardianRelation",
    		CASE
    			WHEN adm.AdmissionCase = 'police case' then 1
    			else 0
    		end AS "IsPoliceCase",
    		case when adm.isinsurancepatient is null then 0 else adm.isinsurancepatient end AS "IsInsurancePatient",
    		--patient bed infos--
    		pbi.bedid,
    		pbi.patientbedinfoid,
    		pbi.wardid,
    		pbi.bedfeatureid,
    		pbi.startedon,
    		pbi.bedonholdenabled,
    		pbi.receivedby,
    		wd.wardname AS "Ward",
    		b.bedfeaturename AS "BedFeature",
    		bed.bedcode,
    		bed.bednumber,
    		upper(left(pbi.action,1))+lower(substring(pbi.action,2,len(pbi.action))) AS "Action"
    
    	from
    		adt_patientadmission adm
    		inner join pat_patientvisits visit on adm.patientvisitid = visit.patientvisitid
    		inner join pat_patient pat on pat.patientid = adm.patientid
    		inner join mst_department dep on visit.departmentid = dep.departmentid
    		inner join temp_latestbedinfos lbi on visit.patientvisitid = lbi.patientvisitid
    		inner join adt_txn_patientbedinfo pbi on lbi.latestpatientbedinfoid = pbi.patientbedinfoid and visit.patientvisitid = pbi.patientvisitid
    		inner join adt_bed bed on pbi.bedid = bed.bedid
    		inner join adt_mst_ward wd on pbi.wardid = wd.wardid
    		inner join adt_mst_bedfeature b on b.bedfeatureid = pbi.bedfeatureid
    		left join adt_dischargesummary summary on adm.patientvisitid = summary.patientvisitid
    		left join emp_employee doc on adm.admittingdoctorid = doc.employeeid
    	where 
    		lower(adm.admissionstatus) = lower(p_admissionstatus) and
    		(p_patientvisitid = 0 or adm.patientvisitid = p_patientvisitid)
    	order by adm.admissiondate desc;
    end;
END;
$$ LANGUAGE plpgsql;