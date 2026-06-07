CREATE OR REPLACE FUNCTION sp_mr_patientslistwithvisitid(
    p_searchtxt VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "PatientId" INT,
    "PatientVisitId" INT,
    "MedicalRecordId" INT,
    "PatientCode" VARCHAR,
    "ShortName" VARCHAR,
    "Age" VARCHAR,
    "Gender" VARCHAR,
    "PhoneNumber" TIMESTAMP,
    "DateOfBirth" TIMESTAMP,
    "Address" VARCHAR
) AS $$
BEGIN
    -- __comment_placeholder_0__ 
     
    
    RETURN QUERY SELECT 
      pat.patientid 
      ,mrs.patientvisitid
      ,mrs.medicalrecordid
      ,pat.patientcode
      ,pat.shortname
      ,pat.age
      ,pat.gender
      ,coalesce(pat.phonenumber, '') AS "PhoneNumber"
      ,pat.dateofbirth
      ,coalesce(pat.address, '') AS "Address"  
    from mr_recordsummary mrs
      inner join pat_patient pat on mrs.patientid = pat.patientid
      inner join adt_dischargetype distype on distype.dischargetypeid = mrs.dischargetypeid
    where pat.isactive = 1
    	and lower(distype.dischargetypename) ='death'
      and (pat.shortname like '%' || coalesce(p_searchtxt,'') || '%' or pat.patientcode like '%' || coalesce(p_searchtxt,'') || '%');
END;
$$ LANGUAGE plpgsql;