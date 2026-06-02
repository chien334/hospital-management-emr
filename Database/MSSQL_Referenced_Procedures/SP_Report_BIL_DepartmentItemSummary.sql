--Changed ProviderName to PerformerName
CREATE PROCEDURE [dbo].[SP_Report_BIL_DepartmentItemSummary]  
--[SP_Report_BIL_DepartmentItemSummary] '01-22-2018','01-22-2019',NULL  
@ToDate DATETIME = NULL,  
@FromDate DATETIME = NULL,  
@SrvDeptName NVARCHAR(MAX) = NULL  
AS  
/*  
Change History  
S.No. UpdatedBy/Date			Remarks  
1  Ramavtar/11Sept'18		Initial Draft  
2  Ramavtar/30Nov'18		added summary and filtered report data for provisional and cancel  
3  Sud/13Mar'19				Changed to function FN_BILL_Get_BillingTxnItemSeggregation_ByBillingType_NoProvisional   
                                  from: FN_BIL_GetTxnItemsInfoWithDateSeparation_DepartmentSummary  
4. Dinesh/27th May'19		Added ReferredDoctorName   
5. Krishna/8thJun'22		Changed ProviderName to PerformerName
6. Krishna/23,Aug'22		changed the SP for Department summary (removed the dependency of function from the SP)
*/  
BEGIN  

select * from (

--<Sales part start>
SELECT 
	 CONVERT(DATE,CreatedOn) AS 'Date'
	,ISNULL(invItm.PerformerName,'No Doctor') 'PerformerName'
	,ISNULL(invItm.PrescriberName,'No Doctor') 'PrescriberName'
	,invItm.ShortName 'PatientName'
	,invItm.PatientCode 'PatientCode'
	,invItm.InvoiceNo 'InvoiceNumber'
	,invItm.Price
	,invItm.Quantity as 'Quantity'
	,invItm.SubTotal as 'SubTotal'
	,invItm.DiscountAmount
	, ISNULL(invItm.TotalAmount,0) 'TotalAmount'
	, 0 as 'ReturnAmount'
	,ISNULL(invItm.TotalAmount, 0) AS 'NetAmount'
	,invItm.ServiceDepartmentId
	,invItm.ServiceDepartmentName
	,invItm.ItemName
FROM (
	SELECT 
		 perfEmp.FullName 'PerformerName'
		,presEmp.FullName 'PrescriberName'
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
	LEFT JOIN EMP_Employee perfEmp ON perfEmp.EmployeeId = itm.PerformerId
	LEFT JOIN EMP_Employee presEmp ON presEmp.EmployeeId = itm.PrescriberId
	WHERE Convert(DATE, txn.CreatedOn) BETWEEN @FromDate AND @ToDate
		AND serv.ServiceDepartmentName = ISNULL(@SrvDeptName, serv.ServiceDepartmentName)
		
	) invItm
--<Sales part END>
UNION ALL


--<Return part starts>
SELECT 
		
	CONVERT(DATE,ret.CreatedOn) AS 'Date'
	,ISNULL(perfEmp.FullName,'No Doctor') 'PerformerName'
	,ISNULL(presEmp.FullName,'No Doctor') 'PrescriberName'
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
	LEFT JOIN EMP_Employee perfEmp ON perfEmp.EmployeeId = itm.PerformerId
	LEFT JOIN EMP_Employee presEmp ON presEmp.EmployeeId = itm.PrescriberId
	WHERE Convert(DATE, ret.CreatedOn) BETWEEN @FromDate AND @ToDate
		AND itm.ServiceDepartmentName = ISNULL(@SrvDeptName, itm.ServiceDepartmentName)
	
	)tbl
	ORDER BY tbl.Date DESC
--<Return part END>
 
--table2: provisional, cancel, credit amounts for summary  
 SELECT   
  SUM(CASE WHEN BillStatus='provisional' THEN ProvisionalAmount ELSE 0 END) 'ProvisionalAmount',  
  SUM(CASE WHEN BillStatus='cancelled' THEN CancelledAmount ELSE 0 END) 'CancelledAmount',  
  SUM(CASE WHEN BillStatus='credit' THEN CreditAmount ELSE 0 END) 'CreditAmount',  
  (SELECT SUM(ISNULL(AdvanceReceived,0)) FROM FN_BIL_GetDepositNProvisionalBetnDateRange(@FromDate,@ToDate)) 'AdvanceReceived',  
  (SELECT SUM(ISNULL(AdvanceSettled,0)) FROM FN_BIL_GetDepositNProvisionalBetnDateRange(@FromDate,@ToDate)) 'AdvanceSettled'  
 FROM FN_BIL_GetTxnItemsInfoWithDateSeparation_DepartmentSummary(@FromDate, @ToDate)  
 WHERE ServiceDepartmentName = ISNULL(@SrvDeptName,ServiceDepartmentName)
END