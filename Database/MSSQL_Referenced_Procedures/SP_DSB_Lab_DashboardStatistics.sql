CREATE PROCEDURE [dbo].[SP_DSB_Lab_DashboardStatistics]
AS
/*
=============================================================================================
FileName: [SP_DSB_Lab_DashboardStatistics]
Description: Table1:To get stats for LAB dashboard --> to fill Labels
					-->> for sample pending	-->> OrderStatus = active && (BillingStatus == unpaid || BillingStatus == paid) && IsActive=true
					-->> for results pending	-->> OrderStatus = pending && (BillingStatus == unpaid || BillingStatus == paid) && IsActive=true
					-->> for test completed	-->> OrderStatus = result-added or report-generated && (BillingStatus == unpaid || BillingStatus == paid) && IsActive=true
					-->> for tests cancelled	-->> BillingStatus = cancel && IsActive=true
					-->> for tests returned	-->> BillingStatus = return && IsActive=true
					-->> for total test		-->> Count all where IsActive=true
			Table2:To get stats for LAB dashboard --> For Trending LabTest (last 30 days)
					takes count of LabTest - grouping by them with LabTestName, ordering them in descending order and selecting top 10 only
			Table3:to get count of LabTest performed today ( Templete wise count is shown)


Edited by Anish: 2 June, 2020 new Updated Status Added 
=============================================================================================
*/
BEGIN

--Table1
	SELECT * FROM 
		(select count(*) 'TotalAvailableTest' from LAB_LabTests where IsActive=1) labtest,
		(select
			ISNULL(SUM(1),0) AS 'TestRequisitedToday',
			ISNULL(SUM( CASE WHEN OrderStatus = 'active' and IsActive=1 and (BillingStatus <> 'cancel' AND BillingStatus <> 'returned') THEN 1 ELSE 0 END ),0) AS 'SamplePendingToday',
			ISNULL(SUM( CASE WHEN OrderStatus = 'pending' and IsActive=1 and (BillingStatus <> 'cancel' AND BillingStatus <> 'returned') THEN 1 ELSE 0 END ),0) AS 'AddResultsPendingToday',
			ISNULL(SUM( CASE WHEN (OrderStatus = 'result-added' or OrderStatus = 'report-generated') and IsActive=1 and (BillingStatus <> 'cancel' AND BillingStatus <> 'returned') THEN 1 ELSE 0 END ),0) AS 'CompletedToday',
			ISNULL(SUM( CASE WHEN BillingStatus='cancel'and IsActive=1 THEN 1 ELSE 0 END ),0) AS 'CancelledTestsToday',
			ISNULL(SUM( CASE WHEN BillingStatus = 'returned'and IsActive=1 THEN 1 ELSE 0 END ),0) AS 'ReturnedTestsToday'
			from LAB_TestRequisition where convert(date,OrderDateTime) = convert(date,getdate())
		) Today,
		(select
			SUM(1) AS 'TestRequisitedTillDate',
			SUM( CASE WHEN OrderStatus = 'active' and IsActive=1 and (BillingStatus <> 'cancel' AND BillingStatus <> 'returned') THEN 1 ELSE 0 END ) AS 'SamplePendingTillDate',
			SUM( CASE WHEN OrderStatus = 'pending' and IsActive=1 and (BillingStatus <> 'cancel' AND BillingStatus <> 'returned') THEN 1 ELSE 0 END ) AS 'AddResultsPendingTillDate',
			SUM( CASE WHEN (OrderStatus = 'result-added' or OrderStatus = 'report-generated') and IsActive=1 and (BillingStatus <> 'cancel' AND BillingStatus <> 'returned') THEN 1 ELSE 0 END ) AS 'CompletedTillDate',
			SUM( CASE WHEN BillingStatus='cancel'and IsActive=1 THEN 1 ELSE 0 END ) AS 'CancelledTestsTillDate',
			SUM( CASE WHEN BillingStatus = 'returned' and IsActive=1 THEN 1 ELSE 0 END ) AS 'ReturnedTestsTillDate'
			from LAB_TestRequisition
		) TillDate
--Table2
	SELECT TOP(10) LabTestName,COUNT(LabTestName) AS Counts FROM LAB_TestRequisition 
		WHERE IsActive=1 and (DATEDIFF(DAY,OrderDateTime,GETDATE()) BETWEEN 0 AND 30)
		GROUP BY LabTestName
		ORDER BY Counts DESC
--Table3
	SELECT ReportTemplateName,COUNT(req.LabTestName) Counts FROM LAB_TestRequisition req 
		JOIN LAB_LabTests test ON req.LabTestId=test.LabTestId
		JOIN Lab_ReportTemplate reprt ON test.ReportTemplateID=reprt.ReportTemplateID
		WHERE  req.IsActive=1 and (CONVERT(DATE,OrderDateTime) = CONVERT(DATE,GETDATE()))
		GROUP BY ReportTemplateName
END