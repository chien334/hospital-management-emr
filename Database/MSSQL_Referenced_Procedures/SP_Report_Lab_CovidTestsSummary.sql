--Altering SP_Report_Lab_CovidTestsSummary SP
--changed ProviderName to PrescriberName
CREATE PROCEDURE [dbo].[SP_Report_Lab_CovidTestsSummary]   
 ( @FromDate DATETIME = NULL,  
 @ToDate DATETIME = NULL,  
 @TestName varchar(200) = NULL,  
 @CountrySubDivisionId int = null)  
AS  
  
/************************************************************************  
FileName: [SP_Report_Lab_CovidTestsSummary]  
CreatedBy/date: Anjana/22June,2021  
Description: Get covid tests summary details  
S.No.    UpdatedBy/Date                        Remarks  
1        Anjana/22June,2021     Initial Draft  
2        pratik/5thSep,2021                 Positive and negative followup cases from LAB_TestRequisition  
3  Anish/12Sept 2021     replace empty provider id by 'new'  
*************************************************************************/  
  
BEGIN  
 declare @isVerificationEnabled bit;  
    declare @verificationParam varchar(500) = (Select ParameterValue from CORE_CFG_Parameters where ParameterName='LabReportVerificationNeededB4Print')  
    set @isVerificationEnabled = (SELECT JSON_VALUE(@verificationParam, '$.EnableVerificationStep'));  
  
 If(@FromDate IS NOT NULL OR @ToDate IS NOT NULL)  
 BEGIN  
  
 IF(@CountrySubDivisionId = 0)  
  BEGIN  
   SET @CountrySubDivisionId = null  
  END  
   
 Select  
 subDiv.CountrySubDivisionName as District,  
 Count(*) TotalCases,  
 Sum( Case when lower([Value]) = 'negative' and ISNULL(req.PrescriberName,'new') like '%new%' then 1 else 0 end) as NewNegativeCases,  
 Sum( Case when lower([Value]) = 'positive' and ISNULL(req.PrescriberName,'new') like '%new%' then 1 else 0 end) as NewPositiveCases,  
 Sum( Case when lower([Value]) = 'negative' and replace(req.PrescriberName,'-','') like '%followup%' then 1 else 0 end) as FollowupNegativeCases,  
 Sum( Case when lower([Value]) = 'positive' and replace(PrescriberName,'-','') like '%followup%' then 1 else 0 end) as FollowupPositiveCases  
  
 from LAB_TestRequisition req  
 join LAB_TXN_TestComponentResult result on req.RequisitionId = result.RequisitionId  
 join PAT_Patient pat on req.PatientId = pat.PatientId  
 left join MST_CountrySubDivision subDiv on pat.CountrySubDivisionId = subDiv.CountrySubDivisionId  
 join LAB_LabTests test on req.LabTestId = test.LabTestId  
    where test.LabTestName = @TestName and req.IsActive = 1 and result.IsActive=1 and Convert(date,req.OrderDateTime) BETWEEN CONVERT(date, @FromDate) AND CONVERT(date, @ToDate)  
 AND ISNULL(@CountrySubDivisionId,subDiv.CountrySubDivisionId)=subDiv.CountrySubDivisionId and result.[Value] IN ('negative','positive')  
 AND (req.IsVerified=1 OR ISNULL(req.IsVerified,0)=@isVerificationEnabled)   
  group by subDiv.CountrySubDivisionName  
 END  
END