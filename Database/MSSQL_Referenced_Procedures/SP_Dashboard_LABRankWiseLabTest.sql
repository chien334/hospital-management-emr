CREATE PROCEDURE [dbo].[SP_Dashboard_LABRankWiseLabTest]
	@fromDate DATE= null, 
	@toDate DATE = null
AS
BEGIN
/************************************************************************
FileName: [SP_Dashboard_LAB_TrendingLabTest]   
CreatedBy/date: Prem: 3rd Jan,2023
Description: To get details of  lab Test Done according to MembershipType for Dashboard
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1.    Prem						Initial Daft
*************************************************************************/
	SELECT 
		pat.Rank,
		COUNT(labReq.RequisitionId) AS TotalCount 
	FROM LAB_TestRequisition labReq 
	INNER JOIN PAT_Patient pat ON labReq.PatientId = pat.PatientId 
	WHERE 
		labReq.IsActive=1 
		AND (OrderStatus='result-added' OR OrderStatus='report-generated') 
		AND (BillingStatus='unpaid' OR BillingStatus='paid') 
		AND  BillingStatus!='cancel'
		AND (pat.Rank IS NOT NULL OR pat.Rank!='')
		AND CONVERT(DATE,OrderDateTime) BETWEEN @fromDate AND @toDate 
	GROUP BY pat.Rank 
END