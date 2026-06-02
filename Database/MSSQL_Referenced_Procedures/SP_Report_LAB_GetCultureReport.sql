CREATE PROCEDURE [dbo].[SP_Report_LAB_GetCultureReport] --SP_Report_LAB_GetCultureReport '2020-02-06','2021-07-15'
    ( @FromDate DATETIME = NULL,
      @ToDate DATETIME = NULL)
AS
/*
 File: SP_Report_LAB_GetCultureReport
 Description: To get details of Culture test of patients between selected dates
 Conditions/Checks: 
        
 Change History:
 S.No.    ChangeDate/By              Remarks
 1.      26Jul'21/Anjana          Initial Draft 
 2.     30 Sept'21/Anish        Verification Filter and other filters added 
*/
BEGIN
    declare @isVerificationEnabled bit;
    declare @verificationParam varchar(500) = (Select ParameterValue from CORE_CFG_Parameters where ParameterName='LabReportVerificationNeededB4Print')
    set @isVerificationEnabled = (SELECT JSON_VALUE(@verificationParam, '$.EnableVerificationStep'));

    --for positive culture test report
    select 
    max(tblPositiveData.ShortName) as ShortName,
    max(tblPositiveData.PatientCode) as PatientCode,
    max(tblPositiveData.Age) as Age,
    max(tblPositiveData.Gender) as Gender,
    max(tblPositiveData.SampleCodeFormatted) as SampleCodeFormatted,
    max(tblPositiveData.Finding) as Finding,
    max(tblPositiveData.[Sensitivity]) as [Sensitivity],
    max(tblPositiveData.Resistant) as Resistant,
    max(tblPositiveData.[Intermediate]) as [Intermediate],
    max(tblPositiveData.ResultDate) as ResultDate,
    max(tblPositiveData.LabTestSpecimen) as LabTestSpecimen
    from (select * from (Select 
    max(pat.ShortName) as ShortName,
    pat.PatientId,
    pat.PatientCode,
    max(pat.Age) as Age,
    max(pat.Gender) as Gender,
    req.SampleCodeFormatted,
    max(case when res.ComponentName IN ('Result','Result C/S') then res.[Value] end) Finding,
    (case when max(res.[Value]) = 'Sensitive' then String_Agg(res.ComponentName , ', ') end) as [Sensitivity],
    (case when max(res.[Value]) = 'Resistant' then String_Agg(res.ComponentName , ', ') end) as Resistant,
    (case when max(res.[Value]) = 'Intermediate' then String_Agg(res.ComponentName , ', ') end) as [Intermediate],
    max(res.CreatedOn) as ResultDate,
    req.RequisitionId as RequisitionId,
    max(req.LabTestSpecimen) as LabTestSpecimen
    from PAT_Patient pat
    join LAB_TestRequisition req on pat.PatientId = req.PatientId
    join LAB_TXN_TestComponentResult res on req.RequisitionId = res.RequisitionId
    join Lab_ReportTemplate template on req.ReportTemplateID = template.ReportTemplateID
    where Convert(Date,req.OrderDateTime) BETWEEN (CONVERT(Date, @FromDate)) 
    and CONVERT(Date, @ToDate) and res.IsActive = 1 and req.IsActive = 1 and res.IsNegativeResult = 0 
    and template.TemplateType='culture' 
    and (req.IsVerified=1 OR ISNULL(req.IsVerified,0)=@isVerificationEnabled)
    group by pat.PatientId, pat.PatientCode,req.SampleCodeFormatted, req.RequisitionId, res.[Value]
    ) as tblinnerPositiveData) as tblPositiveData
    group by tblPositiveData.RequisitionId

    union all
    --for negative culture test report
    select 
    max(tblNegativeData.ShortName) as ShortName,
    max(tblNegativeData.PatientCode) as PatientCode,
    max(tblNegativeData.Age) as Age,
    max(tblNegativeData.Gender) as Gender,
    max(tblNegativeData.SampleCodeFormatted) as SampleCodeFormatted,
    max(tblNegativeData.Finding) as Finding,
    max(tblNegativeData.[Sensitivity]) as [Sensitivity],
    max(tblNegativeData.Resistant) as Resistant,
    max(tblNegativeData.[Intermediate]) as [Intermediate],
    max(tblNegativeData.ResultDate) as ResultDate,
    max(tblNegativeData.LabTestSpecimen) as LabTestSpecimen
    from (select * from (Select 
    max(pat.ShortName) as ShortName,
    pat.PatientId,
    pat.PatientCode,
    max(pat.Age) as Age,
    max(pat.Gender) as Gender,
    req.SampleCodeFormatted,
    max(case when res.ComponentName = 'Negative Result' then res.NegativeResultText end) Finding,
    max(case when res.ComponentName ='Negative Result' then res.[Value] end) as [Sensitivity],
    max(case when res.ComponentName ='Negative Result' then res.[Value] end) as Resistant,
    max(case when res.ComponentName ='Negative Result' then res.[Value] end) as [Intermediate],
    max(res.CreatedOn) as ResultDate,
    req.RequisitionId as RequisitionId,
    max(req.LabTestSpecimen) as LabTestSpecimen
    from PAT_Patient pat
    join LAB_TestRequisition req on pat.PatientId = req.PatientId
    join LAB_TXN_TestComponentResult res on req.RequisitionId = res.RequisitionId
    join Lab_ReportTemplate template on req.ReportTemplateID = template.ReportTemplateID
    where Convert(Date,req.OrderDateTime) BETWEEN (CONVERT(Date, @FromDate)) and CONVERT(Date, @ToDate) 
    and res.IsActive = 1 and req.IsActive = 1 and res.IsNegativeResult = 1 and template.TemplateType='culture' 
    and (req.IsVerified=1 OR ISNULL(req.IsVerified,0)=@isVerificationEnabled)
    group by pat.PatientId, pat.PatientCode, req.SampleCodeFormatted, req.RequisitionId, res.[Value]
    ) as tblinnerNegativeData) as tblNegativeData
    group by tblNegativeData.RequisitionId

END