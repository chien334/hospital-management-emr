CREATE PROCEDURE [dbo].[SP_INS_GetVisitListOfValidDays]
	@SearchTxt VARCHAR(200) = '', 
	@RowCounts INT = 200,
	@DaysLimit INT = 1

	AS 
	/*
	 FileName: [SP_INS_GetVisitListOfValidDays] 
	 Created: 22-Dec'21/Krishna
	 Description: To Get the Patients visit list
				-- Returns upto 200 patients
				--Match fields: ShortName, PatientCode (HospitalNo), PhoneNumber
	 Remarks:   
	 Change History
	 S.No.    Date/User              Change          Remarks
	 1.       22-Dec'21/Krishna                      inital draft 
	 2.       25-Dec'21/Sud                          Can search also from Insurance NSHI Number.
	*/
	
	DECLARE @Now DATE
		SET @Now = GETDATE()
	DECLARE @ValidDate DATE
		SET @ValidDate = DATEADD(DAY, -@DaysLimit, @Now) --takes date @Dayslimit(eg: 7 days) days less than the current date.
		
	BEGIN 
		IF(@SearchTxt = 'null') 
	BEGIN 
		SET @SearchTxt = null 
	END 
		SET @RowCounts = ISNULL(@RowCounts, 200) --default rowscount=200

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SELECT TOP (@RowCounts) 
	  visit.PatientVisitId, 
	  visit.ParentVisitId, 
	  dept.DepartmentId,
	  dept.DepartmentName,
	  visit.PerformerId, 
	  visit.PerformerName, 
	  visit.VisitDate, 
	  visit.VisitTime, 
	  visit.VisitType, 
	  visit.AppointmentType, 
	  pat.PatientId, 
	  pat.PatientCode, 
	  pat.FirstName, 
	  pat.MiddleName, 
	  pat.LastName, 
	  pat.ShortName, 
	  pat.PhoneNumber, 
	  pat.DateOfBirth, 
	  pat.Gender, 
	  pat.CountryId, 
	  pat.PANNumber, 
	  pat.MembershipTypeId, 
	  pat.[Address], 
	  pat.Email, 
	  pat.LandLineNumber,
	  visit.ClaimCode,
	  pat.Ins_NshiNumber,
	  visit.Ins_HasInsurance,
	  visit.QueueNo, 
	  visit.BillingStatus AS BillStatus


	FROM PAT_PatientVisits AS visit
		INNER JOIN MST_Department AS dept ON visit.DepartmentId = dept.DepartmentId
		INNER JOIN PAT_Patient AS pat ON visit.PatientId = pat.PatientId
	WHERE 
	  pat.IsActive = 1
	  AND visit.IsActive=1
	  AND ISNULL(visit.Ins_HasInsurance, 0) = 1
	  AND CONVERT(DATE,visit.VisitDate) BETWEEN CONVERT(DATE,@ValidDate) AND CONVERT(DATE,@Now)
	  AND LOWER(visit.VisitType) != 'inpatient'
	  AND LOWER(visit.BillingStatus) != 'returned'
	  AND (
		pat.PatientCode LIKE '%' + ISNULL(@SearchTxt, '') + '%' 
		OR ISNULL(pat.Ins_NshiNumber,'') LIKE '%' + ISNULL(@SearchTxt, '') + '%'   --sud:25Dec'21: Additional where clause for Insurance Patients.
		OR pat.ShortName LIKE '%' + ISNULL(@SearchTxt, '') + '%' 
		OR ISNULL(pat.PhoneNumber, '') LIKE '%' + ISNULL(@SearchTxt, '') + '%'
	  ) 
	 
	ORDER BY 
	  visit.PatientVisitId DESC --Show recent visit at top.. 
	  END