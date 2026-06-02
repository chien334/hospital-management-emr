CREATE PROCEDURE [dbo].[SP_Report_Patient_RegistrationReport] 
	  @FromDate DATE = null
	, @ToDate DATE = null
	, @Gender VARCHAR(50) = null
	, @Country VARCHAR(100) = NULL
AS
/*
FileName: [SP_Report_Patient_RegistrationReport]
Description: To get the Patient Registration Report for the hospital.
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Sanjeev/2023-09-07					Add SchemeName in select query for the registration report
*/
BEGIN
	IF (
			(@FromDate IS NOT NULL)
			AND (@ToDate IS NOT NULL)
			)
	BEGIN
		SELECT 
			  CONVERT(DATE, pat.CreatedOn) AS 'RegisteredDate'
			, pat.ShortName AS PatientName
			, pat.DateOfBirth
			, pat.Age
			, pat.Gender
			, pat.PhoneNumber
			, pat.CountryName
			, pat.Address
			, LatestVisit.SchemeName
			, pat.BloodGroup
			, pat.Email
			, ins.InsuranceNumber
		FROM 
		(SELECT 
			patient.PatientId,
			patient.CreatedOn,
			patient.ShortName, 
			patient.DateOfBirth,
			patient.Age,
			patient.Gender,
			patient.PhoneNumber,
			patient.Address,
			patient.BloodGroup,
			patient.Email,
			country.CountryName
		FROM PAT_Patient patient
			INNER JOIN (SELECT LTRIM(RTRIM(value)) AS 'Gender' 
						FROM string_split(@Gender, ',')) gen ON patient.Gender = gen.Gender
			INNER JOIN MST_Country AS country ON country.CountryId = patient.CountryId
		 WHERE (Convert(DATE, patient.CreatedOn) BETWEEN CONVERT(DATE, @FromDate) AND CONVERT(DATE, @ToDate))
			   AND (country.CountryName = @Country OR @Country IS NULL)
		)pat
		LEFT JOIN (
			SELECT * FROM
				(SELECT 
				PatientId, PatientVisitId,innerVisit.SchemeId, scheme.SchemeName, 
				ROW_NUMBER() OVER( Partition By PatientId order by PatientVisitId DESC) AS 'row_num'
				FROM PAT_PatientVisits innerVisit
				INNER JOIN BIL_CFG_Scheme AS scheme ON innerVisit.SchemeId = scheme.SchemeId
				)visit
				WHERE visit.row_num = 1
			) AS LatestVisit ON pat.PatientId = LatestVisit.PatientId
		LEFT JOIN PAT_PatientInsuranceInfo AS ins ON pat.PatientId = ins.PatientId		
		ORDER BY (CONVERT(DATE, pat.CreatedOn)) DESC
	END
END