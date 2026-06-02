CREATE PROCEDURE SP_Dashboard_PAT_VisitByMembership @FromDate DATE = NULL
	,@ToDate DATE = NULL
AS
/*
 SP_Dashboard_PAT_VisitByMembership '2022-1-05'
FileName: [SP_Dashboard_PAT_VisitByMembership]
CreatedBy/date:Nirmala/2022-1-05
Description: .
Remarks:    A
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Nirmala/2022-1-05                created the script
*/
BEGIN
	SELECT count(visit.PatientId) 'Count'
		,type.MembershipTypeName
	FROM PAT_Patient pat
	INNER JOIN PAT_PatientVisits visit ON pat.PatientId = visit.PatientId
	INNER JOIN PAT_CFG_MembershipType type ON pat.MembershipTypeId = type.MembershipTypeId
	WHERE CONVERT(DATE, visit.VisitDate) BETWEEN CONVERT(DATE, @FromDate)
			AND CONVERT(DATE, @ToDate)
	GROUP BY type.MembershipTypeName
END