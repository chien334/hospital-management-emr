CREATE PROCEDURE [dbo].[SP_APPT_PatientListForNewVisit] @SearchTxt VARCHAR(200) = ''
  ,@RowCounts INT = NULL
  ,@SearchUsingHospitalNo BIT = NULL
  ,@SearchUsingIdCardNo BIT = NULL
AS
/*  
 FileName: [SP_APPT_PatientListForNewVisit]   
 Created: 10-Oct'21/Sud  
 Description: To Get the Patients Info + IsAdmitted for patient matching given search conditions.  
            -- Returns upto 200 patients  
   --Match fields: ShortName, PatientCode (HospitalNo), PhoneNumber  
 Remarks:  Remove Insurance related informations if not required..   
 Change History  
 S.No.    Date/User              Change          Remarks  
 1.      10-Oct'21/Sud                          inital draft   
 2.      20-Apr'22/Dev Narayan                  added email in select statement.  
 3.      07-Sept-22/Krishna						changed the logic of predicates either do exact search with HospitalNo or do using like
 4.      22th,Sept'22/Dev Narayan				Added SSFPolicyNumber in Select Statement.
 5.      1st,Dec'22/Krishna						Added EthnicGroup in Select Statement.
 6.      6th,Jan'23/Krishna						Added MedicareMemberNo in Select Statement.
 4.      23Jan'23/Sud							Add PatientSearch using IdCardNo as well (only for APF) --Merged from:2ndDec'22/Krishna
 5.      15Feb'23/Sanjeev						Add WardNumber
 6.      28Feb'23/Sanjeev						Update condition for SSF PolicyNo, Add PolicyNo
 7.      12thMar'23/Krishna						Rename PAT_MAP_PriceCategory to PAT_MAP_PatientSchemes
 8.      12thMar'23/Krishna						Change PAT_CFG_MembershipType to BIL_CFG_Scheme
 9.      23rdMarch'23/Krishna					Remove The JOIN with BIL_CFG_Scheme
 10.     25thJune'23/Bibek						Added Care taker details whiel fetching patient details 
 11.     10thJuly'23/Bibek						Joined patient visit table to get the patient with latest visitid
 12.	 11thJuly'23/Krishna					Fix same Patient seen multiple times in Appointment New Visit list and
												ADT Create Admission list
 13.	 8thOct'23/Krishna					    Take latest row from PatientSchemeMap based on LatestVisitDate for a patient

*/
BEGIN
  IF (@SearchTxt = '')
  BEGIN
    SET @SearchTxt = NULL
  END

  IF (@SearchUsingHospitalNo IS NULL)
  BEGIN
    SET @SearchUsingHospitalNo = 0;
  END

  IF (@SearchUsingIdCardNo IS NULL)
  BEGIN
    SET @SearchUsingIdCardNo = 0;
  END

  SET @RowCounts = ISNULL(@RowCounts, 200) --default rowscount=200  
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
  SELECT TOP (@RowCounts) pat.PatientId
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
    --,scheme.DiscountPercent 'SchemeDiscountPercent'
    ,pat.PANNumber
    ,pat.BloodGroup
    ,pat.DialysisCode
    ,CASE 
      WHEN adm.PatientId IS NOT NULL
        THEN 1
      ELSE 0
      END AS IsAdmitted
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
    ,mediMember.MemberNo AS 'MedicareMemberNo'
    ,patMap.PolicyNo 'PolicyNo'
    ,gur.GuarantorName AS 'CareTakerName'
    ,gur.PatientRelationship AS 'RelationWithCareTaker'
    ,gur.GuarantorPhoneNumber AS 'CareTakerContact'
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
			ROW_NUMBER() OVER (PARTITION BY PatientId ORDER BY PatientVisitId DESC) AS 'row_num' 
			FROM PAT_PatientVisits) patVis 
      on patMapScheme.PatientId = patVis.PatientId AND patMapScheme.LatestPatientVisitId = patVis.PatientVisitId AND patMapScheme.SchemeId = patVis.SchemeId
	  WHERE patVis.row_num = 1
    )patMap ON pat.PatientId = patMap.PatientId
  LEFT JOIN PAT_PatientGurantorInfo gur ON pat.PatientId = gur.PatientId
  WHERE pat.IsActive = 1
    AND
    --Krishna,07th,Sept'22 , Logic below works as; If @SearchUsingHospitalNo is false then search is done through like operator but if @SearchUsingHospitalNo is true then search is done through exact Hospital No
    (
      (
        ISNULL(@SearchUsingHospitalNo, 0) = 0
        AND ISNULL(@SearchUsingIdCardNo, 0) = 0
        )
      AND (
        pat.PatientCode LIKE '%' + ISNULL(@SearchTxt, '') + '%'
        OR pat.ShortName LIKE '%' + ISNULL(@SearchTxt, '') + '%'
        OR ISNULL(pat.PhoneNumber, '') LIKE '%' + ISNULL(@SearchTxt, '') + '%'
        )
      )
    OR (
      ISNULL(@SearchUsingHospitalNo, 0) = 1
      AND pat.PatientCode = ISNULL(@SearchTxt, pat.PatientCode)
      )
  ORDER BY PatientId DESC --Show recent patient at top..   
END