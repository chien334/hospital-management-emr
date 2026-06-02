CREATE PROCEDURE [dbo].[SP_Dashboard_PAT_PatientDistributionBasedOnRank] @FromDate DATE = NULL
  ,@ToDate DATE = NULL
  ,@DepartmentId INT = NULL
AS
/*
 SP_Dashboard_PAT_PatientDistributionBasedOnRank '2022-1-05'
FileName: [SP_Dashboard_PAT_PatientDistributionBasedOnRank]
CreatedBy/date:Nirmala/2022-1-09
Description: .
Remarks:    A
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Nirmala/2022-1-05               created the script
2.		Nirmal/2023-01-09				ReScripted the query
*/
BEGIN
SELECT pat.Rank
	,COUNT(pat.PatientId) 'Count'
FROM Pat_Patient pat
INNER JOIN PAT_PatientVisits visit ON visit.PatientId = pat.PatientId
WHERE (
		visit.DepartmentId = @DepartmentId
		OR @DepartmentId IS NULL
		)
	AND pat.Rank IS NOT NULL AND CONVERT(DATE, visit.VisitDate) BETWEEN CONVERT(DATE, @FromDate)
    AND CONVERT(DATE, @ToDate)
GROUP BY pat.Rank
END