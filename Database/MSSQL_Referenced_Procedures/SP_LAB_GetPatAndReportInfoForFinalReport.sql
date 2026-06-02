CREATE PROCEDURE [dbo].[SP_LAB_GetPatAndReportInfoForFinalReport]
  @FromDate DATE=NULL,
  @ToDate DATE=NULL,
  @LabTypeName varchar(100)='op-lab',
  @CategoryIdCsv VARCHAR(200)=NULL
AS 
/*
File: SP_LAB_GetPatAndReportInfoForFinalReport
Created: Anish/Sud:6Sep'21
Description: To get patient info, report info, etc in a date range for Final Reports Grid
NOTE: 
   * Returned  And Cancelled items are excluded from this.
   * Provisional Print restriction (parameterized) is checked here
   * our default labtype is op-lab (it may not be passed from some hospitals, hence pre-assigned it.
Change History:
S.No.  ChangedBy/Date               Remarks
1.    Anish/Sud:6Sep'21             Needed new sp since for final report since previous was processing more data and hence taking more time
2.    Anish/10Sep'21                Correction in Verification Filter, which was missing earlier.
3.    Dev /23Jan' 22                Added new fileds in select query like firstname, lastname, email,isfileuploadedtotelemedicine etc.
4.   Krishna/Dev:14thDec'22			Query optimization 
*/
BEGIN

Declare @allowProvisionalPrintStr varchar(10)
Set @allowProvisionalPrintStr = (Select ParameterValue 
                                 from CORE_CFG_Parameters 
								 where LOWER(ParameterGroupName)='lab' and ParameterName='AllowLabReportToPrintOnProvisional');
Declare @allowProvisionalPrint bit = 0;
IF(@allowProvisionalPrintStr = 'true' OR @allowProvisionalPrintStr = '1')
BEGIN 
  Set @allowProvisionalPrint=1
END

declare @isVerificationEnabled bit;
declare @verificationParam varchar(500) = (Select ParameterValue 
                                           from CORE_CFG_Parameters 
										   where ParameterName='LabReportVerificationNeededB4Print')
set @isVerificationEnabled = (SELECT JSON_VALUE(@verificationParam, '$.EnableVerificationStep'));


--Declare @CategoryIdTbl Table(CategoryId int)
--Insert into @CategoryIdTbl
--Select value from string_split(@CategoryIdCsv, ',') where RTRIM(value) <> ''

SELECT pat.PatientId,
pat.PatientCode, 
pat.DateOfBirth, 
pat.PhoneNumber, 
pat.Gender, 
pat.ShortName AS PatientName,
pat.FirstName,
pat.LastName,
pat.Email,
req.SampleCodeFormatted, 
req.VisitType, 
req.RunNumberType, 
req.IsFileUploadedToTeleMedicine,
ISNULL(rpt.IsPrinted,0) IsPrinted, 
req.BillingStatus,
req.BarCodeNumber, 
rpt.LabReportId AS ReportId, 
req.WardName,
emp.FullName ReportGeneratedBy,
string_agg(req.LabTestName, ',') AS LabTestCSV,
string_agg(req.RequisitionId, ',')  AS LabRequisitionIdCSV,
@allowProvisionalPrint AS AllowOutpatientWithProvisional,
CASE WHEN @allowProvisionalPrint=1 then 1 
     WHEN req.VisitType='inpatient' OR req.VisitType='emergency' THEN 1
     WHEN req.BillingStatus !='provisional' THEN 1
     ELSE 0 END AS IsValidToPrint
FROM LAB_TestRequisition req 
INNER JOIN LAB_LabTests tst on req.LabTestId=tst.LabTestId
INNER JOIN LAB_TestCategory allCat on allCat.TestCategoryId=tst.LabTestCategoryId
INNER JOIN (Select CONVERT(int,value) as 'CategoryId' from string_split(@CategoryIdCsv, ',') where RTRIM(value) <> '') selCat 
on selCat.CategoryId=allCat.TestCategoryId
INNER JOIN PAT_Patient pat on req.PatientId=pat.PatientId
INNER JOIN LAB_TXN_LabReports rpt on req.LabReportId=rpt.LabReportId
LEFT JOIN EMP_Employee emp on rpt.CreatedBy = emp.EmployeeId

Where Convert(Date,rpt.CreatedOn) Between @FromDate and @ToDate
     --checking for default labtypename if it's null
     and ISNULL(req.LabTypeName,'op-lab')= ISNULL(@LabTypeName,'op-lab')
   --and req.BillingStatus <>'cancel'
   --and req.BillingStatus <>'returned'
   and req.BillingStatus not in ('cancel','returned')
   and req.OrderStatus = 'report-generated'
   and (req.IsVerified=1 OR ISNULL(req.IsVerified,0)=@isVerificationEnabled)

Group by pat.PatientId,
    pat.PatientCode, 
    pat.DateOfBirth, 
    pat.PhoneNumber, 
    pat.Gender, 
    pat.ShortName,
    req.SampleCodeFormatted, 
    req.VisitType, 
    req.RunNumberType, 
    rpt.IsPrinted, 
    req.BillingStatus,
    req.BarCodeNumber, 
    rpt.LabReportId, 
    req.WardName, 
    emp.FullName,
	pat.FirstName,
	pat.LastName,
	pat.Email,
	req.IsFileUploadedToTeleMedicine
END