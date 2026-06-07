/*
 FileName: [SP_MR_BirthList_FemalePatientsListWithVisitinformation] 
 Created: 6th May 2021/Bikash
 Description: To Get the Female Patients list with Visit information
 Remarks: 
 Change History
 S.No.    Date/User  						Remarks
 1.	     6thMay2021/Bikash					inital draft
 2.		 12th-May-2021/Bikash				show female patient from age group 12-49
 3.		 8th-Sept-2021/Bikash				Only admitted patient taken in considration for search
*/
CREATE OR REPLACE FUNCTION sp_mr_birthlist_femalepatientslistwithvisitinformation(
    p_searchtxt VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "PatientId" INT,
    "PatientCode" VARCHAR,
    "ShortName" VARCHAR,
    "Age" VARCHAR,
    "Gender" VARCHAR,
    "PhoneNumber" TIMESTAMP,
    "DateOfBirth" TIMESTAMP,
    "Address" VARCHAR
) AS $$
BEGIN
    	   
    	RETURN QUERY SELECT distinct
    		pat.patientid,
    		pat.patientcode,
    		pat.shortname,
    		pat.age,
    		pat.gender,
    		pat.phonenumber,
    		pat.dateofbirth,
    		pat.address
    	from pat_patient pat
    		inner join pat_patientvisits visit on visit.patientid = pat.patientid
    		inner join adt_patientadmission adm on adm.patientid = pat.patientid
    	where adm.admissionstatus in ('admitted','discharged') 
    		and coalesce(pat.isoutdoorpat,0) = 0 
    		and pat.isactive=1
    		and (floor(datediff(day, pat.dateofbirth, current_timestamp) / 365.25)>=12 
    		and floor(datediff(day, pat.dateofbirth, current_timestamp) / 365.25)<=49) 
    		and pat.gender = 'Female' 
    		and ((pat.shortname like '%' || coalesce(p_searchtxt,'') || '%' or pat.patientcode like '%' || coalesce(p_searchtxt,'') || '%'));
END;
$$ LANGUAGE plpgsql;