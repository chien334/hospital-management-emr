CREATE OR REPLACE FUNCTION sp_phrm_getpatientlist(
    p_searchtxt VARCHAR,
    p_isinsurance BOOLEAN DEFAULT NULL
)
RETURNS TABLE (
    "PatientId" INT,
    "PatientCode" VARCHAR,
    "FirstName" VARCHAR,
    "MiddleName" INT,
    "LastName" VARCHAR,
    "ShortName" VARCHAR,
    "Age" VARCHAR,
    "Gender" VARCHAR,
    "PhoneNumber" TIMESTAMP,
    "DateOfBirth" TIMESTAMP,
    "Address" VARCHAR,
    "IsOutdoorPat" BOOLEAN,
    "CountryId" INT,
    "CountrySubDivisionId" INT,
    "CountrySubDivisionName" TIMESTAMP,
    "PANNumber" VARCHAR,
    "Ins_NshiNumber" VARCHAR,
    "ClaimCode" VARCHAR,
    "Ins_HasInsurance" VARCHAR,
    "Ins_InsuranceBalance" DECIMAL,
    "PatientVisitId" INT,
    "VisitDate" TIMESTAMP,
    "PerformerId" INT
) AS $$
BEGIN
    /*  
     filename: "sp_phrm_getpatientlist" '018658684'  
     created: 09oct'21/Sud/Sanjit  
     Description: To get Patient along with Insurance Information + latest visit's doctor information.   
         --when p_isinsurance= false or null then get all patient.  
      --when p_searchtxt is null or empty then get all patients.  
      --p_searchtxt compares these columns: patientcode, shortname, insurancenshi code, phonenumber..  (add more fields if required later).  
       
     remarks: need to add more fields later as required..   
     change history  
     s.no.    date/user                     change          remarks  
     1.       09oct'21/Sud/Sanjit           Created          Initial Draft. 
     2.		  2Jun'22/krishna				alter			 changed providerid to performerid
    */  
       
      
      
      
    RETURN QUERY SELECT  pat.patientid,  
     pat.patientcode,  
     pat.firstname,  
     pat.middlename,  
     pat.lastname,  
     pat.shortname,  
     pat.age,  
     pat.gender,  
     pat.phonenumber,  
     pat.dateofbirth,  
     pat.address,  
     pat.isoutdoorpat,  
     pat.countryid,  
     pat.countrysubdivisionid,  
     district.countrysubdivisionname,  
     pat.pannumber,  
     pat.ins_nshinumber,  
     pat.ins_latestclaimcode AS "ClaimCode",  
     pat.ins_hasinsurance,  
     pat.ins_insurancebalance,  
     latestvisit.patientvisitid,  
     ((latestvisit.visitdate)::date)::varchar AS "VisitDate",  
     latestvisit.performerid  
      
    from pat_patient pat  
     inner join mst_countrysubdivision district on pat.countrysubdivisionid=district.countrysubdivisionid  
     left join(  
          
        select patientid, patientvisitid, visitcode, performerid, visitdate  
          from   
          (  
          select   
             row_number() over (  
              partition by patientid  
              order by patientvisitid desc  
             ) as "row_num",  
             patientid, patientvisitid,visitcode, performerid, visitdate  
      
          from   
             pat_patientvisits  
          ) a  
          where row_num=1  
       ) latestvisit on pat.patientid = latestvisit.patientid  
      
    where (pat.patientcode|| pat.shortname || coalesce(pat.phonenumber,'') || coalesce(pat.ins_nshinumber,'')) like '%'||coalesce(p_searchtxt,'')||'%'  
       and (coalesce(p_isinsurance,0)=0 or pat.ins_hasinsurance = p_isinsurance) limit 200;
END;
$$ LANGUAGE plpgsql;