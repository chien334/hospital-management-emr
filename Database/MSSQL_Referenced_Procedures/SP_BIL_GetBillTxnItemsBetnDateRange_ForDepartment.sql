CREATE PROCEDURE [dbo].[SP_BIL_GetBillTxnItemsBetnDateRange_ForDepartment]
		@FromDate Datetime=null ,
		@ToDate DateTime=null,
		@SearchText varchar(100)=null,
		@SrvDptIntegrationName varchar(50)
AS
/*
FileName: [SP_BIL_GetBillTxnItemsBetnDateRange_ForDepartment]
CreatedBy/date: Anjana/sud/2020-05-26
Description: to get billing txn item details for selected integration name(Service Department)
Remarks:  
   -- Returned Items are Excluded.
   -- Cancelled+adtCancelled Items are Excluded.
   -- If Search Text is Empty then returning all.
   -- If Date is Empty the returning today's tranisaction.
   -- if integrationname is empty then returing all.


Change History
S.No.    UpdatedBy/Date                        Remarks
1.      Anjana/sud/2020-05-26              Initial Draft
2.		Krishna/2Jun'22					   changed ProviderId to PerformerId, ProviderName to PerformerName, RequestedBy to PrescriberId
*/
BEGIN
 
 
Select 
	txnItem.CreatedOn as 'Date'
	, txnItem.ServiceDepartmentId,
	txnItem.ServiceDepartmentName,
	txnItem.ItemId,
	txnItem.ItemName,
	txnItem.PerformerId,
	txnItem.PerformerName,
	txnItem.BillingTransactionItemId,
	txnItem.BillStatus,
	txnItem.PrescriberId as 'PrescriberId',
	txnItem.BillingTransactionId,
	txnItem.RequisitionId,
	bilTxn.InvoiceCode + convert(varchar(20),bilTxn.InvoiceNo) as 'ReceiptNo',
	pat.PatientId,
	pat.ShortName as 'PatientName',
	pat.DateOfBirth,
	pat.Gender,
	pat.PhoneNumber,
	pat.PatientCode,
	cfg.IsDoctorMandatory as 'DoctorMandatory',
	emp.FullName as 'PrescriberName'

from BIL_TXN_BillingTransactionItems txnItem INNER JOIN
     BIL_MST_ServiceDepartment srv  
	    ON srv.ServiceDepartmentId = txnItem.ServiceDepartmentId 
	INNER JOIN PAT_Patient pat
	  ON txnItem.PatientId = pat.PatientId
	INNER JOIN BIL_CFG_BillItemPrice cfg
	 
	     ON txnItem.ServiceDepartmentId = cfg.ServiceDepartmentId and txnItem.ItemId=cfg.ItemId
	LEFT JOIN BIL_TXN_BillingTransaction bilTxn ON txnItem.BillingTransactionId = bilTxn.BillingTransactionId
	LEFT JOIN EMP_Employee emp ON txnItem.PrescriberId = emp.EmployeeId

Where 
ISNULL(srv.IntegrationName, '') like '%' + ISNULL(@SrvDptIntegrationName,'') + '%'
AND txnItem.BillStatus != 'cancel'
AND txnItem.BillStatus != 'adtCancel'
AND ISNULL(txnItem.ReturnStatus,0) != 1   -- Null Handling..  NULL OR 0 => Take this, 1 =>   Don't Take this. 
--REturn Today's data if null.. 
and Convert(Date, txnItem.CreatedOn) between ISNULL(@FromDate,Convert(Date, GETDATE())) AND ISNULL(@ToDate, Convert(Date, GETDATE()))  

and (pat.ShortName + pat.PatientCode + ISNUll(pat.PhoneNumber, '') + srv.ServiceDepartmentName + txnItem.ItemName) Like  '%'+ISNULL(@SearchText,'')+'%'


ORder by txnItem.Billingtransactionitemid DESC

END