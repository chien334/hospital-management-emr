--Altering SP_Report_BIL_DoctorDeptItemsSummary SP
--changed ProviderId to PerformerId and ProviderName to PerformerName 
CREATE PROCEDURE [dbo].[SP_Report_BIL_DoctorDeptItemsSummary] @FromDate datetime = NULL,  
@ToDate datetime = NULL,  
@DoctorId int = NULL,  
@SrvDeptName varchar(max) = NULL  
AS  
/*  
Change History  
S.No.    UpdatedBy/Date          Remarks  
1    Ramavtar/04Sept'18      initail draft  
2  Ramavtar/30Nov'18   summary added   
3  Ramavtar/17Dec'18   change in where condition (checking for credit records)  
4.  Ramavtar/18Dec'18   getting data for all service dept  
5.   Sud/21Feb'19             using new function to get doc-dept-items.  
6.   sud:13Mar'19            Join with FN_BIL_GetSrvDeptReportingName_DoctorSummary to get actual service department name,   
                             since it's now removed from  FN_BILL_Get_BillingTxnItemSeggregation_ByBillingType_NoProvisional  
7.   sud:10Aug'20            InvoiceNumber column added in Return data, Order by Date ASC  
8.	Krishna/9thJun'22		changed ProviderId to PerformerId and ProviderName to PerformerName
9.	Krishna/11thAug'22		add condition for PrescriberId and ReferredById with @DoctorId
10.	Krishna/22th,Aug'22		handle Return Scenarios
11.	Krishna/23rd,Aug'22		Complete SP revised(changed)
*/  
BEGIN  
  
 DECLARE @EmpName VARCHAR(100) = (SELECT TOP (1) FullName FROM EMP_Employee WHERE EmployeeId = @DoctorId)

--<Sales part start>
SELECT 
	 CONVERT(DATE,CreatedOn) AS 'Date'
	,@DoctorId 'DoctorId'
	,@EmpName 'DoctorName'
	,invItm.ShortName 'PatientName'
	,invItm.PatientCode 'PatientCode'
	,invItm.InvoiceNo 'InvoiceNumber'
	,invItm.Price
	,invItm.Quantity as 'Quantity'
	,invItm.SubTotal as 'SubTotal'
	,invItm.DiscountAmount as 'DiscountAmount'
	, ISNULL(invItm.TotalAmount,0) 'TotalAmount'
	, 0 as 'ReturnAmount'
	,ISNULL(invItm.TotalAmount, 0) AS 'NetAmount'
	,invItm.ServiceDepartmentId
	,invItm.ServiceDepartmentName
	,invItm.ItemName
FROM (
	SELECT itm.BillingTransactionItemId
		,PrescriberId
		,itm.TotalAmount 'TotalAmount'
		,serv.ServiceDepartmentId
		,serv.ServiceDepartmentName
		,itm.ItemName
		,pat.ShortName
		,txn.InvoiceNo
		,itm.SubTotal
		,itm.DiscountAmount
		,pat.PatientCode
		,itm.Price
		,itm.Quantity
		,txn.CreatedOn as 'CreatedOn'
	FROM BIL_TXN_BillingTransactionItems itm
	INNER JOIN BIL_TXN_BillingTransaction txn ON itm.BillingTransactionId = txn.BillingTransactionId
	INNER JOIN BIL_MST_ServiceDepartment serv ON serv.ServiceDepartmentId = itm.ServiceDepartmentId
	INNER JOIN PAT_Patient pat ON pat.PatientId = itm.PatientId
	WHERE Convert(DATE, txn.CreatedOn) BETWEEN @FromDate AND @ToDate
		AND serv.ServiceDepartmentName = ISNULL(@SrvDeptName, serv.ServiceDepartmentName)
		AND (
			ISNULL(itm.PrescriberId, 0) = ISNULL(@DoctorId, 0)
			OR ISNULL(itm.PerformerId, 0) = ISNULL(@DoctorId, 0)
			OR ISNULL(itm.ReferredById, 0) = ISNULL(@DoctorId, 0)
			)
	) invItm
--<Sales part END>
UNION ALL


--<Return part starts>
SELECT 
		
	CONVERT(DATE,ret.CreatedOn) AS 'Date'
	,@DoctorId 'DoctorId'
	,@EmpName 'DoctorName'
	,pat.ShortName 'PatientName'
	,pat.PatientCode 'PatientCode'
	,ret.RefInvoiceNum 'InvoiceNumber'
	,rti.Price
	,-rti.RetQuantity as 'Quantity'
	,0 as 'SubTotal'
	,0 as 'DiscountAmount'
	,0 as 'TotalAmount'
	, ISNULL(rti.RetTotalAmount,0) as 'ReturnAmount'
	,-ISNULL(rti.RetTotalAmount,0) AS 'NetAmount'
	,itm.ServiceDepartmentId
	,itm.ServiceDepartmentName
	,itm.ItemName
		
	FROM BIL_TXN_InvoiceReturnItems rti
	INNER JOIN BIL_TXN_BillingTransactionItems itm ON rti.BillingTransactionItemId = itm.BillingTransactionItemId
	INNER JOIN BIL_TXN_InvoiceReturn ret ON rti.BillReturnId = ret.BillReturnId
	INNER JOIN PAT_Patient pat ON pat.PatientId = ret.PatientId
	WHERE Convert(DATE, ret.CreatedOn) BETWEEN @FromDate AND @ToDate
		AND itm.ServiceDepartmentName = ISNULL(@SrvDeptName, itm.ServiceDepartmentName)
		AND (
			ISNULL(itm.PrescriberId, 0) = ISNULL(@DoctorId, 0)
			OR ISNULL(itm.PerformerId, 0) = ISNULL(@DoctorId, 0)
			OR ISNULL(itm.ReferredById, 0) = ISNULL(@DoctorId, 0)
			)

END