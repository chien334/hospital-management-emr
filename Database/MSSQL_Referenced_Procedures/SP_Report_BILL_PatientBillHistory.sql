CREATE PROCEDURE [dbo].[SP_Report_BILL_PatientBillHistory]  -- SP_Report_BILL_PatientBillHistory null,null,'1809003399'
	@FromDate datetime = NULL,
	@ToDate datetime = NULL,
	@PatientCode nvarchar(max) = NULL
AS
/*
FileName: [SP_Report_BILL_PatientBillHistory]
CreatedBy/date: nagesh/2017-05-25
Description: to get the total of Billed, Unbilled, and Returned along with the other data
Remarks:    NEEDS LOT OF IMPROVISATION ON THIS SP--sudarshan(29jul'17)
Change History
S.No.    UpdatedBy/Date                        Remarks
1       nagesh/2017-05-25	                created the script
2		ashim/2017-07-11					modified the script
3		ashim/2017-07-28					modifications for bug fix
											(ReceiptNo and ItemPrice,ItemName-ReturnedBill)
4		ramavtar/2018-10-04					change parameter (replaced PatientId with PatientCode)
5		ramavtar/2018-10-15					change in SP (corrected where clause in paid,unpaid.. change table in case of return taking from BIL_TXN_InvoiceReturn.. 
											added require columns (remark, corrected receiptNo)
6		Sanjeev/31st-May'23					Change DepositType to TransactionType and Change Amount to InAmount if TransactionType is 'Deposit', Else Change Amount to OutAmount
*/
BEGIN

  IF (@FromDate IS NOT NULL AND @ToDate IS NOT NULL AND @PatientCode IS NOT NULL)
  BEGIN

    --Paid Bill History
    WITH PaidBillHistory
    AS (SELECT
		ROW_NUMBER() OVER (ORDER BY BillingTransactionItemId) AS SrNo,
		SrvDept.ServiceDepartmentName AS [Department],
		ItemName AS Item,
		Price AS Rate,
		Quantity,
		TransactionItem.SubTotal AS Amount,
		ISNULL(TransactionItem.DiscountAmount, 0) AS Discount,
		TransactionItem.Tax,
		ISNULL(TransactionItem.TotalAmount, 0) AS SubTotal,
		CONVERT(date, TransactionItem.PaidDate) AS [PaidDate],
		Txn.InvoiceNo AS ReceiptNo
    FROM BIL_TXN_BillingTransactionItems TransactionItem
	INNER JOIN BIL_TXN_BillingTransaction Txn ON TransactionItem.BillingTransactionId = Txn.BillingTransactionId
    INNER JOIN BIL_MST_ServiceDepartment SrvDept ON TransactionItem.ServiceDepartmentId = SrvDept.ServiceDepartmentId
    INNER JOIN PAT_Patient pat ON TransactionItem.PatientId = pat.PatientId
    WHERE TransactionItem.BillStatus = 'paid' AND pat.PatientCode = @PatientCode 
		AND CONVERT(date,TransactionItem.PaidDate) BETWEEN @FromDate AND @ToDate
		AND TransactionItem.ReturnStatus IS NULL)
    
	SELECT * FROM PaidBillHistory ORDER BY CONVERT(date, PaidDate) DESC;

    --Unpaid Bill History
    WITH UnpaidBillHistory
    AS (SELECT
		ROW_NUMBER() OVER (ORDER BY BillingTransactionItemId) AS SrNo,
		SrvDept.ServiceDepartmentName AS [Department],
		ItemName AS Item,
		Price AS Rate,
		Quantity,
		TransactionItem.SubTotal AS Amount,
		ISNULL(TransactionItem.DiscountAmount, 0) AS Discount,
		TransactionItem.Tax,
		ISNULL(TransactionItem.TotalAmount, 0) AS SubTotal,
		CONVERT(date, TransactionItem.RequisitionDate) AS [Date],
		Txn.InvoiceNo AS ReceiptNo
    FROM BIL_TXN_BillingTransactionItems TransactionItem
	INNER JOIN BIL_TXN_BillingTransaction Txn ON TransactionItem.BillingTransactionId = Txn.BillingTransactionId
    INNER JOIN BIL_MST_ServiceDepartment SrvDept ON TransactionItem.ServiceDepartmentId = SrvDept.ServiceDepartmentId
    INNER JOIN PAT_Patient pat ON TransactionItem.PatientId = pat.PatientId
    WHERE TransactionItem.BillStatus = 'unpaid' AND pat.PatientCode = @PatientCode
		AND TransactionItem.ReturnStatus IS NULL
		AND CONVERT(date,RequisitionDate) BETWEEN @FromDate AND @ToDate)
    
	SELECT * FROM UnpaidBillHistory ORDER BY CONVERT(date, [Date]) DESC;

    --Returned Bill History
    WITH ReturnedBillHistory
    AS (SELECT
		ROW_NUMBER() OVER (ORDER BY BillReturn.BillReturnId) AS SrNo,
		SrvDept.ServiceDepartmentName AS Department,
		TransactionItem.ItemName AS Item,
		TransactionItem.Price AS Rate,
		TransactionItem.Quantity,
		TransactionItem.SubTotal AS Amount,
		BillReturn.Remarks AS Remarks,
		ISNULL(TransactionItem.DiscountAmount, 0) AS Discount,
		TransactionItem.Tax,
		ISNULL(TransactionItem.TotalAmount, 0) AS ReturnedAmount,
		CONVERT(date,BillReturn.CreatedOn) 'ReturnDate',
		Txn.InvoiceNo AS ReceiptNo,
		Emp.FirstName + ISNULL(' ' + Emp.MiddleName + ' ', ' ') + Emp.LastName AS ReturnedBy
    FROM BIL_TXN_InvoiceReturn BillReturn
	INNER JOIN BIL_TXN_BillingTransaction Txn ON BillReturn.BillingTransactionId = Txn.BillingTransactionId
	INNER JOIN BIL_TXN_BillingTransactionItems TransactionItem ON Txn.BillingTransactionId = TransactionItem.BillingTransactionId
    INNER JOIN BIL_MST_ServiceDepartment SrvDept ON TransactionItem.ServiceDepartmentId = SrvDept.ServiceDepartmentId
    INNER JOIN EMP_Employee Emp ON BillReturn.CreatedBy = Emp.EmployeeId
    INNER JOIN PAT_Patient pat ON BillReturn.PatientId = pat.PatientId
    WHERE pat.PatientCode = @PatientCode
		AND CONVERT(date,BillReturn.CreatedOn) BETWEEN @FromDate AND @ToDate)

    SELECT * FROM ReturnedBillHistory ORDER BY CONVERT(date, ReturnDate) DESC;

    --Deposit
    WITH DepositHistory
    AS (SELECT
      ROW_NUMBER() OVER (ORDER BY DepositId) AS SrNo,
      CONVERT(date, dep.CreatedOn) AS [Date],
      TransactionType,
      CASE WHEN TransactionType = 'Deposit' THEN inAmount ELSE outAmount END AS Amount,
      Remarks,
	  ReceiptNo
    FROM BIL_TXN_Deposit dep
    INNER JOIN PAT_Patient pat ON dep.PatientId = pat.PatientId
    WHERE pat.PatientCode = @PatientCode
		AND CONVERT(date,dep.CreatedOn) BETWEEN @FromDate AND @ToDate)
    
	SELECT * FROM DepositHistory ORDER BY CONVERT(date, Date) DESC;

    --Cancel Bill History
    WITH CancelBillHistory
    AS (SELECT
      ROW_NUMBER() OVER (ORDER BY BillingTransactionItemId) AS SrNo,
      SrvDept.ServiceDepartmentName AS [Department],
      ItemName AS Item,
      Price AS Rate,
      Quantity,
      CancelRemarks AS Remarks,
      SubTotal AS Amount,
      TotalAmount AS CancelledAmount,
      CONVERT(date, CancelledOn) AS CancelledDate,
      Emp.FirstName + ISNULL(' ' + Emp.MiddleName + ' ', ' ') + Emp.LastName AS CancelledBy,
      ISNULL(DiscountAmount, 0) AS Discount,
      Tax,
      ISNULL(TotalAmount, 0) AS SubTotal,
      CONVERT(date, RequisitionDate) AS [Date]
    FROM BIL_TXN_BillingTransactionItems TransactionItem
    INNER JOIN BIL_MST_ServiceDepartment SrvDept ON TransactionItem.ServiceDepartmentId = SrvDept.ServiceDepartmentId
    INNER JOIN EMP_Employee Emp ON TransactionItem.CancelledBy = Emp.EmployeeId
    INNER JOIN PAT_Patient pat ON TransactionItem.PatientId = pat.PatientId
    WHERE BillStatus = 'cancel' AND pat.PatientCode = @PatientCode
		AND CONVERT(date,RequisitionDate) BETWEEN @FromDate AND @ToDate)
    
	SELECT * FROM CancelBillHistory ORDER BY CONVERT(date, [Date]) DESC;

  END
  ELSE IF (@FromDate IS NULL AND @ToDate IS NULL AND @PatientCode IS NOT NULL)
  BEGIN
	    --Paid Bill History
    WITH PaidBillHistory
    AS (SELECT
		ROW_NUMBER() OVER (ORDER BY BillingTransactionItemId) AS SrNo,
		SrvDept.ServiceDepartmentName AS [Department],
		ItemName AS Item,
		Price AS Rate,
		Quantity,
		TransactionItem.SubTotal AS Amount,
		ISNULL(TransactionItem.DiscountAmount, 0) AS Discount,
		TransactionItem.Tax,
		ISNULL(TransactionItem.TotalAmount, 0) AS SubTotal,
		CONVERT(date, TransactionItem.PaidDate) AS [PaidDate],
		Txn.InvoiceNo AS ReceiptNo
    FROM BIL_TXN_BillingTransactionItems TransactionItem
	INNER JOIN BIL_TXN_BillingTransaction Txn ON TransactionItem.BillingTransactionId = Txn.BillingTransactionId
    INNER JOIN BIL_MST_ServiceDepartment SrvDept ON TransactionItem.ServiceDepartmentId = SrvDept.ServiceDepartmentId
    INNER JOIN PAT_Patient pat ON TransactionItem.PatientId = pat.PatientId
    WHERE TransactionItem.BillStatus = 'paid' AND pat.PatientCode = @PatientCode
		AND TransactionItem.ReturnStatus IS NULL)
    
	SELECT * FROM PaidBillHistory ORDER BY CONVERT(date, PaidDate) DESC;

    --Unpaid Bill History
    WITH UnpaidBillHistory
    AS (SELECT
		ROW_NUMBER() OVER (ORDER BY BillingTransactionItemId) AS SrNo,
		SrvDept.ServiceDepartmentName AS [Department],
		ItemName AS Item,
		Price AS Rate,
		Quantity,
		TransactionItem.SubTotal AS Amount,
		ISNULL(TransactionItem.DiscountAmount, 0) AS Discount,
		TransactionItem.Tax,
		ISNULL(TransactionItem.TotalAmount, 0) AS SubTotal,
		CONVERT(date, TransactionItem.RequisitionDate) AS [Date],
		Txn.InvoiceNo AS ReceiptNo
    FROM BIL_TXN_BillingTransactionItems TransactionItem
	INNER JOIN BIL_TXN_BillingTransaction Txn ON TransactionItem.BillingTransactionId = Txn.BillingTransactionId
    INNER JOIN BIL_MST_ServiceDepartment SrvDept ON TransactionItem.ServiceDepartmentId = SrvDept.ServiceDepartmentId
    INNER JOIN PAT_Patient pat ON TransactionItem.PatientId = pat.PatientId
    WHERE TransactionItem.BillStatus = 'unpaid' AND pat.PatientCode = @PatientCode
		AND TransactionItem.ReturnStatus IS NULL)
    
	SELECT * FROM UnpaidBillHistory ORDER BY CONVERT(date, [Date]) DESC;

    --Returned Bill History
    WITH ReturnedBillHistory
    AS (SELECT
		ROW_NUMBER() OVER (ORDER BY BillReturn.BillReturnId) AS SrNo,
		SrvDept.ServiceDepartmentName AS Department,
		TransactionItem.ItemName AS Item,
		TransactionItem.Price AS Rate,
		TransactionItem.Quantity,
		TransactionItem.SubTotal AS Amount,
		BillReturn.Remarks AS Remarks,
		ISNULL(TransactionItem.DiscountAmount, 0) AS Discount,
		TransactionItem.Tax,
		ISNULL(TransactionItem.TotalAmount, 0) AS ReturnedAmount,
		CONVERT(date,BillReturn.CreatedOn) 'ReturnDate',
		Txn.InvoiceNo AS ReceiptNo,
		Emp.FirstName + ISNULL(' ' + Emp.MiddleName + ' ', ' ') + Emp.LastName AS ReturnedBy
    FROM BIL_TXN_InvoiceReturn BillReturn
	INNER JOIN BIL_TXN_BillingTransaction Txn ON BillReturn.BillingTransactionId = Txn.BillingTransactionId
	INNER JOIN BIL_TXN_BillingTransactionItems TransactionItem ON Txn.BillingTransactionId = TransactionItem.BillingTransactionId
    INNER JOIN BIL_MST_ServiceDepartment SrvDept ON TransactionItem.ServiceDepartmentId = SrvDept.ServiceDepartmentId
    INNER JOIN EMP_Employee Emp ON BillReturn.CreatedBy = Emp.EmployeeId
    INNER JOIN PAT_Patient pat ON BillReturn.PatientId = pat.PatientId
    WHERE pat.PatientCode = @PatientCode)

    SELECT * FROM ReturnedBillHistory ORDER BY CONVERT(date, ReturnDate) DESC;

    --Deposit
    WITH DepositHistory
    AS (SELECT
      ROW_NUMBER() OVER (ORDER BY DepositId) AS SrNo,
      CONVERT(date, dep.CreatedOn) AS [Date],
      TransactionType,
      CASE WHEN TransactionType = 'Deposit' THEN inAmount ELSE outAmount END AS Amount,
      Remarks,
	  ReceiptNo
    FROM BIL_TXN_Deposit dep
    INNER JOIN PAT_Patient pat ON dep.PatientId = pat.PatientId
    WHERE pat.PatientCode = @PatientCode)
    
	SELECT * FROM DepositHistory ORDER BY CONVERT(date, Date) DESC;

    --Cancel Bill History
    WITH CancelBillHistory
    AS (SELECT
      ROW_NUMBER() OVER (ORDER BY BillingTransactionItemId) AS SrNo,
      SrvDept.ServiceDepartmentName AS [Department],
      ItemName AS Item,
      Price AS Rate,
      Quantity,
      CancelRemarks AS Remarks,
      SubTotal AS Amount,
      TotalAmount AS CancelledAmount,
      CONVERT(date, CancelledOn) AS CancelledDate,
      Emp.FirstName + ISNULL(' ' + Emp.MiddleName + ' ', ' ') + Emp.LastName AS CancelledBy,
      ISNULL(DiscountAmount, 0) AS Discount,
      Tax,
      ISNULL(TotalAmount, 0) AS SubTotal,
      CONVERT(date, RequisitionDate) AS [Date]
    FROM BIL_TXN_BillingTransactionItems TransactionItem
    INNER JOIN BIL_MST_ServiceDepartment SrvDept ON TransactionItem.ServiceDepartmentId = SrvDept.ServiceDepartmentId
    INNER JOIN EMP_Employee Emp ON TransactionItem.CancelledBy = Emp.EmployeeId
    INNER JOIN PAT_Patient pat ON TransactionItem.PatientId = pat.PatientId
    WHERE BillStatus = 'cancel' AND pat.PatientCode = @PatientCode)
    
	SELECT * FROM CancelBillHistory ORDER BY CONVERT(date, [Date]) DESC;

  END
END