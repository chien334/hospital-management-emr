CREATE PROCEDURE [dbo].[SP_Report_LAB_GetHIVTestDetails] --SP_Report_LAB_GetHIVTestDetails '2020-02-06','2020-03-06'
    ( @FromDate DATETIME = NULL,
      @ToDate DATETIME = NULL)
AS
/*
 File: SP_Report_LAB_GetHIVTestDetails
 Description: To get details of HIV test of patients between selected dates
 Conditions/Checks: 
        
 Change History:
 S.No.    ChangeDate/By              Remarks
 1.      25Jul'21/Anjana          Initial Draft 
 2.      3 Sept/Anish             Filters Added with verification Parameter
 3.      16 Nov/Dev Narayan       Change procedure for getting labtypename
*/
BEGIN
    declare @isVerificationEnabled bit;
    declare @verificationParam varchar(500) = (Select ParameterValue from CORE_CFG_Parameters where ParameterName='LabReportVerificationNeededB4Print')
    set @isVerificationEnabled = (SELECT JSON_VALUE(@verificationParam, '$.EnableVerificationStep'));

    Select allData.RequisitionId,allData.ShortName,allData.PatientCode,
  max(allData.Age) 'Age',
  max(allData.Gender) 'Gender',
  allData.Method, 
  allData.[Value], 
    allData.[Address], 
  allData.SampleCodeFormatted 'SampleCode', 
  allData.ComponentName, 
  Convert(Date,allData.ResultDate) 'ResultDate',
  allData.LabTypeName
    from (Select 
    pat.ShortName,
    pat.PatientCode,
    pat.Age,
    pat.Gender,
    pat.[Address],
    req.SampleCodeFormatted,
    res.ComponentName,
    res.[Value],
    res.Method,
    req.RequisitionId,
    res.CreatedOn as ResultDate,
	req.LabTypeName
    from PAT_Patient pat
    join LAB_TestRequisition req on pat.PatientId = req.PatientId
    join LAB_TXN_TestComponentResult res on req.RequisitionId = res.RequisitionId
    where res.ComponentName = 'HIV' and res.IsActive=1 and req.IsActive=1 
    and (req.IsVerified=1 OR ISNULL(req.IsVerified,0)=@isVerificationEnabled)
    and Convert(date,req.OrderDateTime) BETWEEN (CONVERT(date, @FromDate)) and CONVERT(date, @ToDate)
    ) allData group by allData.RequisitionId, allData.Method, allData.[Value], allData.[Address],
    allData.ShortName,allData.PatientCode, allData.SampleCodeFormatted, allData.ComponentName,Convert(Date,allData.ResultDate),allData.LabTypeName
	order by Convert(Date,allData.ResultDate) desc
END