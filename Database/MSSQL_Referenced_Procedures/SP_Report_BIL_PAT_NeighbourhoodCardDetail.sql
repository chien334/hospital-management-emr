--Altering SP_Report_BIL_PAT_NeighbourhoodCardDetail SP
--changed RequestedBy to PrescriberName  
CREATE PROCEDURE [dbo].[SP_Report_BIL_PAT_NeighbourhoodCardDetail]      
 @FromDate datetime=null,  
 @ToDate datetime=null    
AS  
/*  
FileName: [SP_Report_BIL_PAT_NeighbourhoodCardDetail]  
CreatedBy/date: Rusha/05-31-2019  
Description: To get the Details of Breakage Items From different Ward   
Remarks:      
Change History  
S.No.    UpdatedBy/Date                        Remarks  
1.  Rusha/05-31-2019        get details of patient for neighbourhood card report 
2.	Krishna/9thJun'22		changed RequestedBy to PrescriberName
*/  
  
BEGIN  
  IF ((@FromDate IS NOT NULL) and (@ToDate IS NOT NULL))  
  BEGIN  
   SELECT CONVERT(date,ncd.CreatedOn) AS IssuedDate,ncd.PatientId, ncd.PatientCode AS HospitalNo,   
   CONCAT_WS(' ',pat.FirstName, pat.MiddleName,pat.LastName) AS PatientName,  
   pat.Gender, pat.DateOfBirth,CONCAT_WS(' ',emp.FirstName,emp.MiddleName,emp.LastName) AS PrescriberName  
   FROM PAT_NeighbourhoodCardDetail AS ncd  
   JOIN PAT_Patient AS pat ON pat.PatientId = ncd.PatientId  
   JOIN EMP_Employee AS emp ON emp.EmployeeId = ncd.CreatedBy  
   WHERE CONVERT(date, ncd.CreatedOn) BETWEEN ISNULL(@FromDate,GETDATE())  AND ISNULL(@ToDate,GETDATE())+1  
  END   
END