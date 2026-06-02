CREATE PROCEDURE [dbo].[SP_APPT_GetVisitListOfValidDays]    
 @SearchTxt VARCHAR(200) = '',     
 @RowCounts INT = 200,    
 @DaysLimit INT = 7,
 @SearchUsingHospitalNo BIT = NULL,
 @SearchUsingIdCardNo BIT = NULL

 AS
/*    
  FileName: [SP_APPT_GetVisitListOfValidDays]     
  Created: 21-Dec'21/Krishna    
  Description: To Get the Patients visit list    
    -- Returns upto 200 patients    
    --Match fields: ShortName, PatientCode (HospitalNo), PhoneNumber    
  Remarks:       
  Change History    
  S.No.    Date/User              Change          Remarks    
  1.       21-Dec'21/Krishna                     inital draft     
  2.       24-Feb'22/Dev                         Added CountrySubDivisionName and    
											     CountrySubDivisionId (Required while refering)    
  3.	   18th,Jul'22/Krishna    Alter		     Age Coumn added in the select query  
  4.	   05th,Aug'22/Krishna    Alter			 Add DependentId,IdCardNumber,Posting,Rank in select Query  
  5.	   07th,Sept'22/Krishna	  Alter			 changed the logic of predicates either do exact search with HospitalNo or do 
												 using like
  6.       22th,Sept'22/Dev Narayan              Added SSFPolicyNumber in Select Statement.
  7.	   Krishna/17thNov'22					 Rename PatientVisitId to LatestPatientVisitId
  8.	   Krishna/1stDec'22					 Read PriceCategoryId from Visit
  9.	   Krishna/24Jan'23  	  Alter			 Add patient search using IdCardNo(for APF only) -- (Merged from: 2ndDEC'22/
											     Krishna)
  10.	   Sanjeev/1stMar'23	  Alter			 Add MembershipTypeName
  11.	   Krishna/12thMar'23	  Alter			 Rename PAT_MAP_PriceCategory to PAT_MAP_PatientScheme and PAT_CFG_MembershipType
												 to BIL_CFG_Scheme
  12.	   Krishna/22ndMarch'23   Alter	         Change Join Condition of BIL_CFG_Scheme with Patient to Visit
  13.	   Krishna/10thapril'23	  Alter			 Change condition for Ins_HasInsurance Predicate
  14.	   Sanjeev/18thMay'23	  Alter			 Add SchemeId in SELECT statement
  15.	   Krishna/8thOct'23	  Alter		     Read PolicyNo
  16.	   Krishna/7thNov'23	  Alter			 Read IsFreeVisit from Visit table
 */
DECLARE @Now DATE

SET @Now = GETDATE()

DECLARE @ValidDate DATE

SET @ValidDate = DATEADD(DAY, - @DaysLimit, @Now) --takes date @Dayslimit(eg: 7 days) days less than the current date.    

BEGIN
	IF (@SearchTxt = '')
	BEGIN
		SET @SearchTxt = NULL
	END

	IF (@SearchUsingHospitalNo IS NULL)
	BEGIN
		SET @SearchUsingHospitalNo = 0;
	END
	IF(@SearchUsingIdCardNo is null)
	BEGIN
		SET @SearchUsingIdCardNo = 0;
	END
  SET @RowCounts = ISNULL(@RowCounts, 200) --default rowscount=200    
    

	SET @RowCounts = ISNULL(@RowCounts, 200) --default rowscount=200    

	SELECT TOP (@RowCounts) visit.PatientVisitId
		,visit.ParentVisitId
		,dept.DepartmentId
		,dept.DepartmentName
		,visit.PerformerId
		,visit.PerformerName
		,visit.VisitDate
		,visit.VisitTime
		,visit.VisitType
		,visit.AppointmentType
		,pat.PatientId
		,pat.PatientCode
		,pat.FirstName
		,pat.MiddleName
		,pat.LastName
		,pat.ShortName
		,pat.PhoneNumber
		,pat.DateOfBirth
		,pat.Age
		,pat.Gender
		,pat.CountryId
		,pat.CountrySubDivisionId
		,countrySubDivision.CountrySubDivisionName
		,pat.PANNumber
		,pat.MembershipTypeId
		,scheme.SchemeName
		,scheme.SchemeId
		,pat.[Address]
		,pat.Email
		,pat.LandLineNumber
		,pat.DependentId
		,pat.IDCardNumber
		,pat.Posting
		,pat.[Rank] AS 'Rank'
		,visit.QueueNo
		,visit.BillingStatus AS BillStatus
		,map.PolicyNo AS 'PolicyNo'
		,visit.PriceCategoryId
		,visit.IsFreeVisit
	FROM PAT_PatientVisits AS visit
	INNER JOIN MST_Department AS dept ON visit.DepartmentId = dept.DepartmentId
	INNER JOIN PAT_Patient AS pat ON visit.PatientId = pat.PatientId
	INNER JOIN BIL_CFG_Scheme AS scheme on visit.SchemeId = scheme.SchemeId
	LEFT JOIN MST_CountrySubDivision AS countrySubDivision ON pat.CountrySubDivisionId = countrySubDivision.CountrySubDivisionId
	LEFT JOIN PAT_MAP_PatientSchemes map ON visit.PatientVisitId = map.LatestPatientVisitId
		AND pat.PatientId = map.PatientId
	WHERE pat.IsActive = 1
		AND visit.IsActive = 1
		AND CONVERT(DATE, visit.VisitDate) BETWEEN CONVERT(DATE, @ValidDate)
			AND CONVERT(DATE, @Now)
		AND LOWER(visit.VisitType) != 'inpatient'
		AND LOWER(visit.BillingStatus) != 'returned'
		AND (
			 --Krishna,07th,Sept'22 , Logic below works as; If @SearchUsingHospitalNo is false then search is done through like operator but if @SearchUsingHospitalNo is true then search is done through exact Hospital No
			((ISNULL(@SearchUsingHospitalNo,0) = 0 AND ISNULL(@SearchUsingIdCardNo,0) = 0) AND
				(pat.PatientCode like '%' + ISNULL(@SearchTxt,'') + '%'  
				OR pat.ShortName like '%' + ISNULL(@SearchTxt,'') + '%'    
				OR ISNULL(pat.PhoneNumber,'') LIKE '%' + ISNULL(@SearchTxt,'') + '%'))
			OR (ISNULL(@SearchUsingHospitalNo,0) = 1 AND pat.PatientCode = ISNULL(@SearchTxt,pat.PatientCode)) 
			OR (ISNULL(@SearchUsingIdCardNo,0) = 1 AND pat.IDCardNumber = ISNULL(@SearchTxt,pat.IDCardNumber)))     
		AND visit.Ins_HasInsurance = 0    
 ORDER BY     
   visit.PatientVisitId DESC --Show recent visit at top..     
   END