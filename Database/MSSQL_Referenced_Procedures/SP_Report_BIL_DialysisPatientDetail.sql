--Altering SP_Report_BIL_DialysisPatientDetail SP
--RequestedBy changed to PrescriberName
CREATE PROCEDURE [dbo].[SP_Report_BIL_DialysisPatientDetail]      
 @FromDate datetime=null,  
 @ToDate datetime=null    
AS  
/*  
FileName: [SP_Report_BIL_PAT_NeighbourhoodCardDetail]  
CreatedBy/date: Rusha/05-31-2019  
Description: T oget details report of dialysis patient  
Remarks:      
Change History  
S.No.    UpdatedBy/Date                        Remarks  
1.  Rusha/06-03-2019        get details report of dialysis patient 
2.	Krishna/8thJun'22		RequestedBy changed to PrescriberName
*/  
  
BEGIN  
  IF ((@FromDate IS NOT NULL) and (@ToDate IS NOT NULL))  
  BEGIN  
   SELECT CONVERT(date,pat.CreatedOn) AS [Date],pat.DialysisCode, pat.PatientCode AS HospitalNo,   
   CONCAT_WS(' ',pat.FirstName, pat.MiddleName,pat.LastName) AS PatientName,  
   pat.age+ '/' + substring(pat.Gender, 1, 1) as 'Gender', pat.Age, CONCAT_WS(' ',emp.FirstName,emp.MiddleName,emp.LastName) AS PrescriberName  
   FROM PAT_Patient AS pat   
   join EMP_Employee as emp on emp.EmployeeId = pat.CreatedBy    
   WHERE pat.DialysisCode is not null AND CONVERT(date, pat.CreatedOn) BETWEEN ISNULL  
  
(@FromDate,GETDATE())  AND ISNULL(@ToDate,GETDATE())+1  
  END   
END