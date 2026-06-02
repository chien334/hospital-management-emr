CREATE PROCEDURE [dbo].[SP_Report_Appointment_RankwiseDailyAppointmentReport]   
    @FromDate Date='',
    @ToDate Date='',
    @Membership VARCHAR(1000) = '',
    @Rank VARCHAR(500) = '',
    @AppointmentType varchar(100) = null
AS
/*  
FileName: [SP_Report_Appointment_RankwiseDailyAppointmentReport]
Example: exec [dbo].[SP_Report_Appointment_RankwiseDailyAppointmentReport] '2022-11-01','2022-12-29','6,8','',''
CreatedBy/date: Rusha/2023-01-09  
Description: Rankwise Daily Appointment Report  
Remarks:      
Change History  
S.No.    UpdatedBy/Date                        Remarks  
1.        Rusha/ 09thJan'23                    Initial draft
*/
BEGIN
    SELECT
    CONVERT(datetime, CONVERT(date, vis.VisitDate)) + CONVERT(datetime, VisitTime) as 'Date',
    pat.PatientCode,
    ISNULL(pat.Rank, '') as Rank,
    mem.MembershipTypeName as Membership,
    pat.ShortName AS PatientName,
    pat.Address,
    pat.PhoneNumber,
    pat.Age,
    pat.Gender,
    ISNULL(dept.DepartmentName, 'Not Assigned') AS DepartmentName,
    vis.AppointmentType,
    vis.VisitType,
    vis.VisitStatus 
FROM
  PAT_PatientVisits AS vis 
  INNER JOIN PAT_Patient pat ON vis.PatientId = pat.PatientId 
  INNER JOIN MST_CountrySubDivision dist on pat.CountrySubDivisionId = dist.CountrySubDivisionId 
  left join MST_Department dept on vis.DepartmentId = dept.DepartmentId 
  left join EMP_Employee emp on emp.EmployeeId = vis.PerformerId 
  INNER JOIN pat_cfg_membershiptype mem
         ON pat.membershiptypeid = mem.membershiptypeid
  INNER JOIN (SELECT value AS 'MembershipTypeId'
              FROM   String_split(@Membership, ',')) membership
         ON mem.membershiptypeid = membership.membershiptypeid
WHERE
  CONVERT(date, vis.VisitDate) BETWEEN @FromDate AND @ToDate
  and vis.VisitType != 'inpatient' --excluding inpatient visits (those can be seen from admission reports)  
  and vis.AppointmentType LIKE '%' + ISNULL(@AppointmentType, '') + '%'
  AND(pat.Rank IN (select value as 'Ranks' from string_split(@Rank, ',')) OR @Rank = '')
  AND vis.BillingStatus NOT IN('cancel', 'returned') --exclude cancelled and returned visits.  
ORDER BY
  CONVERT(
    datetime,
    CONVERT(date, vis.VisitDate)
  ) + CONVERT(datetime, vis.VisitTime) DESC
END