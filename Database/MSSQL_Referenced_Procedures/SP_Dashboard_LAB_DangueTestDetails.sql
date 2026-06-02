CREATE PROCEDURE [dbo].[SP_Dashboard_LAB_DangueTestDetails]
AS
BEGIN
/************************************************************************
FileName: [SP_Dashboard_LAB_TrendingLabTest]   
CreatedBy/date: Prem: 3rd Jan,2023
Description: To get details of  Test Completed for Dashboard
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1.    Prem						Initial Daft
*************************************************************************/
	
	
	DECLARE @TestId INT 
			SET @TestId=(
					SELECT LabTestId FROM LAB_LabTests 
					where LabTestName like 'Dengue%')
	
	select 'TillNow' as 'TimePeriod', sum(ResultNotFinalized) AS ResultNotFinalizedCount , sum(PositiveCount) AS PositiveCount,sum(NegativeCount) AS NegativeCount,
	sum(ResultNotFinalized+PositiveCount+NegativeCount) As TotalCount
	from
	(Select  req.LabTypeName,  req.PatientId,
		req.LabTestName, req.CreatedOn,
	   Case When req.OrderStatus IN ('active','pending') THEN 1 Else 0 End As ResultNotFinalized   ,
	   case when req.OrderStatus IN ('report-generated','result-added') and res.Value = 'Positive' then 1 Else 0 End AS PositiveCount,
	   case when req.OrderStatus IN ('report-generated','result-added') and res.Value is null then 1 Else 0 End AS NegativeCount
	From LAB_TestRequisition req
	LEFT JOIN (Select Distinct RequisitionId, Value
				From LAB_TXN_TestComponentResult
				Where LabTestId=@TestId and Value='Positive' and IsActive=1
				) res
	on req.RequisitionId = res.RequisitionId
	where req.LabTestId = @TestId
	AND req.BillingStatus in ('paid','unpaid','provisional')
	)resTempTillNow   
	UNION ALL
	select 'Today' as 'TimePeriod',isnull(sum(ResultNotFinalized),0) AS ResultNotFinalizedCount  , sum(ResultNotFinalized+PositiveCount+NegativeCount) As TotalCount,
			isnull(sum(PositiveCount),0) AS PositiveCount   ,isnull(sum(NegativeCount),0) AS NegativeCount   
	from
	(Select  req.LabTypeName,  req.PatientId,
		req.LabTestName, req.CreatedOn,
	   Case When req.OrderStatus IN ('active','pending') THEN 1 Else 0 End As ResultNotFinalized   ,
	   case when req.OrderStatus IN ('report-generated','result-added') and res.Value = 'Positive' then 1 Else 0 End AS PositiveCount,
	   case when req.OrderStatus IN ('report-generated','result-added') and res.Value is null then 1 Else 0 End AS NegativeCount
	From LAB_TestRequisition req
	LEFT JOIN (Select Distinct RequisitionId, Value
				From LAB_TXN_TestComponentResult
				Where LabTestId=@TestId and Value='Positive' and IsActive=1
				) res
	on req.RequisitionId = res.RequisitionId
	where req.LabTestId = @TestId
	AND CONVERT(DATE,req.OrderDateTime)=GETDATE()
	AND req.BillingStatus in ('paid','unpaid','provisional')
	)resTempToday

END