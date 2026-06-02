CREATE PROCEDURE [dbo].[SP_DSB_Home_DashboardStatistics]
AS
/*
FileName: [SP_DSB_Home_DashboardStatistisc]
CreatedBy/date: sudarshan/2017-07-09
Description: to get dashboard statistics of the home dashboards. these are used to fill labels.
Remarks:  
NOTE:  
Change History
S.No.    UpdatedBy/Date                        Remarks
1       sudarshan/2017-07-09	               created
2       sudarshan/2017-07-14	               update
3.      sudarshan/2017-08-16                   update: added types inside appointmentcount.
4.      sud/17Jan'19                           removed returned count from TOtal, Added Transfer count to New 
5.      Sud/4Feb'19                            Segregation of Doctors Count for Consultant, MO, Anaesthetists <need revision for TotalDoctors Count>
*/
BEGIN
	--Rules:-- 
	/*
	 1. Search Criteria is only 'today's OutPatient visits': VisitType='outpatient'  AND CONVERT(DATE,VisitDate)=CONVERT(DATE,GETDATE())
	 2. Total: today's all OPD counts
	 3. New: AppointmentType='new'  or AppointmentType='Transfer'
	 4. Referral: AppointmentType='referral'
	 5. Followup = AppointmentType='followup' 
	 6.Cancelled: (AppointmentType='new' and BillingStatus='cancel')   (other than 'new') can't be cancelled since they're not seen in billing.
	 7.Returned : (AppointmentType='new' and BillingStatus='return') similar as canceled 
	*/
  SELECT * FROM 
    ( Select Count(*) 'TotalPatient' from PAT_Patient ) pat,
	( Select Count(*) 'TodayPatient' from PAT_Patient where CAST(CreatedOn AS DATE) = CAST(GETDATE() AS DATE) ) today_pat,
	( Select Count(*) 'YestardayPatient' from PAT_Patient where CAST(CreatedOn AS DATE) = dateadd(day,-1, cast(getdate() as date) )) yestarday_pat,


	( 
	    --  Select COUNT(*) 'TotalDoctors' from EMP_Employee e,
		--MST_Department d where e.DepartmentId=d.DepartmentId
		--and d.IsAppointmentApplicable=1

		--We're adding EmployeeRoles ('Doctor','M.O.','Anaesthetist'  in TotalDoctorsCount -- needs revision. sud:4Feb'19

		Select  SUM(case when eRole.EmployeeRoleName='Doctor' THEN 1 ELSE 0 END ) AS 'ConsultantsCount',
		  SUM(case when eRole.EmployeeRoleName='M.O.' THEN 1 ELSE 0 END ) AS 'MedicalOfficersCount',
          SUM(case when eRole.EmployeeRoleName='Anaesthetist' THEN 1 ELSE 0 END ) AS 'AnaesthetistsCount',
		  SUM(case when eRole.EmployeeRoleName='Doctor' OR eRole.EmployeeRoleName='M.O.' OR eRole.EmployeeRoleName='Anaesthetist' THEN 1 ELSE 0 END ) AS 'TotalDoctorsCount'
		 from EMP_Employee emp
		LEFT JOIN EMP_EmployeeRole eRole
		ON emp.EmployeeRoleId=eRole.EmployeeRoleId


	 ) docs,
    (Select 
		SUM(1) 'TotalAppts',
		SUM( CASE WHEN (AppointmentType='new' OR AppointmentType='Transfer') THEN 1 ELSE 0 END ) AS 'NewAppts',
		SUM( CASE WHEN AppointmentType='referral' THEN 1 ELSE 0 END ) AS 'ReferralAppts',
		SUM( CASE WHEN AppointmentType='followup' THEN 1 ELSE 0 END ) AS 'FollowUpAppts',
		SUM( CASE WHEN AppointmentType='new' and BillingStatus='cancel' THEN 1 ELSE 0 END ) AS 'CancelAppts'
		--SUM( CASE WHEN AppointmentType='new' and BillingStatus='returned' THEN 1 ELSE 0 END ) AS 'ReturnAppts'--sud:17Jan'19--removed returned from this query, added in separate query below.
		from PAT_PatientVisits where VisitType='outpatient' AND CONVERT(DATE,VisitDate)=CONVERT(DATE,GETDATE())
		and BillingStatus !='returned' -- exclude returned visits..
	) appt,

	 (Select 
		Count(*) 'ReturnAppts'
		FROM PAT_PatientVisits 
		where VisitType='outpatient' AND CONVERT(DATE,VisitDate)=CONVERT(DATE,GETDATE())
		and BillingStatus='returned'
	) retAppts
END