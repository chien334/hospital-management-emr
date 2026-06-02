CREATE PROCEDURE [dbo].[SP_Report_Appointment_DayAndMonthWiseVisitReport] @FromDate DATE = NULL
	,@ToDate DATE = NULL
	,@DepartmentId INT = NULL
	,@ReportType VARCHAR(20) = NULL
AS
/*
FileName: exec [SP_Report_Appointment_DayAndMonthWiseVisitReport]
 @FromDate  = '2023-03-06',
@ToDate  ='2023-06-27' , 
@DepartmentId  =  NULL,
@ReportType  = 'Month'
CreatedBy/date: Bibek, 21stJune'23
Description: This SP will generate a Day and Month wise Department Stat report for Appointment

Change History
S.No.    UpdatedBy/Date            Remarks
1      Bibek:21June'23             Initial Script 
2	   Bibek:22ndJune'23		   Remove Department from Month Wise Query
3.     Bibek:2ndJuly'23		       Group by the sum of month 
*/
BEGIN
	IF @ReportType = 'day'
	BEGIN
		SELECT dept.DepartmentName
			,VisitDate
			,DATENAME(MONTH, VisitDate) AS MonthName
			,DATENAME(WEEKDAY, VisitDate) AS DayName
			,SUM(CASE 
					WHEN AppointmentType = 'new'
						THEN 1
					ELSE 0
					END) AS NewTotal
			,SUM(CASE 
					WHEN AppointmentType = 'followup'
						THEN 1
					ELSE 0
					END) AS FollowupTotal
			,SUM(CASE 
					WHEN AppointmentType = 'new'
						THEN 1
					ELSE 0
					END) + SUM(CASE 
					WHEN AppointmentType = 'followup'
						THEN 1
					ELSE 0
					END) AS TotalVisit
		FROM PAT_PatientVisits vst
		JOIN MST_Department dept ON vst.DepartmentId = dept.DepartmentId
		WHERE CONVERT(DATE, VisitDate) BETWEEN CONVERT(DATE, @FromDate)
				AND CONVERT(DATE, @ToDate)
			AND VisitType <> 'inpatient' AND AppointmentType IN ('New','followup') AND BillingStatus <> 'returned'
			AND ISNULL(NULLIF(@DepartmentId, 0), vst.DepartmentId) = vst.DepartmentId
		GROUP BY vst.VisitDate
			,DATENAME(WEEKDAY, vst.VisitDate)
			,dept.DepartmentName;
	END
	ELSE IF @ReportType = 'month'
	BEGIN
	select sum(A.NewTotal) As NewTotal ,sum(A.FollowupTotal) AS FollowupTotal,sum(A.NewTotal+A.FollowupTotal) AS TotalVisit, MonthName from 
		(SELECT SUM(CASE 
					WHEN AppointmentType = 'new'
						THEN 1
					ELSE 0
					END) AS NewTotal
			,SUM(CASE 
					WHEN AppointmentType = 'followup'
						THEN 1
					ELSE 0
					END) AS FollowupTotal
			,SUM(CASE 
					WHEN AppointmentType = 'new'
						THEN 1
					ELSE 0
					END) + COUNT(CASE 
					WHEN AppointmentType = 'followup'
						THEN 1
					ELSE 0
					END) AS TotalVisit
			,DATENAME(MONTH, VisitDate) AS MonthName
		FROM PAT_PatientVisits vst
		JOIN MST_Department dept ON vst.DepartmentId = dept.DepartmentId
		WHERE CONVERT(DATE, VisitDate) BETWEEN CONVERT(DATE, @FromDate)
			AND CONVERT(DATE, @ToDate)
			AND VisitType <> 'inpatient' AND AppointmentType IN ('New','followup') AND BillingStatus <> 'returned'
			AND ISNULL(NULLIF(@DepartmentId, 0), vst.DepartmentId) = vst.DepartmentId
			GROUP BY  DATENAME(MONTH, VisitDate)
			,dept.DepartmentName) A 
			Group By MonthName
	END
END