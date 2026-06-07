CREATE OR REPLACE FUNCTION sp_ins_searchinsurancepatients(
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
    "PatientNameLocal" VARCHAR,
    "Age" VARCHAR,
    "Gender" VARCHAR,
    "PhoneNumber" TIMESTAMP,
    "DateOfBirth" TIMESTAMP,
    "Address" VARCHAR,
    "IsOutdoorPat" BOOLEAN,
    "CreatedOn" TIMESTAMP,
    "CountryId" INT,
    "CountryName" INT,
    "CountrySubDivisionId" INT,
    "CountrySubDivisionName" TIMESTAMP,
    "MunicipalityId" INT,
    "MunicipalityName" VARCHAR,
    "MembershipTypeId" INT,
    "MembershipTypeName" VARCHAR,
    "MembershipDiscountPercent" INT,
    "PANNumber" VARCHAR,
    "BloodGroup" VARCHAR,
    "Ins_HasInsurance" VARCHAR,
    "Ins_NshiNumber" VARCHAR,
    "Ins_InsuranceBalance" DECIMAL,
    "LatestClaimCode" VARCHAR,
    "IsAdmitted" BOOLEAN,
    "InsuranceProviderId" INT
) AS $$
DECLARE
    v_insproviderid INT;
BEGIN
    /*
     filename: "sp_ins_searchinsurancepatients" 
     created: 10-oct'21/Sud
     Description: To Get the Patients Info + IsAdmitted for patient matching given search conditions.
                -- Returns upto 200 patients
    			--Match fields: NSHI Number, ShortName, PatientCode (HospitalNo), PhoneNumber
     Remarks:  Searches only for Insurance patients, other informations can be removed if not required. 
     Change History
     S.No.    Date/User              Change          Remarks
     1.       10-Oct'21/sud                          inital draft 
     2.       28-oct'21/Sud                          Sending InsuranceProviderId of Gov-Insurance in return data.
                                                     it was causing issue in InsuranceBalanceUpdate because of null value. 
    */
    BEGIN  
    p_rowcounts := COALESCE(p_rowcounts,200);--default rowscount=200
    
    IF(p_searchtxt='null')
    THEN
      p_searchtxt := null;
    END IF;
    
    --Need to send back insurance providerid of GovernmentInsuarnce--
    
    v_insproviderid := ( Select InsuranceProviderId from INS_CFG_InsuranceProviders
    					 where InsuranceProviderName='government insurance');
    
    
    
    RETURN QUERY SELECT 
      pat.PatientId,
      pat.PatientCode,
      pat.ShortName,
      pat.FirstName,
      pat.LastName,
      pat.MiddleName,
      pat.PatientNameLocal,
      pat.Age,
      pat.Gender,
      pat.PhoneNumber,
      pat.DateOfBirth,
      pat.Address,
      pat.IsOutdoorPat,  pat.CreatedOn,
      pat.CountryId, cntry.CountryName,  pat.CountrySubDivisionId,  sub.CountrySubDivisionName,
      pat.MunicipalityId,munc.MunicipalityName,  
      pat.MembershipTypeId,  memb.MembershipTypeName,
      memb.DiscountPercent AS "MembershipDiscountPercent",
      pat.PANNumber,  pat.BloodGroup, 
      pat.Ins_HasInsurance,
      pat.Ins_NshiNumber,
      pat.Ins_InsuranceBalance,
      pat.Ins_LatestClaimCode AS "LatestClaimCode",
      case when adm.PatientId is not null then 1
         else 0 END AS "IsAdmitted",
      v_insproviderid AS "InsuranceProviderId"
    
    from PAT_Patient pat
     INNER JOIN  MST_Country cntry on pat.CountryId=cntry.CountryId
     inner join MST_CountrySubDivision sub
        on pat.CountrySubDivisionId=sub.CountrySubDivisionId
      inner join PAT_CFG_MembershipType memb on pat.MembershipTypeId=memb.MembershipTypeId
      LEFT JOIN 
      (
       Select distinct PatientId from ADT_PatientAdmission
       Where AdmissionStatus='admitted'
      ) adm
      on pat.PatientId=adm.PatientId
    
    Left join MST_Municipality munc
       ON pat.MunicipalityId=munc.MunicipalityId
    
    where pat.IsActive=1 
     and pat.Ins_HasInsurance=1 --take only insurance patients. 
    and (
           COALESCE(pat.Ins_NshiNumber,'') like '%' || COALESCE(p_searchtxt,'') || '%'
           OR pat.PatientCode like '%' || COALESCE(p_searchtxt,'') || '%'
           or pat.ShortName like '%' || COALESCE(p_searchtxt,'') || '%'  
    	   OR COALESCE(pat.PhoneNumber,'') LIKE '%' || COALESCE(p_searchtxt,'') || '%'
    	 )
    order by patientid desc limit p_rowcounts; 
    
    end;
END;
$$ LANGUAGE plpgsql;