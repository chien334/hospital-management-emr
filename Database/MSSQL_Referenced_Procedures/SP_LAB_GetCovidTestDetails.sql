--start:anjana:7May'21--Correction in COVID-19 Statistics Stored Proc---

/*
 FileName: [SP_LAB_GetCovidTestDetails] 
 Created: May,3,2021
 Description: To get the details of Covid-19 test results
Remarks: 
 Change History
 S.No.    Date/User              Change          Remarks
 1.	     May,3,2021/Anjana		                inital draft
 2.		 May,6'21/Anjana					Added testname as parameter
 */
CREATE PROCEDURE [dbo].[SP_LAB_GetCovidTestDetails] 
@TestName varchar(200) = NULL
AS
BEGIN
Select * from 

(Select Count(*) TotalTest,
	Sum( Case when [Value] = 'Negative' then 1 else 0 end) as TotalNegative,
	Sum( Case when [Value] = 'Positive' then 1 else 0 end) as TotalPositive,
	Sum( Case when (req.OrderStatus ='pending' or req.OrderStatus ='active') then 1 else 0 end) as TotalPendingTests
	from LAB_TestRequisition req
	left join LAB_TXN_TestComponentResult result on req.RequisitionId = result.RequisitionId
	join LAB_LabTests test on req.LabTestId = test.LabTestId
	--where test.LabTestName = 'RT-PCR NCOV-2' and test.IsActive = 1) TillDate,
    where test.LabTestName = @TestName and test.IsActive = 1) TillDate,

	(Select Count(*) TotalTestToday,
	ISNULL( Sum( Case when [Value] = 'Negative' then 1 else 0 end),0) as TotalNegativeToday,
	ISNULL( Sum( Case when [Value] = 'Positive' then 1 else 0 end),0) as TotalPositiveToday,
	ISNULL( Sum( Case when (req.OrderStatus ='pending' or req.OrderStatus ='active') then 1 else 0 end),0) as PendingTestsToday
	from LAB_TestRequisition req
	left join LAB_TXN_TestComponentResult result on req.RequisitionId = result.RequisitionId
	join LAB_LabTests test on req.LabTestId = test.LabTestId
	where test.LabTestName = @TestName and test.IsActive = 1 
	and req.OrderDateTime between(CONVERT(date, getdate())) and CONVERT(date, DATEADD(day, 1, getdate()))) today
END