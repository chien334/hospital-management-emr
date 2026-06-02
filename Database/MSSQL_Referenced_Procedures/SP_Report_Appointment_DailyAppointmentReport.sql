CREATE PROCEDURE [dbo].[SP_Report_Appointment_DailyAppointmentReport]   
 @FromDate Date=null,  
 @ToDate Date=null,  
 @Doctor_Name varchar(100) = null,  
 @AppointmentType varchar(100) = null  
AS  
/*  
FileName: [SP_Report_Appointment_DailyAppointmentReport]  
CreatedBy/date: Umed/2017-06-08  
Description: to get Details such as Patient Name , Appointment type, Appointment Status, along with doctor name between the Given Dates  
Remarks:      
Change History  
S.No.    UpdatedBy/Date                        Remarks  
5  Rusha/2019-18-06     Updated of script according to provider name and appointment type  
6       Shankar/2020-19-02                  Added middle name to the patients name  
7.      Sud/14Jun'20                        PatientName taking from ShortName field of Pat_Patient Table  
8.      Sud:21Sep'21                        Adding DepartmentName, DistrictName in Select Result.  
                                            Refactoring of where clause   
  
9.      Prem:26 april'22          Adding Ins_HasInsurance in Select Result. 
10.		Krishna,3rdJun'22		  changed ProviderId to PerformerId
                                              
*/  
BEGIN  
    SELECT  
 CONVERT(datetime, CONVERT(date, vis.VisitDate)) + CONVERT(datetime, VisitTime) as 'Date',  
  pat.PatientCode,  
  pat.ShortName AS Patient_Name,  
        pat.PhoneNumber,pat.Age,  
  pat.Gender,  
  pat.Ins_HasInsurance,  
  dist.CountrySubDivisionName 'DistrictName',  
  ISNULL(dept.DepartmentName,'Not Assigned') AS DepartmentName,  
  vis.AppointmentType,vis.VisitType,  
  emp.FullName AS Doctor_Name,vis.PerformerId,  
  vis.VisitStatus  
FROM PAT_PatientVisits AS vis  
 INNER JOIN PAT_Patient pat ON vis.PatientId = pat.PatientId  
 INNER JOIN MST_CountrySubDivision dist on pat.CountrySubDivisionId=dist.CountrySubDivisionId  
 left join MST_Department dept on vis.DepartmentId=dept.DepartmentId  
 left join EMP_Employee emp on emp.EmployeeId=vis.PerformerId  
 WHERE CONVERT(date, vis.VisitDate) BETWEEN @FromDate  AND  @ToDate   
 and vis.VisitType !='inpatient' --excluding inpatient visits (those can be seen from admission reports)  
 and ISNULL(emp.FullName,'') LIKE '%' + ISNULL(@Doctor_Name, '') + '%' and  
   vis.AppointmentType LIKE '%' + ISNULL(@AppointmentType, '') + '%'  
    AND vis.BillingStatus NOT  IN('cancel','returned')--exclude cancelled and returned visits.  
 ORDER BY CONVERT(datetime, CONVERT(date, vis.VisitDate)) + CONVERT(datetime, vis.VisitTime) DESC  
  
END