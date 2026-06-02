CREATE PROCEDURE SP_PHRM_ItemWiseSalesReport @FromDate DATE
	,@ToDate DATE
	,@ItemId INT = NULL
	,@StoreId INT = NULL
	,@CounterId INT = NULL
	,@CreatedBy INT = NULL
AS
/*
Example to execute SP: SP_PHRM_ItemWiseSalesReport '2022-02-15','2022-02-16',435,null,null,null
FileName: [[SP_PHRM_ItemWiseSalesReport]]
CreatedBy/date: Rohit/2022-02-16
Description: To get daily sales report for particular item.
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Rohit/2022-02-16                     created the script
2.      Rohit/13Feb'23						 MRP-> SalePrice
*/
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT InvoicePrintId
		,GenericName
		,ItemName
		,PatientName
		,BatchNo
		,ExpiryDate
		,Quantity
		,Price
		,SalePrice
		,StockValue
		,TotalAmount
		,CreatedOn
		,StoreName
		,CounterName
		,CreatedByName
		,TransactionType
		,Remark
	FROM (
		SELECT 'PH' + CONVERT(VARCHAR(20), inv.InvoicePrintId) 'InvoicePrintId'
			,pat.FirstName + ISNULL(pat.MiddleName, ' ') + pat.LastName 'PatientName'
			,generic.GenericName 'GenericName'
			,mstitm.ItemName 'ItemName'
			,invitm.BatchNo 'BatchNo'
			,invitm.ExpiryDate 'ExpiryDate'
			,invitm.Quantity 'Quantity'
			,invitm.Price 'Price'
			,invitm.SalePrice 'SalePrice'
			,invitm.Quantity * invitm.Price 'StockValue'
			,invitm.TotalAmount 'TotalAmount'
			,invitm.CreatedOn 'CreatedOn'
			,CASE 
				WHEN inv.PaymentMode = 'Cash'
					THEN 'CashSales'
				ELSE 'CreditSales'
				END AS 'TransactionType'
			,store.Name 'StoreName'
			,counter.CounterName 'CounterName'
			,emp.FullName 'CreatedByName'
			,inv.Remark AS 'Remark'
		FROM PHRM_TXN_InvoiceItems invitm
		JOIN PHRM_TXN_Invoice inv ON invitm.InvoiceId = inv.InvoiceId
		JOIN PHRM_MST_Item mstitm ON invitm.ItemId = mstitm.ItemId
		JOIN PHRM_MST_Generic generic ON mstitm.GenericId = generic.GenericId
		JOIN PAT_Patient pat ON invitm.PatientId = pat.PatientId
		JOIN PHRM_MST_Store store ON invitm.StoreId = store.StoreId
		JOIN PHRM_MST_Counter counter ON invitm.CounterId = counter.CounterId
		JOIN EMP_Employee emp ON invitm.CreatedBy = emp.EmployeeId
		WHERE Convert(DATE, invitm.CreatedOn) BETWEEN @FromDate
				AND @ToDate
			AND (
				invitm.StoreId = @StoreId
				OR @StoreId IS NULL
				)
			AND (
				invitm.CounterId = @CounterId
				OR @CounterId IS NULL
				)
			AND (
				invitm.CreatedBy = @CreatedBy
				OR @CreatedBy IS NULL
				)
			AND (
				invitm.ItemId = @ItemId
				OR @ItemId IS NULL
				)
		
		UNION ALL
		
		SELECT 'CR-PH' + CONVERT(VARCHAR(20), invret.CreditNoteID) 'InvoicePrintId'
			,pat.FirstName + ISNULL(pat.MiddleName, ' ') + pat.LastName 'PatientName'
			,generic.GenericName 'GenericName'
			,mstitm.ItemName 'ItemId'
			,invitmret.BatchNo 'BatchNo'
			,invitm.ExpiryDate 'ExpiryDate'
			,- invitmret.ReturnedQty 'Quantity'
			,invitmret.Price 'Price'
			,invitmret.SalePrice 'SalePrice'
			,- (invitmret.ReturnedQty * invitmret.Price) 'StockValue'
			,- invitmret.TotalAmount 'TotalAmount'
			,invitmret.CreatedOn 'CreatedOn'
			,CASE 
				WHEN invret.PaymentMode = 'Cash'
					THEN 'CashSalesReturn'
				ELSE 'CreditSalesReturn'
				END AS 'TransactionType'
			,store.Name 'StoreName'
			,counter.CounterName 'CounterName'
			,emp.FullName 'CreatedByName'
			,invret.Remarks + ' Reference InvoiceNo: ' + '(' + CONVERT(VARCHAR(20), inv.InvoicePrintID) + ')' AS 'Remark'
		FROM PHRM_TXN_InvoiceReturnItems invitmret
		JOIN PHRM_TXN_InvoiceReturn invret ON invitmret.InvoiceReturnId = invret.InvoiceReturnId
		JOIN PHRM_TXN_InvoiceItems invitm ON invitmret.InvoiceItemId = invitm.InvoiceItemId
		JOIN PHRM_TXN_Invoice inv ON invitm.InvoiceId = inv.InvoiceId
		JOIN PHRM_MST_Item mstitm ON invitmret.ItemId = mstitm.ItemId
		JOIN PHRM_MST_Generic generic ON mstitm.GenericId = generic.GenericId
		JOIN PAT_Patient pat ON invret.PatientId = pat.PatientId
		JOIN PHRM_MST_Store store ON invitmret.StoreId = store.StoreId
		JOIN PHRM_MST_Counter counter ON invitmret.CounterId = counter.CounterId
		JOIN EMP_Employee emp ON invitmret.CreatedBy = emp.EmployeeId
		WHERE Convert(DATE, invitmret.CreatedOn) BETWEEN @FromDate
				AND @ToDate
			AND (
				invitmret.StoreId = @StoreId
				OR @StoreId IS NULL
				)
			AND (
				invitmret.CounterId = @CounterId
				OR @CounterId IS NULL
				)
			AND (
				invitmret.CreatedBy = @CreatedBy
				OR @CreatedBy IS NULL
				)
			AND (
				invitmret.ItemId = @ItemId
				OR @ItemId IS NULL
				)
		) a
	ORDER BY CreatedOn DESC
END