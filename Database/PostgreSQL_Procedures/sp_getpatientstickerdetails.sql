CREATE OR REPLACE FUNCTION sp_getpatientstickerdetails(
    p_patientid INT DEFAULT NULL
)
RETURNS TABLE (
    "HospitalNo" VARCHAR,
    "PatientName" VARCHAR,
    "Age" VARCHAR,
    "Contact" TIMESTAMP,
    "Address" VARCHAR,
    "Gender" VARCHAR,
    "DateOfBirth" TIMESTAMP,
    "MunicipalityName" VARCHAR,
    "CountryName" INT,
    "District" VARCHAR
) AS $$
BEGIN
    /*
    filename: "sp_getpatientstickerdetails"
    createdby/date: aniket/26-10-2021
    recreated by: krishna, 19thapril'23
    Description: To get the Details of Patient Sticker
    Remarks:    
    Change History
    S.No.    UpdatedBy/Date                        Remarks
    1.    Aniket/26-10-2021                    created the script
    2.	  Krishna/19thApril'23				   recreate the script as it was dropped earlier
    */
    begin
          if p_patientid is not null
              then
              RETURN QUERY SELECT p.patientcode AS "HospitalNo", 
    		         p.shortname AS "PatientName", 
    				 p.age AS "Age",
    				 p.phonenumber AS "Contact", 
    				 p.address AS "Address",
    				 p.gender AS "Gender",
    				 p.dateofbirth AS "DateOfBirth",
    				 m.municipalityname AS "MunicipalityName",
    				 c.countryname AS "CountryName",
    				 cs.countrysubdivisionname AS "District"
              from pat_patient p
    		  left join mst_municipality as m on p.municipalityid = m.municipalityid
    		  left join mst_country as c on p.countryid = c.countryid
    		  left join mst_countrysubdivision as cs on p.countrysubdivisionid = cs.countrysubdivisionid
    		  where patientid = p_patientid;
              end if;
    end;
END;
$$ LANGUAGE plpgsql;