CREATE PROCEDURE [dbo].[SP_ER_GetERTriagedPatientList] 
(
	@SelectedCase INT
)
AS
/*  
 FileName: [SP_ER_GetERTriagedPatientList]   
 Created: 2nd-Oct'23/Sanjeev  
 Description: To Get the Emergency Triage Patient List
 Change History  
 S.No.    Date/User              Change          Remarks  
 1.      2nd-Oct'23/Sanjeev                      Get the Emergency Triage Patient List passing the input parameter 'SelectedCase'
 2.		 3rd-Oct'23/Sanjeev						 Add SchemeName and PriceCategoryName in select query.
*/
BEGIN
	SELECT erPat.ERPatientId
		, erPat.ERPatientNumber
		, erpat.PatientId
		, erpat.PatientVisitId
		, pat.PatientCode
		, erpat.VisitDateTime
		, erpat.FirstName
		, erpat.MiddleName
		, erpat.LastName
		, erpat.Gender
		, erpat.Age
		, erpat.Age + '/' + SUBSTRING(erpat.Gender, 1, 1) AS AgeSex
		, erpat.DateOfBirth
		, erpat.ContactNo
		, erpat.Address
		, erpat.ReferredBy
		, erpat.ReferredTo
		, erpat.PerformerId
		, erpat.PerformerName
		--, erpat.Case
		, erpat.ConditionOnArrival
		, moa.ModeOfArrivalName
		, moa.ModeOfArrivalId
		, erpat.CareOfPerson
		, erpat.ERStatus
		, erpat.TriageCode
		, erpat.TriagedBy
		, erpat.TriagedOn
		, erpat.CreatedBy
		, erpat.CreatedOn
		, erpat.ModifiedBy
		, erpat.ModifiedOn
		, erpat.IsActive
		, erpat.OldPatientId
		, erpat.IsExistingPatient
		, pat.ShortName AS FullName
		, pat.CountryId
		, pat.CountrySubDivisionId
		, (
			SELECT TOP 1 employee.FullName
			FROM ER_Patient emrPat
			INNER JOIN EMP_Employee employee ON emrPat.TriagedBy = employee.EmployeeId
			WHERE emrPat.ERPatientId = emrPat.ERPatientId
				AND emrPat.ERStatus = 'triaged'
			) AS TriagedByName
		, (
			SELECT TOP 1 patC.*
			FROM ER_Patient_Cases patC
			INNER JOIN PAT_Patient patient ON patC.ERPatientId = patient.PatientId
			WHERE patC.IsActive = 1
				AND patC.ERPatientId = erPat.ERPatientId
			ORDER BY patC.PatientCaseId DESC
			FOR JSON PATH
				, WITHOUT_ARRAY_WRAPPER
			) AS PatientCases
		, patientSchemeMap.SchemeId
		, patientSchemeMap.PriceCategoryId
		, scheme.SchemeName
		, priceCat.PriceCategoryName
	FROM ER_Patient erPat
	INNER JOIN PAT_Patient pat ON erPat.PatientId = pat.PatientId
	LEFT JOIN ER_ModeOfArrival moa ON erPat.ModeOfArrival = moa.ModeOfArrivalId
	INNER JOIN PAT_PatientVisits visit ON erPat.PatientVisitId = visit.PatientVisitId
	LEFT JOIN PAT_MAP_PatientSchemes patientSchemeMap ON visit.PatientId = patientSchemeMap.PatientId
		AND visit.SchemeId = patientSchemeMap.SchemeId
	INNER JOIN BIL_CFG_Scheme scheme ON patientSchemeMap.SchemeId = scheme.SchemeId
	LEFT JOIN BIL_CFG_PriceCategory priceCat ON patientSchemeMap.PriceCategoryId = priceCat.PriceCategoryId
	WHERE erPat.ERStatus = 'triaged'
		AND erPat.IsActive = 1
		AND ISNULL(erPat.FinalizedStatus, '') = ''
		AND (
			@SelectedCase = 0
			OR @SelectedCase = (
				SELECT TOP 1 MainCase
				FROM ER_Patient_Cases epc
				WHERE epc.ERPatientId = erPat.ERPatientId
					AND epc.IsActive = 1
				ORDER BY PatientCaseId DESC
				)
			)
	ORDER BY erPat.ERPatientId DESC;
END