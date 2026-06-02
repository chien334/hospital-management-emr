CREATE PROCEDURE [dbo].[SP_Dashboard_LAB_TrendingLabTest]
	@fromDate DATE= null, 
	@toDate DATE = null
AS
BEGIN
/************************************************************************
FileName: [SP_Dashboard_LAB_TrendingLabTest]   
CreatedBy/date: Prem: 3rd Jan,2023
Description: To get details of Top 10 Trending Lab Test for Dashboard
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1.    Prem						Initial Daft
*************************************************************************/
	SELECT TOP(10) 
		LabTestName,
		COUNT(LabTestName) AS Counts 
	FROM 
		LAB_TestRequisition 
	WHERE 
		IsActive=1 
		AND (BillingStatus='paid' OR BillingStatus='unpaid')
		AND CONVERT(date,OrderDateTime) BETWEEN @fromDate AND @toDate
	GROUP BY LabTestName
	ORDER BY Counts DESC
END