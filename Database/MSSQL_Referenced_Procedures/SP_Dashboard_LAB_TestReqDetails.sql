CREATE PROCEDURE [dbo].[SP_Dashboard_LAB_TestReqDetails]
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
	  Table-1: For Lab Req till Date
	  Table-2: For Lab Req Today
*************************************************************************/
	

--Negative
select 'Negative' as 'Result','TillNow' As 'DateRange', 'All' as 'PatientVisitType' , COUNT(DISTINCT(RequisitionId)) as TotalCount from LAB_TXN_TestComponentResult where RequisitionId NoT IN
(
select DISTINCT(RequisitionId) from   LAB_TXN_TestComponentResult res 
where  Value='Positive'

) AND Value='Negative' AND  IsActive=1

--Positive
UNION ALL
select 'Positive' as 'Result','TillNow' As 'DateRange', 'All' as 'PatientVisitType' , COUNT(DISTINCT(RequisitionId)) as TotalCount from   LAB_TXN_TestComponentResult res 
where  Value='Positive' AND  IsActive=1
UNION ALL
--pending
select 'Pending' as 'Result' ,'TillNow' As 'DateRange', 'All' as 'PatientVisitType' , ISNULL(SUM(ResultNotFinalized),0) as TotalCount
from(
select
 Case When OrderStatus IN ('active','pending') THEN 1 Else 0 End As ResultNotFinalized 
from   LAB_TestRequisition  
where   BillingStatus in ('paid','unpaid','provisional') AND  IsActive=1
)res
--Total
UNION ALL
select 'Total' as 'Result' ,'TillNow' As 'DateRange', 'All' as 'PatientVisitType' , COUNT(DISTINCT(RequisitionId)) as TotalCount from   LAB_TXN_TestComponentResult res 
where   IsActive=1


--New visit
--Complete
UNION ALL
SELECT 'Complete' as 'Result','TillNow' As 'DateRange', 'New' as 'PatientVisitType' , 
	COUNT(RequisitionId) AS TotalCount
	FROM LAB_TestRequisition labReq 
	JOIN PAT_PatientVisits pat
	ON pat.PatientVisitId=labReq.PatientVisitId
	WHERE labReq.IsActive=1 AND (labReq.OrderStatus='result-added' OR labReq.OrderStatus='report-generated') 
	AND (labReq.BillingStatus='unpaid' OR labReq.BillingStatus='paid')
	AND pat.AppointmentType='New'

--Pending
UNION ALL
SELECT 'Pending' as 'Result','TillNow' As 'DateRange', 'New' as 'PatientVisitType' , 
	COUNT(RequisitionId) AS TotalCount
	FROM LAB_TestRequisition labReq 
	JOIN PAT_PatientVisits pat
	ON pat.PatientVisitId=labReq.PatientVisitId
	WHERE labReq.IsActive=1 AND labReq.OrderStatus='pending'
	AND (labReq.BillingStatus='unpaid' OR labReq.BillingStatus='paid')
	AND pat.AppointmentType='New'
--returned
UNION ALL
SELECT 'Returned' as 'Result','TillNow' As 'DateRange', 'New' as 'PatientVisitType' , 
	COUNT(RequisitionId) AS TotalCount
	FROM LAB_TestRequisition labReq 
	JOIN PAT_PatientVisits pat
	ON pat.PatientVisitId=labReq.PatientVisitId
	WHERE labReq.IsActive=1 
	AND labReq.BillingStatus='returned'
	AND pat.AppointmentType='New'
--Cancelled
UNION ALL

SELECT 'Cancelled' as 'Result','TillNow' As 'DateRange', 'New' as 'PatientVisitType' , 
	COUNT(RequisitionId) AS TotalCount
	FROM LAB_TestRequisition labReq 
	JOIN PAT_PatientVisits pat
	ON pat.PatientVisitId=labReq.PatientVisitId
	WHERE labReq.IsActive=1 
	AND labReq.BillingStatus='cancelled'
	AND pat.AppointmentType='New'

--Total
UNION ALL

SELECT 'Total' as 'Result','TillNow' As 'DateRange', 'New' as 'PatientVisitType' , 
	COUNT(RequisitionId) AS TotalCount
	FROM LAB_TestRequisition labReq 
	JOIN PAT_PatientVisits pat
	ON pat.PatientVisitId=labReq.PatientVisitId
	WHERE labReq.IsActive=1 
	AND pat.AppointmentType='New'




--Negative
select 'Negative' as 'Result','Today' As 'DateRange', 'All' as 'PatientVisitType' , COUNT(DISTINCT(RequisitionId)) as TotalCount from LAB_TXN_TestComponentResult where RequisitionId NoT IN
(
select DISTINCT(RequisitionId) from   LAB_TXN_TestComponentResult res 
where  Value='Positive'

) AND Value='Negative' AND  IsActive=1 AND CONVERT(DATE,CreatedOn)=GetDate()

--Positive
UNION ALL
select 'Positive' as 'Result','Today' As 'DateRange', 'All' as 'PatientVisitType' , COUNT(DISTINCT(RequisitionId)) as TotalCount from   LAB_TXN_TestComponentResult res 
where  Value='Positive' AND  IsActive=1 AND CONVERT(DATE,CreatedOn)=GetDate()
UNION ALL
--pending
select 'Pending' as 'Result' ,'Today' As 'DateRange', 'All' as 'PatientVisitType' , ISNULL(SUM(ResultNotFinalized),0) as TotalCount
from(
select
 Case When OrderStatus IN ('active','pending') THEN 1 Else 0 End As ResultNotFinalized 
from   LAB_TestRequisition  
where   BillingStatus in ('paid','unpaid','provisional') AND  IsActive=1 AND CONVERT(DATE,OrderDateTime)=GetDate()
)res
--Total
UNION ALL
select 'Total' as 'Result' ,'Today' As 'DateRange', 'All' as 'PatientVisitType' , COUNT(DISTINCT(RequisitionId)) as TotalCount from   LAB_TXN_TestComponentResult res 
where  IsActive=1  AND CONVERT(DATE,CreatedOn)=GetDate()


--TODAY
UNION ALL
--Complete
SELECT 'Complete' as 'Result','Today' As 'DateRange', 'New' as 'PatientVisitType' , 
	COUNT(RequisitionId) AS TotalCount
	FROM LAB_TestRequisition labReq 
	JOIN PAT_PatientVisits pat
	ON pat.PatientVisitId=labReq.PatientVisitId
	WHERE labReq.IsActive=1 AND (labReq.OrderStatus='result-added' OR labReq.OrderStatus='report-generated') 
	AND (labReq.BillingStatus='unpaid' OR labReq.BillingStatus='paid')
	AND labReq.ResultAddedOn=GETDATE()
	AND pat.AppointmentType='New'

--Pending
UNION ALL
SELECT 'Pending' as 'Result','Today' As 'DateRange', 'New' as 'PatientVisitType' , 
	COUNT(RequisitionId) AS TotalCount
	FROM LAB_TestRequisition labReq 
	JOIN PAT_PatientVisits pat
	ON pat.PatientVisitId=labReq.PatientVisitId
	WHERE labReq.IsActive=1 AND labReq.OrderStatus='pending'
	AND (labReq.BillingStatus='unpaid' OR labReq.BillingStatus='paid')
	AND labReq.ResultAddedOn=GETDATE()
	AND pat.AppointmentType='New'
--return
UNION ALL
SELECT 'Returned' as 'Result','Today' As 'DateRange', 'New' as 'PatientVisitType' , 
	COUNT(RequisitionId) AS TotalCount
	FROM LAB_TestRequisition labReq 
	JOIN PAT_PatientVisits pat
	ON pat.PatientVisitId=labReq.PatientVisitId
	WHERE labReq.IsActive=1 
	AND labReq.BillingStatus='returned'
	AND labReq.ResultAddedOn=GETDATE()
	AND pat.AppointmentType='New'
--Cancelled
UNION ALL

SELECT 'Cancelled' as 'Result','Today' As 'DateRange', 'New' as 'PatientVisitType' , 
	COUNT(RequisitionId) AS TotalCount
	FROM LAB_TestRequisition labReq 
	JOIN PAT_PatientVisits pat
	ON pat.PatientVisitId=labReq.PatientVisitId
	WHERE labReq.IsActive=1 
	AND labReq.BillingStatus='cancelled'
	AND labReq.ResultAddedOn=GETDATE()
	AND pat.AppointmentType='New'

--Total
UNION ALL

SELECT 'Total' as 'Result','Today' As 'DateRange', 'New' as 'PatientVisitType' , 
	COUNT(RequisitionId) AS TotalCount
	FROM LAB_TestRequisition labReq 
	JOIN PAT_PatientVisits pat
	ON pat.PatientVisitId=labReq.PatientVisitId
	WHERE labReq.IsActive=1 
	AND labReq.ResultAddedOn=GETDATE()
	AND pat.AppointmentType='New'
END