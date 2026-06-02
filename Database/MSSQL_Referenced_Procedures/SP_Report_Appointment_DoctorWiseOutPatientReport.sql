-- =============================================  
-- Author/Date:    Ramavtar/06Aug'18  
-- Description:  get count of outpatient new visit and follow-up visit doctor-wise  
-- =============================================  
CREATE PROCEDURE [dbo].[SP_Report_Appointment_DoctorWiseOutPatientReport]  
@FromDate DATETIME = null,  
@ToDate DATETIME = null  
AS  
/*  
Change History  
S.No.    UpdatedBy/Date          Remarks  
1    Ramavtar/06Aug'18      created the script  
2.     Sud/31-Oct'21                Excluding Inpatient Visits and Returned/Cancelled visits from this report.  
                                    Correction in EmployeeFullName field (for doctor name). 
3.	Krishna,3rdJun'22		changed ProviderId to PerformerId
*/  
BEGIN  
SELECT   
  e.FullName 'DoctorName',  
    SUM(CASE WHEN vis.AppointmentType = 'New' THEN 1 ELSE 0 END) 'NEW',  
    SUM(CASE WHEN vis.AppointmentType = 'followup' THEN 1 ELSE 0 END) 'FOLLOWUP'  
FROM PAT_PatientVisits vis  
JOIN EMP_Employee E ON PerformerId = EmployeeId  
WHERE CONVERT(DATE, vis.VisitDate) BETWEEN @FromDate AND @ToDate  
    --excluding returned and cancelled visits  
  and vis.BillingStatus NOT IN('returned','cancel')  
  --exclude inpatient visits..  
  and vis.VisitType !='inpatient'  
GROUP BY vis.PerformerId, e.FullName  
ORDER BY vis.PerformerId  
END