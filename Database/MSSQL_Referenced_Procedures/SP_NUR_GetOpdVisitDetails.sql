CREATE PROCEDURE [dbo].[SP_NUR_GetOpdVisitDetails]
		@FromDate DATE=null ,
		@ToDate DATE=null

AS
/*
FileName: [SP_NUR_GetOpdVisitDetails]
CreatedBy/date: Anjana/2020-06-23
Description: to get list of outpatient 
Note: Renamed from: SP_GetVisitListForOPD
Change History
S.No.    UpdatedBy/Date                        Remarks
1.      Anjana/2020-06-23					Initial Draft
2.      Anjana/2020-07-09					Updated HasVitals to IsTriaged for OPD Triage
3.		Krishna/2Jun'22						changed ProviderName to PerformerName, ProviderId to PerformerId 
4.      Santosh/23April'23                  Read Department and SchemeName
5.      Krishna/Sud:25Apr'23                Changed IsTriaged Condition, Dropped old sp 'SP_GetVisitListForOPD' and Recreated this.
6.      Bibek: 21May'23                     add filter VisitStatus = 'initiated'
7.      Santosh/10July"23                   Add filter VisitStatus = 'checkedin'
*/
BEGIN 
SELECT
  pat.PatientId,
  pat.PatientCode,
  pat.ShortName,
  pat.DateOfBirth,
  pat.PhoneNumber,
  pat.Gender,
  pat.Address,
  pat.Age,
  vis.VisitDate,
  vis.VisitTime,
  vis.VisitType,
  vis.PatientVisitId,
  vis.PerformerName,
  vis.PerformerId,
  vis.AppointmentType,
  vis.VisitStatus,
  vis.IsTriaged 'IsTriaged',
  dept.DepartmentName,
  sch.SchemeName,
  dept.DepartmentId

FROM 
 PAT_Patient pat 
     INNER JOIN
 PAT_PatientVisits vis
    ON pat.PatientId= vis.PatientId	
  INNER JOIN 
  MST_Department AS dept
  ON dept.DepartmentId = vis.DepartmentId
  INNER JOIN 
  BIL_CFG_Scheme AS sch
  ON sch.SchemeId = vis.SchemeId

WHERE  
vis.VisitType = 'outpatient'
	 AND vis.BillingStatus != 'cancel'
	 AND vis.BillingStatus != 'returned'
	 AND( vis.VisitStatus = 'initiated'
	 OR vis.VisitStatus = 'checkedin')
AND Convert(Date, vis.CreatedOn) between @FromDate AND @ToDate
END