CREATE OR REPLACE FUNCTION sp_appt_patientlistfornewvisit(
    p_searchtxt VARCHAR DEFAULT NULL,
    p_rowcounts INT DEFAULT NULL,
    p_searchusinghospitalno BOOLEAN DEFAULT NULL,
    p_searchusingidcardno BOOLEAN DEFAULT NULL
)
RETURNS TABLE (
    "PatientId" INT,
    "PatientCode" VARCHAR,
    "ShortName" VARCHAR,
    "FirstName" VARCHAR,
    "LastName" VARCHAR,
    "MiddleName" INT,
    "Age" VARCHAR,
    "CountryName" INT,
    "Gender" VARCHAR,
    "PhoneNumber" TIMESTAMP,
    "DateOfBirth" TIMESTAMP,
    "Address" VARCHAR,
    "IsOutdoorPat" BOOLEAN,
    "CreatedOn" TIMESTAMP,
    "CountryId" INT,
    "CountrySubDivisionId" INT,
    "WardNumber" VARCHAR,
    "CountrySubDivisionName" TIMESTAMP,
    "MembershipTypeId" INT,
    "PANNumber" VARCHAR,
    "BloodGroup" VARCHAR,
    "DialysisCode" VARCHAR,
    "IsAdmitted" BOOLEAN,
    "Ins_HasInsurance" VARCHAR,
    "Ins_NshiNumber" VARCHAR,
    "Ins_InsuranceBalance" DECIMAL,
    "MunicipalityId" INT,
    "MunicipalityName" VARCHAR,
    "Email" VARCHAR,
    "IDCardNumber" INT,
    "Rank" VARCHAR,
    "DependentId" INT,
    "Posting" VARCHAR,
    "EthnicGroup" VARCHAR,
    "MedicareMemberNo" VARCHAR,
    "PolicyNo" VARCHAR,
    "CareTakerName" VARCHAR,
    "RelationWithCareTaker" TIMESTAMP,
    "CareTakerContact" TIMESTAMP
) AS $$
BEGIN
    /*  
     filename: "sp_appt_patientlistfornewvisit"   
     created: 10-oct'21/Sud  
     Description: To Get the Patients Info + IsAdmitted for patient matching given search conditions.  
                -- Returns upto 200 patients  
       --Match fields: ShortName, PatientCode (HospitalNo), PhoneNumber  
     Remarks:  Remove Insurance related informations if not required..   
     Change History  
     S.No.    Date/User              Change          Remarks  
     1.      10-Oct'21/sud                          inital draft   
     2.      20-apr'22/Dev Narayan                  added email in select statement.  
     3.      07-Sept-22/Krishna						changed the logic of predicates either do exact search with HospitalNo or do using like
     4.      22th,Sept'22/dev narayan				added ssfpolicynumber in select statement.
     5.      1st,dec'22/Krishna						Added EthnicGroup in Select Statement.
     6.      6th,Jan'23/krishna						added medicarememberno in select statement.
     4.      23jan'23/Sud							Add PatientSearch using IdCardNo as well (only for APF) --Merged from:2ndDec'22/krishna
     5.      15feb'23/Sanjeev						Add WardNumber
     6.      28Feb'23/sanjeev						update condition for ssf policyno, add policyno
     7.      12thmar'23/Krishna						Rename PAT_MAP_PriceCategory to PAT_MAP_PatientSchemes
     8.      12thMar'23/krishna						change pat_cfg_membershiptype to bil_cfg_scheme
     9.      23rdmarch'23/Krishna					Remove The JOIN with BIL_CFG_Scheme
     10.     25thJune'23/bibek						added care taker details whiel fetching patient details 
     11.     10thjuly'23/Bibek						Joined patient visit table to get the patient with latest visitid
     12.	 11thJuly'23/krishna					fix same patient seen multiple times in appointment new visit list and
    												adt create admission list
     13.	 8thoct'23/Krishna					    Take latest row from PatientSchemeMap based on LatestVisitDate for a patient
    
    */
    BEGIN
      IF (p_searchtxt = '')
      THEN
        p_searchtxt := NULL;
      END IF;
    
      IF (p_searchusinghospitalno IS NULL)
      THEN
        p_searchusinghospitalno := 0;
      END IF;
    
      IF (p_searchusingidcardno IS NULL)
      THEN
        p_searchusingidcardno := 0;
      END IF;
    
      p_rowcounts := COALESCE(p_rowcounts, 200); --default rowscount=200  
      
      RETURN QUERY SELECT  pat.PatientId
        ,pat.PatientCode
        ,pat.ShortName
        ,pat.FirstName
        ,pat.LastName
        ,pat.MiddleName
        ,pat.Age
        ,cntry.CountryName
        ,pat.Gender
        ,pat.PhoneNumber
        ,pat.DateOfBirth
        ,pat.Address
        ,pat.IsOutdoorPat
        ,pat.CreatedOn
        ,pat.CountryId
        ,pat.CountrySubDivisionId
        ,pat.WardNumber
        ,sub.CountrySubDivisionName
        ,pat.MembershipTypeId
        --,scheme.SchemeName
        --,scheme.DiscountPercent 'schemediscountpercent'
        ,pat.PANNumber
        ,pat.BloodGroup
        ,pat.DialysisCode
        ,CASE 
          WHEN adm.PatientId IS NOT NULL
            THEN 1
          ELSE 0
          END AS "IsAdmitted"
        ,pat.Ins_HasInsurance
        ,pat.Ins_NshiNumber
        ,pat.Ins_InsuranceBalance
        ,pat.MunicipalityId
        ,munc.MunicipalityName
        ,pat.Email
        ,pat.IDCardNumber
        ,pat.Rank
        ,pat.DependentId
        ,pat.Posting
        ,pat.EthnicGroup
        ,mediMember.MemberNo AS "MedicareMemberNo"
        ,patMap.PolicyNo AS "PolicyNo"
        ,gur.GuarantorName AS "CareTakerName"
        ,gur.PatientRelationship AS "RelationWithCareTaker"
        ,gur.GuarantorPhoneNumber AS "CareTakerContact"
      FROM PAT_Patient pat
      INNER JOIN MST_Country cntry ON pat.CountryId = cntry.CountryId
      INNER JOIN MST_CountrySubDivision sub ON pat.CountrySubDivisionId = sub.CountrySubDivisionId
      --INNER JOIN BIL_CFG_Scheme scheme ON pat.MembershipTypeId = scheme.SchemeId
      LEFT JOIN (
        SELECT DISTINCT PatientId
        FROM ADT_PatientAdmission
        WHERE AdmissionStatus = 'admitted'
        ) adm ON pat.PatientId = adm.PatientId
      LEFT JOIN MST_Municipality munc ON pat.MunicipalityId = munc.MunicipalityId
      LEFT JOIN INS_MedicareMember mediMember ON mediMember.PatientId = pat.PatientId
      LEFT JOIN (SELECT patMapScheme.PatientId,PolicyNo FROM  
          PAT_MAP_PatientSchemes patMapScheme 
          JOIN (SELECT PatientId, PatientVisitId, SchemeId,
    			ROW_NUMBER() OVER (PARTITION BY PatientId ORDER BY PatientVisitId DESC) AS "row_num" 
    			FROM PAT_PatientVisits) patVis 
          on patMapScheme.PatientId = patVis.PatientId AND patMapScheme.LatestPatientVisitId = patVis.PatientVisitId AND patMapScheme.SchemeId = patVis.SchemeId
    	  WHERE patVis.row_num = 1
        )patMap ON pat.PatientId = patMap.PatientId
      LEFT JOIN PAT_PatientGurantorInfo gur ON pat.PatientId = gur.PatientId
      WHERE pat.IsActive = 1
        AND
        --Krishna,07th,Sept'22 , logic below works as; if p_searchusinghospitalno is false then search is done through like operator but if p_searchusinghospitalno is true then search is done through exact hospital no
        (
          (
            coalesce(p_searchusinghospitalno, 0) = 0
            and coalesce(p_searchusingidcardno, 0) = 0
            )
          and (
            pat.patientcode like '%' || coalesce(p_searchtxt, '') || '%'
            or pat.shortname like '%' || coalesce(p_searchtxt, '') || '%'
            or coalesce(pat.phonenumber, '') like '%' || coalesce(p_searchtxt, '') || '%'
            )
          )
        or (
          coalesce(p_searchusinghospitalno, 0) = 1
          and pat.patientcode = coalesce(p_searchtxt, pat.patientcode)
          )
      order by patientid desc limit p_rowcounts; --show recent patient at top..   
    end;
END;
$$ LANGUAGE plpgsql;