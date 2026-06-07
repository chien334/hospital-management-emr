CREATE OR REPLACE FUNCTION sp_pat_registeredpatientlist(
    p_searchtxt VARCHAR DEFAULT NULL,
    p_rowcounts INT DEFAULT NULL
)
RETURNS TABLE (
    "PatientId" INT,
    "PatientCode" VARCHAR,
    "ShortName" VARCHAR,
    "FirstName" VARCHAR,
    "LastName" VARCHAR,
    "MiddleName" INT,
    "Age" VARCHAR,
    "Gender" VARCHAR,
    "PhoneNumber" TIMESTAMP,
    "DateOfBirth" TIMESTAMP,
    "Address" VARCHAR,
    "IsOutdoorPat" BOOLEAN,
    "CreatedOn" TIMESTAMP,
    "WardNumber" VARCHAR
) AS $$
BEGIN
    /*
    filename: "sp_pat_registeredpatientlist" null
    created: 17-dec'21/Krishna
    Description: To Get the Patients List
    				-- Returns upto 200 patients
    				--Match fields: ShortName, PatientCode (HospitalNo), PhoneNumber
    Remarks:   
    Change History
    S.No.    Date/User              Change          Remarks
    1.       17-Dec'21/krishna                          inital draft 
    2.       17-june'22/Devendra     Concatenate patient address field
    3.		 10-October'23/sanjeev	 add wardnumber on select query.
    */
    
    begin 
    	if(p_searchtxt = 'null') 
    then 
    	p_searchtxt := null; 
    end if; 
    	p_rowcounts := coalesce(p_rowcounts, 200); --default rowscount=200
    
     RETURN QUERY SELECT  
    	  pat.patientid, 
    	  pat.patientcode, 
    	  pat.shortname, 
    	  pat.firstname, 
    	  pat.lastname, 
    	  pat.middlename, 
    	  pat.age, 
    	  pat.gender, 
    	  pat.phonenumber, 
    	  pat.dateofbirth, 
    	  coalesce(pat."address",'') || ' ' || coalesce(mun.municipalityname,'') ||   ' ' || coalesce(district.countrysubdivisionname,'')  AS "Address", 
    	  pat.isoutdoorpat, 
    	  pat.createdon,
    	  pat.wardnumber
    
     from 
    	  pat_patient pat 
    	  left join mst_countrysubdivision district on pat.countrysubdivisionid = district.countrysubdivisionid
    	  left join mst_municipality mun on pat.municipalityid = mun.municipalityid
     where 
    	  pat.isactive = 1 
    	  and (
    		pat.patientcode like '%' || coalesce(p_searchtxt, '') || '%' 
    		or pat.shortname like '%' || coalesce(p_searchtxt, '') || '%' 
    		or coalesce(pat.phonenumber, '') like '%' || coalesce(p_searchtxt, '') || '%'
    	  ) 
    	order by 
    	  patientid desc limit p_rowcounts; --show recent patient at top.. 
      end;
END;
$$ LANGUAGE plpgsql;