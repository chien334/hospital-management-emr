CREATE PROCEDURE [dbo].[SP_Dashboard_LAB_AbnormalNormalTestCount]
	@labTestId int
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

	CREATE TABLE #DateRangeInMonths
	(
		SN INT,
		Months varchar(20)
	);
	INSERT INTO #DateRangeInMonths
		(SN,Months)
	VALUES
			(1,'Jan'),
			(2,'Feb'),
            (3,'Mar'),
            (4,'Apr'),
            (5,'May'),
            (6,'Jun'),
            (7,'Jul'),
            (8,'Aug'),
            (9,'Sep'),
            (10,'Oct'),
			(11,'Nov'),
            (12,'Dec')


select Months.Months,Count(res.TestComponentResultId) AS TotalCount,'Normal' AS 'TestResultType' from #DateRangeInMonths Months
left Join  
(select 
TestComponentResultId ,
[dbo].[DateDiffereneForDashboard](CreatedOn) as Months
from LAB_TXN_TestComponentResult where Range is not null
and IsAbnormal=0  AND IsActive=1 AND LabTestId=@labTestId
)res
on Months.Months=res.Months 
group by Months.Months

--Abnormal Count
select Months.Months,Count(res.TestComponentResultId) AS TotalCount,'Abnormal' AS 'TestResultType' from #DateRangeInMonths Months
left Join  
(select 
TestComponentResultId ,
[dbo].[DateDiffereneForDashboard](CreatedOn) as Months
from LAB_TXN_TestComponentResult where Range is not null
and IsAbnormal=1 AND IsActive=1 AND LabTestId=@labTestId
)res
on Months.Months=res.Months 
group by Months.Months

--Number Of Visits
select Months.Months,Count(res.PatientVisitId) AS TotalCount,'NoOfVisits' AS 'TestResultType' from #DateRangeInMonths Months
left Join  
(
select 
distinct(req.PatientVisitId),
[dbo].[DateDiffereneForDashboard](res.CreatedOn) as Months
from LAB_TXN_TestComponentResult res
inner join LAB_TestRequisition req
on req.RequisitionId=res.RequisitionId
where res.IsActive=1 AND res.Range is not null AND res.LabTestId=@labTestId
)res
on Months.Months=res.Months 
group by Months.Months
DROP TABLE #DateRangeInMonths
END