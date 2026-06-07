CREATE OR REPLACE FUNCTION sp_vaccination_baby_patientlist(
    p_searchtxt VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "PatientId" INT,
    "PatientCode" VARCHAR,
    "Age" VARCHAR,
    "ShortName" VARCHAR,
    "DateOfBirth" TIMESTAMP,
    "Gender" VARCHAR,
    "PhoneNumber" TIMESTAMP,
    "Address" VARCHAR,
    "VaccinationRegNo" TIMESTAMP,
    "EthnicGroup" VARCHAR,
    "FatherName" VARCHAR,
    "MotherName" VARCHAR,
    "CountryId" INT,
    "CountrySubDivisionId" INT
) AS $$
DECLARE
    v_twoyearsback DATE;
BEGIN
    
    
    
    v_twoyearsback := (dateadd(year, -2, current_timestamp))::date; 
    	RETURN QUERY SELECT 
    	pat.patientid,
    	pat.patientcode,
    	pat.age,
    	pat.shortname,
    	pat.dateofbirth,
    	pat.gender,
    	pat.phonenumber,
    	pat.address,
    	pat.vaccinationregno,
    	pat.ethnicgroup,
    	pat.fathername,
    	pat.mothername,
    	pat.countryid,
    	pat.countrysubdivisionid
    from pat_patient pat 
    where (coalesce(pat.isvaccinationactive, 0) = 0)  and pat.dateofbirth is not null and (coalesce(pat.isvaccinationpatient, 0) = 0) 
    and ((pat.dateofbirth)::date > v_twoyearsback) and (pat.shortname like '%' || coalesce(p_searchtxt,'') || '%' or pat.patientcode like '%' || coalesce(p_searchtxt,'') || '%');
END;
$$ LANGUAGE plpgsql;