CREATE PROCEDURE [dbo].[SP_PHRMReport_ItemTxnSummaryReport] @FromDate DATE = NULL
	,@ToDate DATE = NULL
	,@ItemId INT = NULL
AS
/*
  FileName: [SP_PHRMReport_ItemTxnSummaryReport]
  CreatedBy/date: Sanjit/2021-01-20
  Description: 
  1. Created to find all the item txn as a part of stock summary report in pharmacy
  Example to Execute:
  exec SP_PHRMReport_ItemTxnSummaryReport '2021-06-15', '2021-09-01', 9
  Change History
  S.No.    UpdatedBy/Date                        Remarks
  1       Sanjit/2021-01-20          created the script.
  2       Sanjesh/2021-02-21         Added Reference name 
  3		  Sanjit/2021-09-01			 Added StoreName, UserName. Added Transfers and Opening Data	
  4       Ramesh/2021-09-26          InvoiceReturnId added as ReferenceNo for Invoice Return 
          Rohit/13Feb'23		     MRP-> SalePrice
*/
BEGIN
	SELECT TransactionDate
		,ReferenceNoPrefix
		,ReferenceName
		,ReferenceNo
		,ReferencePrintNo
		,Type
		,StockIn
		,StockOut
		,Rate
		,SalePrice
		,ExpiryDate
		,StoreName
		,UserName
	FROM (
		--Opening Items
		SELECT FYS.CreatedOn AS [TransactionDate]
			,'Opening' AS [ReferenceNoPrefix]
			,'' AS [ReferenceName]
			,NULL AS [ReferenceNo]
			,NULL AS [ReferencePrintNo]
			,'Opening' AS [Type]
			,ISNULL(FYS.OpeningQuantity, 0) AS [StockIn]
			,0 AS [StockOut]
			,FYS.CostPrice AS [Rate]
			,FYS.SalePrice AS [SalePrice]
			,CONVERT(VARCHAR, FYS.ExpiryDate, 23) AS [ExpiryDate]
			,store.Name AS StoreName
			,E.FullName AS UserName
		FROM PHRM_FiscalYearStock AS FYS
		INNER JOIN PHRM_MST_Store store ON FYS.StoreId = store.StoreId
		INNER JOIN EMP_Employee E ON FYS.CreatedBy = E.EmployeeId
		WHERE (FYS.ItemId = @ItemId)
			AND (
				CONVERT(DATE, FYS.CreatedOn) BETWEEN @fromDate
					AND @toDate
				)
		
		UNION
		
		--Purchase from Goods Receipt Table
		SELECT GR.GoodReceiptDate AS [TransactionDate]
			,'GR' AS [ReferenceNoPrefix]
			,Supp.SupplierName AS [ReferenceName]
			,GR.GoodReceiptId AS [ReferenceNo]
			,GR.GoodReceiptPrintId AS [ReferencePrintNo]
			,'Purchase' AS [Type]
			,ISNULL(GRI.ReceivedQuantity, 0) + ISNULL(GRI.FreeQuantity, 0) AS [StockIn]
			,0 AS [StockOut]
			,GRI.GRItemPrice AS [Rate]
			,GRI.SalePrice AS [SalePrice]
			,CONVERT(VARCHAR, GRI.ExpiryDate, 23) AS [ExpiryDate]
			,store.Name AS StoreName
			,E.FullName AS UserName
		FROM PHRM_GoodsReceiptItems AS GRI
		INNER JOIN PHRM_GoodsReceipt AS GR ON GR.GoodReceiptId = GRI.GoodReceiptId
		INNER JOIN PHRM_MST_Supplier AS Supp ON gr.SupplierId = Supp.SupplierId
		INNER JOIN PHRM_MST_Store store ON GR.StoreId = store.StoreId
		INNER JOIN EMP_Employee E ON GR.CreatedBy = E.EmployeeId
		WHERE (GRI.ItemId = @ItemId)
			AND (
				CONVERT(DATE, GR.GoodReceiptDate) BETWEEN @fromDate
					AND @toDate
				)
		
		UNION
		
		-- Purchase Return from Return To Supplier
		SELECT RTS.ReturnDate AS [TransactionDate]
			,'RTS' AS [ReferenceNoPrefix]
			,Supp.SupplierName AS [ReferenceName]
			,RTS.CreditNoteId AS [ReferenceNo]
			,RTS.CreditNotePrintId AS [ReferencePrintNo]
			,'PurchaseReturn' AS [Type]
			,0 AS [StockIn]
			,(ISNULL(RTSI.Quantity, 0) + ISNULL(RTSI.FreeQuantity, 0)) AS [StockOut]
			,RTSI.ItemPrice AS [Rate]
			,RTSI.SalePrice AS [SalePrice]
			,CONVERT(VARCHAR, RTSI.ExpiryDate, 23) AS [ExpiryDate]
			,'Main Store' AS StoreName
			,E.FullName AS UserName
		FROM PHRM_ReturnToSupplierItems RTSI
		INNER JOIN PHRM_ReturnToSupplier RTS ON RTSI.ReturnToSupplierId = RTS.ReturnToSupplierId
		INNER JOIN PHRM_MST_Supplier Supp ON rts.SupplierId = Supp.SupplierId
		INNER JOIN EMP_Employee E ON RTS.CreatedBy = E.EmployeeId
		WHERE RTSI.ItemId = @ItemId
			AND CONVERT(DATE, RTS.ReturnDate) BETWEEN @fromDate
				AND @toDate
		
		UNION
		
		--Purchase Cancel , txn type = cancel-gr
		SELECT GR.GoodReceiptDate AS [TransactionDate]
			,'CGR' AS [ReferenceNoPrefix]
			,NULL AS [ReferenceName]
			,GR.GoodReceiptId AS [ReferenceNo]
			,GR.GoodReceiptPrintId AS [ReferencePrintNo]
			,'PurchaseCancel' AS [Type]
			,ISNULL(GRI.ReceivedQuantity, 0) + ISNULL(GRI.FreeQuantity, 0) AS [StockIn]
			,0 AS [StockOut]
			,GRI.GRItemPrice AS [Rate]
			,GRI.SalePrice AS [SalePrice]
			,CONVERT(VARCHAR, GRI.ExpiryDate, 23) AS [ExpiryDate]
			,store.Name AS StoreName
			,E.FullName AS UserName
		FROM PHRM_GoodsReceiptItems AS GRI
		INNER JOIN PHRM_GoodsReceipt AS GR ON GR.GoodReceiptId = GRI.GoodReceiptId
		INNER JOIN PHRM_MST_Store store ON GR.StoreId = store.StoreId
		INNER JOIN EMP_Employee E ON GR.CreatedBy = E.EmployeeId
		WHERE (GRI.ItemId = @ItemId)
			AND GR.IsCancel = 1
			AND (
				CONVERT(DATE, GR.GoodReceiptDate) BETWEEN @fromDate
					AND @toDate
				)
		
		UNION
		
		--StockManageIn from PHRM_StoreStock
		SELECT S.TransactionDate AS [TransactionDate]
			,'SMI' AS [ReferenceNoPrefix]
			,'' AS [ReferenceName]
			,S.ReferenceNo AS [ReferenceNo]
			,S.ReferenceNo AS [ReferencePrintNo]
			,'StockManageIn' AS [Type]
			,ISNULL(S.InQty, 0) AS [StockIn]
			,0 AS [StockOut]
			,S.CostPrice AS [Rate]
			,S.SalePrice AS [SalePrice]
			,CONVERT(VARCHAR, S.ExpiryDate, 23) AS [ExpiryDate]
			,store.Name AS StoreName
			,E.FullName AS UserName
		FROM PHRM_TXN_StockTransaction S
		INNER JOIN PHRM_MST_Store store ON S.StoreId = store.StoreId
		INNER JOIN EMP_Employee E ON S.CreatedBy = E.EmployeeId
		WHERE TransactionType = 'stock-managed-item'
			AND S.InQty > 0
			AND S.ItemId = @ItemId
			AND CONVERT(DATE, S.TransactionDate) BETWEEN @fromDate
				AND @toDate
		
		UNION
		
		--StockManageOut from PHRM_StoreStock
		SELECT S.TransactionDate AS [TransactionDate]
			,'SMO' AS [ReferenceNoPrefix]
			,'' AS [ReferenceName]
			,S.ReferenceNo AS [ReferenceNo]
			,S.ReferenceNo AS [ReferencePrintNo]
			,'StockManageOut' AS [Type]
			,0 AS [StockIn]
			,ISNULL(S.OutQty, 0) AS [StockOut]
			,S.CostPrice AS [Rate]
			,S.SalePrice AS [SalePrice]
			,CONVERT(VARCHAR, S.ExpiryDate, 23) AS [ExpiryDate]
			,store.Name AS StoreName
			,E.FullName AS UserName
		FROM PHRM_TXN_StockTransaction S
		INNER JOIN PHRM_MST_Store store ON S.StoreId = store.StoreId
		INNER JOIN EMP_Employee E ON S.CreatedBy = E.EmployeeId
		WHERE TransactionType = 'stock-managed-item'
			AND S.OutQty > 0
			AND S.ItemId = @ItemId
			AND CONVERT(DATE, S.TransactionDate) BETWEEN @fromDate
				AND @toDate
		
		UNION
		
		-- Sale from Invoice Table
		SELECT I.CreateOn AS [TransactionDate]
			,'PH' AS [ReferenceNoPrefix]
			,pat.ShortName AS [ReferenceName]
			,I.InvoiceId AS [ReferenceNo]
			,I.InvoicePrintId AS [ReferencePrintNo]
			,'Sale' AS [Type]
			,0 AS [StockIn]
			,(ISNULL(IItem.Quantity, 0) + ISNULL(IItem.FreeQuantity, 0)) AS [StockOut]
			,IItem.Price AS [Rate]
			,IItem.SalePrice AS [SalePrice]
			,CONVERT(VARCHAR, IItem.ExpiryDate, 23) AS [ExpiryDate]
			,store.Name AS StoreName
			,E.FullName AS UserName
		FROM PHRM_TXN_InvoiceItems IItem
		INNER JOIN PHRM_TXN_Invoice I ON I.InvoiceId = IItem.InvoiceId
		INNER JOIN PAT_Patient pat ON I.PatientId = pat.PatientId
		INNER JOIN PHRM_MST_Store store ON I.StoreId = store.StoreId
		INNER JOIN EMP_Employee E ON I.CreatedBy = E.EmployeeId
		WHERE IItem.ItemId = @ItemId
			AND CONVERT(DATE, I.CreateOn) BETWEEN @fromDate
				AND @toDate
		
		UNION
		
		-- Sales Return from Invoice Return Table
		SELECT IR.CreatedOn AS [TransactionDate]
			,'CR-PH' AS [ReferenceNoPrefix]
			,NULL AS [ReferenceName]
			,IR.InvoiceReturnId AS [ReferenceNo]
			,IR.CreditNoteID AS [ReferencePrintNo]
			,'SaleRefund' AS [Type]
			,(ISNULL(IRI.ReturnedQty, 0)) AS [StockIn]
			,0 AS [StockOut]
			,IRI.Price AS [Rate]
			,IRI.SalePrice AS [SalePrice]
			,CONVERT(VARCHAR, IItem.ExpiryDate, 23) AS [ExpiryDate]
			,store.Name AS StoreName
			,E.FullName AS UserName
		FROM PHRM_TXN_InvoiceReturnItems IRI
		INNER JOIN PHRM_TXN_InvoiceReturn IR ON IR.InvoiceReturnId = IRI.InvoiceReturnId
		INNER JOIN PHRM_TXN_InvoiceItems IItem ON IItem.InvoiceItemId = IRI.InvoiceItemId
		INNER JOIN PHRM_MST_Store store ON IR.StoreId = store.StoreId
		INNER JOIN EMP_Employee E ON IR.CreatedBy = E.EmployeeId
		WHERE IRI.ItemId = @ItemId
			AND CONVERT(DATE, IR.CreatedOn) BETWEEN @fromDate
				AND @toDate
		
		UNION
		
		-- Dispatches/Transfers
		SELECT DI.DispatchedDate AS [TransactionDate]
			,'TR' AS [ReferenceNoPrefix]
			,'' AS [ReferenceName]
			,DI.DispatchItemsId AS [ReferenceNo]
			,DI.DispatchId AS [ReferencePrintNo]
			,'Transfer/Dispatch' AS [Type]
			,(SUM(ST.InQty)) AS [StockIn]
			,(SUM(ST.OutQty)) AS [StockOut]
			,ST.CostPrice AS [Rate]
			,ST.SalePrice AS [SalePrice]
			,CONVERT(VARCHAR, ST.ExpiryDate, 23) AS [ExpiryDate]
			,store.Name AS StoreName
			,E.FullName AS UserName
		FROM PHRM_TXN_StockTransaction ST
		INNER JOIN PHRM_StoreDispatchItems DI ON ST.ReferenceNo = DI.DispatchItemsId
		INNER JOIN PHRM_MST_Store store ON ST.StoreId = store.StoreId
		INNER JOIN EMP_Employee E ON (
				ST.OutQty > 0
				AND DI.CreatedBy = E.EmployeeId
				)
			OR (
				ST.InQty > 0
				AND DI.ReceivedById = E.EmployeeId
				)
		WHERE ST.TransactionType IN (
				'transfer-item'
				,'dispensary-dispatched-item'
				,'dispatched-item'
				)
			AND ST.ItemId = @ItemId
			AND CONVERT(DATE, ST.TransactionDate) BETWEEN @fromDate
				AND @toDate
		GROUP BY DI.DispatchItemsId
			,DI.DispatchedDate
			,DI.DispatchId
			,ST.CostPrice
			,ST.SalePrice
			,ST.ExpiryDate
			,store.Name
			,E.FullName
		) ItemTxns
	ORDER BY ItemTxns.TransactionDate
END