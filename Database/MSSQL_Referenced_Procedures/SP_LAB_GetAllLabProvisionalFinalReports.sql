CREATE PROCEDURE [dbo].[SP_LAB_GetAllLabProvisionalFinalReports]
	@BarcodeNumber int = 0,
	@SampleNumber int = 0,
	@PatientId int = 0,
	@StartDate DateTime = null,
	@EndDate DateTime = null,
	@CategoryList NVARCHAR(400) = '',
	@LabType varchar(50),	
	@IsForLabMaster bit
AS
BEGIN
	Declare @allowProvisionalPrintStr varchar(10)
	Set @allowProvisionalPrintStr = (Select ParameterValue from CORE_CFG_Parameters where LOWER(ParameterGroupName)='lab' and ParameterName='AllowLabReportToPrintOnProvisional');
	Declare @allowProvisionalPrint bit = 0;
	IF(@allowProvisionalPrintStr = 'true' OR @allowProvisionalPrintStr = '1')
	BEGIN 
	Set @allowProvisionalPrint=1
	END

	Declare @CategoryTbl Table(CategoryId int)
	Insert into @CategoryTbl
	Select value from string_split(@CategoryList, ',') where RTRIM(value) <> ''
		Select 
		req.SampleCodeFormatted,
		req.SampleCode,
		Convert(date, req.SampleCreatedOn) as SampleDate,
		req.LabReportId,
		req.VisitType,
		req.RunNumberType as RunNumType,
		report.IsPrinted,
		req.BarCodeNumber,
		req.WardName,
		req.LabTestName,
		req.BillingStatus,
		req.RequisitionId,
		req.LabTestId,
		req.SampleCreatedBy as SampleCollectedBy,
		req.VerifiedBy as VerifiedBy,
		req.IsVerified,
		req.ResultAddedBy as ResultAddedBy,		
		req.HasInsurance,
		req.PrintCount,
		req.PrintedBy,
		pat.PatientId,
		pat.PatientCode,
		pat.DateOfBirth,
		pat.PhoneNumber,
		pat.Gender,
		pat.ShortName as PatientName,		
		emp.FullName as ReportGeneratedBy,
		report.CreatedBy as ReportGeneratedById,		
		test.LabTestCategoryId as LabCategoryId,
		@allowProvisionalPrint as AllowOutpatientWithProvisional,
		CASE LOWER(req.BillingStatus) 
		WHEN 'provisional' then 'provisional' 
		WHEN 'unpaid' then 'paid'
		WHEN 'paid' then 'paid'
		ELSE '' end as BillingStatus
		
		from LAB_TestRequisition req 
		join PAT_Patient pat on req.PatientId = pat.PatientId
		join LAB_TXN_LabReports report on req.LabReportId = report.LabReportId
		join LAB_LabTests test on req.LabTestId = test.LabTestId
		left join EMP_Employee emp on report.CreatedBy = emp.EmployeeId
		where req.OrderStatus = 'report-generated' and 
		(req.BarcodeNumber = (case @BarcodeNumber when 0 then req.BarCodeNumber else @BarcodeNumber end)) and
		(req.SampleCode = (case @SampleNumber when 0 then req.SampleCode else @SampleNumber end)) and
		(req.PatientId = (case @PatientId when 0 then req.PatientId else @PatientId end)) and
		(report.CreatedOn Is Not NULL) and 
		(Convert(date,report.CreatedOn) BETWEEN CONVERT(date, @StartDate) and CONVERT(date, @EndDate)) and 
		(test.LabTestCategoryId In (Select CategoryId from @CategoryTbl)) and 
		(LOWER(req.BillingStatus) IN ('paid','unpaid','provisional')) and
		(req.LabTypeName = (case @IsForLabMaster when 1 then req.LabTypeName else @LabType end))		 
END