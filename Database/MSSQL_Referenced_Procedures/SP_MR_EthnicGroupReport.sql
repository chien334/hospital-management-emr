CREATE PROCEDURE [dbo].[SP_MR_EthnicGroupReport]
   @FromDate Date,
   @ToDate Date
AS
/*
FileName: EXEC SP_MR_EthnicGroupReport <FromDate,ToDate> 
CreatedBy/date: Bikesh:22Aug2023  
Usage Eg: SP_MR_EthnicGroupReport
Description: 
   To get EthnicGroup wise Appointment countof male and female 
Remarks:    
   > Count All male/female on the basis of FromTo Date filter grouped by ethinic group
Change History
S.No.    UpdatedBy/Date                        Remarks
1        Bikesh/9Sept'23                   Initial Draft
2		 Krishna/18thSept'23			   Fix for inpatients visit, need discharged patients only
3		 Krishna/16thOct'23				   Rewrite the script according to new report format.
*/
BEGIN  
DECLARE @ChildAgeInDays INT = (SELECT MaxAgeInDays FROM CORE_MST_AgeClassification 
							WHERE ReportType = 'DepartmentWiseStatReport' AND AgeName = 'Child')

SELECT   
	ISNULL(pat.EthnicGroup,'Others') AS 'EthnicGroup',
	SUM(IIF((DATEDIFF(DAY,pat.DateOfBirth,adm.AdmissionDate) <= @ChildAgeInDays) AND pat.Gender = 'Male',1, 0)) AS 'Total_MaleChildren',
	SUM(IIF((DATEDIFF(DAY,pat.DateOfBirth,adm.AdmissionDate) <= @ChildAgeInDays) AND pat.Gender = 'Female',1, 0)) AS 'Total_FemaleChildren',
	SUM(IIF((DATEDIFF(DAY,pat.DateOfBirth,adm.AdmissionDate) > @ChildAgeInDays) AND pat.Gender = 'Male',1, 0)) AS 'Total_MaleCount',
	SUM(IIF((DATEDIFF(DAY,pat.DateOfBirth,adm.AdmissionDate) > @ChildAgeInDays) AND pat.Gender = 'Female',1, 0)) AS 'Total_FemaleCount',
	ISNULL(SUM(1),0) AS 'Total'
FROM (SELECT VisitType, BillingStatus, PatientVisitId, VisitDate, PatientId 
		FROM PAT_PatientVisits WHERE VisitType = 'inpatient'
		AND BillingStatus NOT IN('cancel','returned')) AS vis  
INNER JOIN (SELECT PatientVisitId, DischargeDate, AdmissionDate FROM ADT_PatientAdmission 
				WHERE AdmissionStatus = 'discharged') adm 
	ON vis.PatientVisitId = adm.PatientVisitId
INNER JOIN PAT_Patient pat ON vis.PatientId = pat.PatientId
WHERE CONVERT(date, adm.DischargeDate) BETWEEN @FromDate  AND  @ToDate   
GROUP BY ISNULL (pat.EthnicGroup, 'Others')

SELECT
	ISNULL (pat.EthnicGroup, 'Others') AS 'EthnicGroup',
	SUM(IIF((DATEDIFF(DAY,pat.DateOfBirth,vis.VisitDate) <= @ChildAgeInDays) AND pat.Gender = 'Male' AND vis.AppointmentType = 'New' AND vis.RowNum = 1,1, 0)) AS 'Total_MaleChildrenNew',
	SUM(IIF((DATEDIFF(DAY,pat.DateOfBirth,vis.VisitDate) <= @ChildAgeInDays) AND pat.Gender = 'Female' AND vis.AppointmentType = 'New' AND vis.RowNum = 1,1, 0)) AS 'Total_FemaleChildrenNew',
	SUM(IIF((DATEDIFF(DAY,pat.DateOfBirth,vis.VisitDate) <= @ChildAgeInDays) AND pat.Gender = 'Male' AND vis.AppointmentType = 'New' AND vis.RowNum > 1,1, 0)) AS 'Total_MaleChildrenOld',
	SUM(IIF((DATEDIFF(DAY,pat.DateOfBirth,vis.VisitDate) <= @ChildAgeInDays) AND pat.Gender = 'Female' AND vis.AppointmentType = 'New' AND vis.RowNum > 1,1, 0)) AS 'Total_FemaleChildrenOld',
	SUM(IIF((DATEDIFF(DAY,pat.DateOfBirth,vis.VisitDate) <= @ChildAgeInDays) AND pat.Gender = 'Male' AND vis.AppointmentType = 'followup',1, 0)) AS 'Total_MaleChildrenFollowup',
	SUM(IIF((DATEDIFF(DAY,pat.DateOfBirth,vis.VisitDate) <= @ChildAgeInDays) AND pat.Gender = 'Female' AND vis.AppointmentType = 'followup',1, 0)) AS 'Total_FemaleChildrenFollowup',
	SUM(IIF((DATEDIFF(DAY,pat.DateOfBirth,vis.VisitDate) > @ChildAgeInDays) AND pat.Gender = 'Male' AND vis.AppointmentType = 'New' AND vis.RowNum = 1,1, 0)) AS 'Total_MaleNew',
	SUM(IIF((DATEDIFF(DAY,pat.DateOfBirth,vis.VisitDate) > @ChildAgeInDays) AND pat.Gender = 'Female' AND vis.AppointmentType = 'New' AND vis.RowNum = 1,1, 0)) AS 'Total_FemaleNew',
	SUM(IIF((DATEDIFF(DAY,pat.DateOfBirth,vis.VisitDate) > @ChildAgeInDays) AND pat.Gender = 'Male' AND vis.AppointmentType = 'New' AND vis.RowNum > 1,1, 0)) AS 'Total_MaleOld',
	SUM(IIF((DATEDIFF(DAY,pat.DateOfBirth,vis.VisitDate) > @ChildAgeInDays) AND pat.Gender = 'Female' AND vis.AppointmentType = 'New' AND vis.RowNum > 1,1, 0)) AS 'Total_FemaleOld',
	SUM(IIF((DATEDIFF(DAY,pat.DateOfBirth,vis.VisitDate) > @ChildAgeInDays) AND pat.Gender = 'Male' AND vis.AppointmentType = 'followup',1, 0)) AS 'Total_MaleFollowup',
	SUM(IIF((DATEDIFF(DAY,pat.DateOfBirth,vis.VisitDate) > @ChildAgeInDays) AND pat.Gender = 'Female' AND vis.AppointmentType = 'followup',1, 0)) AS 'Total_FemaleFollowup',
	ISNULL(SUM(1),0) AS 'Total'
FROM (SELECT VisitType, PatientVisitId, VisitDate, PatientId, AppointmentType, 
	   ROW_NUMBER() OVER(Partition BY PatientId, AppointmentType ORDER BY PatientVisitId) AS 'RowNum'
	  FROM PAT_PatientVisits
	  WHERE VisitType != 'inpatient' AND BillingStatus NOT IN('cancel','returned')
	  AND AppointmentType NOT IN('transfer', 'Referral')) AS vis  
INNER JOIN PAT_Patient pat ON vis.PatientId = pat.PatientId  
WHERE CONVERT(date, vis.VisitDate) BETWEEN @FromDate  AND  @ToDate   
GROUP BY ISNULL (pat.EthnicGroup, 'Others')
End