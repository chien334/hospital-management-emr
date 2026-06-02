CREATE PROCEDURE [dbo].[SP_Report_Appointment_DepartmentWiseAppointmentReport] 
    @FromDate DATE =NULL,
	@ToDate DATE = NULL,
	@DepartmentId int = null,
	@Gender Varchar(20)=null
AS
/*
FileName: [SP_Report_Appointment_DepartmentWiseAppointmentReport]
CreatedBy/date: 
Description: To get departments total appointments(new,followup,referral) on a given date range
Remarks:    
Change History
S.No.    UpdatedBy/Date            Remarks
1      Sud:21Sep'21               Complete rewrite as per new requirement to show sum in the given date range
*/
BEGIN

Select DepartmentId, ISNULL(DepartmentName,'Not Assigned') AS DepartmentName, 
	ISNULL([New],0) 'NewAppointment',
	ISNULL([followup],0) 'Followup',
	ISNULL([Referral],0) 'Referral',
	ISNULL([New],0) + ISNULL([followup],0) + ISNULL([Referral],0)  'TotalAppointments'

	from 
	(
	Select dept.DepartmentId, dept.DepartmentName, vis.AppointmentType, Count(*) 'AppointmentCount'
	FROM PAT_PatientVisits VIS
	INNER JOIN PAT_Patient pat
	  on vis.PatientId = pat.PatientId
	LEFT JOIN MST_Department dept ON VIS.DepartmentId = DEPT.DepartmentId
	
	WHERE Convert(Date,VIS.VisitDate) BETWEEN @FromDate AND @ToDate AND 
	   --make deptid= null if it came as Zero---
	   ISNULL(NULLIF(@DepartmentId,0),vis.DepartmentId)=vis.DepartmentId

	and vis.BillingStatus NOT IN('returned','cancel')
	--exclude inpatient visits..
	and vis.VisitType !='inpatient'

	and ISNULL(NULLIF(@Gender,'all'),pat.Gender)=pat.Gender

	GROUP by dept.DepartmentId,vis.AppointmentType, dept.DepartmentName

	) tbl
	pivot (SUM(AppointmentCount) for AppointmentType IN ([New],[followup],[Referral])) as pvtData

	order by DepartmentName
END