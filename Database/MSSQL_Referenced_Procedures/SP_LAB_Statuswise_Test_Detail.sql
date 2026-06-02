-- =============================================
-- Author:		<Anish Bhattarai>
-- Create date: <3 August 2020>
-- Description:	<Get the test requisition detail and its status>
--Modified Column Name : <8 August 2020>
--Co-Author:          <Dev Narayan Chaudhary>
--Modified Date:      <13 Sep 2021>
--Description:        <Added status filter>
-- =============================================
CREATE PROCEDURE [dbo].[SP_LAB_Statuswise_Test_Detail] 
( @FromDate DATETIME = NULL,
      @ToDate DATETIME = NULL,
	  @OrderStatus varchar(200) = NULL)
AS
BEGIN
	Declare @OrderStatusList Table(OrderStatus varchar(20))
	Insert into @OrderStatusList
	Select value from string_split(@OrderStatus,',') where RTRIM(value) <>''
If(@FromDate IS NOT NULL OR @ToDate IS NOT NULL)
BEGIN
SELECT OrderDateTime 'RequestedOn', pat.ShortName 'PatientName',pat.PatientCode 'HospitalNo',
Convert(Varchar(10),pat.Age)+'/'+ pat.Gender 'AgeSex',
CASE WHEN WardName='outpatient' THEN 'OPD'
ELSE UPPER(wardname) END AS  WardName,
CASE WHEN req.PrescriberName is null THEN 'SELF' 
ELSE req.PrescriberName END AS 'ReferredBy',
LabTestName,SampleCodeFormatted 'RunNo',
CASE 
WHEN req.OrderStatus='active' then 'Sample Not Collected' 
WHEN req.OrderStatus='pending' then 'Sample Collected'
WHEN req.OrderStatus='result-added' then 'Result Added'
WHEN req.OrderStatus='report-generated' then 'Report Generated' 
END AS TestStatus,
CASE 
WHEN BillingStatus IN ('paid','unpaid') THEN 'Paid' 
WHEN BillingStatus='cancel' THEN 'bill-cancelled'
WHEN BillingStatus = 'returned' THEN 'bill-returned' 
WHEN BillingStatus = 'provisional' THEN 'provisional' 
END AS BillStatus,
emp1.FullName AS SampleCollectedBy,emp4.FullName AS ReportPrintedBy,
emp2.FullName As CancelledByUser, req.BillCancelledOn
FROM LAB_TestRequisition req 
join @OrderStatusList os on req.OrderStatus = os.OrderStatus
LEFT JOIN EMP_Employee emp1 ON req.SampleCreatedBy = emp1.EmployeeId
LEFT JOIN EMP_Employee emp2 ON req.BillCancelledBy = emp2.EmployeeId
LEFT JOIN EMP_Employee emp3 ON req.ResultAddedBy = emp3.EmployeeId
LEFT JOIN LAB_TXN_LabReports report ON req.LabReportId = report.LabReportId
LEFT JOIN EMP_Employee emp4 ON report.PrintedBy = emp4.EmployeeId
JOIN PAT_Patient pat ON req.PatientId=pat.PatientId
WHERE CONVERT(date,req.OrderDateTime) between @FromDate and @ToDate
Order by req.OrderDateTime desc;
END
END