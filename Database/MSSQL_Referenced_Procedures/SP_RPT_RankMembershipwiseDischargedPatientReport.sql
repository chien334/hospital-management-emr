CREATE PROCEDURE SP_RPT_RankMembershipwiseDischargedPatientReport   
    @FromDate  DATE = NULL,  
    @ToDate DATE = NULL,  
    @MembershiptTypeIds  VARCHAR(1000) ='',  
    @Rank VARCHAR(500)= ''  
  
AS  
/*
[SP_RPT_RankMembershipwiseDischargedPatientReport] '2023-1-12','2023-1-12', '1,2,3','SI,CON'
FileName: [SP_RPT_RankMembershipwiseDischargedPatientReport]
CreatedBy/date:Santosh/2023-1-13
Description: .
Remarks:    A
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Santosh/2023-1-13                created the script for Rank-Membership wise Discharged Patient Report
*/
BEGIN  
  
SELECT   
pat.PatientCode AS HospitalNo,  
visit.VisitCode AS IPNumber,  
pat.Rank,  
memtype.MembershipTypeName AS Membership,  
pat.ShortName AS PatientName,   
pat.Age,  
pat.Gender,  
pat.Age + '/' + pat.Gender AS 'AgeSex',  
pat.Address,  
pat.PhoneNumber,  
adm.AdmissionDate,  
adm.DischargeDate AS DischargedDate  
  
FROM PAT_Patient AS pat  
INNER JOIN PAT_PatientVisits AS visit ON pat.PatientId = visit.PatientId  
INNER JOIN PAT_CFG_MembershipType AS memtype ON pat.MembershipTypeId = memtype.MembershipTypeId   
INNER JOIN ADT_PatientAdmission AS adm ON visit.PatientVisitId = adm.PatientVisitId  
where adm.AdmissionStatus ='discharged' AND pat.Rank IS NOT NULL  and CONVERT(DATE,visit.VisitDate) BETWEEN @FromDate and @ToDate   
AND (  
      pat.Rank IN (  
        SELECT value  
        FROM STRING_SPLIT(@Rank, ',')  
        )  
      OR @Rank = ''  
      )  
    AND (  
      memtype.MembershipTypeId IN (  
        SELECT value  
        FROM STRING_SPLIT(@MembershiptTypeIds, ',')  
        )  
      OR @MembershiptTypeIds = ''  
      )  
END