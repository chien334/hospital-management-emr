CREATE PROCEDURE [dbo].[SP_Dashboard_PAT_PatientCountByDay] @FromDate DATE = NULL
	,@ToDate DATE = NULL
AS
/*
 SP_Dashboard_PAT_PatientCountByDay '2022-1-05'
FileName: [SP_Dashboard_PAT_PatientCountByDay]
CreatedBy/date: Nirmala/Rohit/2022-1-05
Description: .
Remarks:    A
Change History
S.No.    UpdatedBy/Date                        Remarks
1      Nirmala/Rohit/2022-1-05                created the script
*/
BEGIN
	DECLARE @DateDiff INT = (
			SELECT DATEDIFF(day, @FromDate, @ToDate)
			)

	IF (@DateDiff <= 7)
SELECT TOP 7 CONVERT(VARCHAR(12), pat.CreatedOn, 7) 'Label',
			visit.VisitType,
			COUNT(pat.PatientId) 'PatientCount'
		FROM PAT_Patient pat INNER JOIN PAT_PatientVisits visit ON pat.PatientId=visit.PatientId
		WHERE CONVERT(DATE, pat.CreatedOn) BETWEEN @FromDate
				AND @ToDate
		GROUP BY CONVERT(VARCHAR(12), pat.CreatedOn, 7)
			,Month(pat.CreatedOn)
			,DAY(pat.CreatedOn),visit.VisitType
		ORDER BY Month(pat.CreatedOn)
			,DAY(pat.CreatedOn),visit.VisitType
	ELSE
	BEGIN
		
		SELECT		'' AS Label,
			'inpatient' AS VisitType,
			count(pat.PatientId) 'PatientCount' 
		FROM PAT_Patient pat inner join 
		PAT_PatientVisits visit on pat.PatientId=visit.PatientId
		WHERE VisitType='InPatient' AND CONVERT(DATE,pat.CreatedOn) BETWEEN @FromDate and @ToDate  
		UNION ALL
		SELECT 
		'' AS Label,
			'outpatient' as VisitType,
			COUNT(pat.PatientId) 'PatientCount' 
		FROM PAT_Patient pat inner join 
		PAT_PatientVisits visit on pat.PatientId=visit.PatientId 
		WHERE VisitType='OutPatient'AND CONVERT(DATE,pat.CreatedOn) between @FromDate and @ToDate  
	END
END