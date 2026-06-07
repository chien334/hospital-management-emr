CREATE OR REPLACE FUNCTION sp_phrmreport_itemtxnsummaryreport(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_itemid INT DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
BEGIN
    /*
      filename: "sp_phrmreport_itemtxnsummaryreport"
      createdby/date: sanjit/2021-01-20
      description: 
      1. created to find all the item txn as a part of stock summary report in pharmacy
      example to execute:
      exec sp_phrmreport_itemtxnsummaryreport '2021-06-15', '2021-09-01', 9
      change history
      s.no.    updatedby/date                        remarks
      1       sanjit/2021-01-20          created the script.
      2       sanjesh/2021-02-21         added reference name 
      3		  sanjit/2021-09-01			 added storename, username. added transfers and opening data	
      4       ramesh/2021-09-26          invoicereturnid added as referenceno for invoice return 
              rohit/13feb'23		     MRP-> SalePrice
    */
    
    	OPEN ref1 FOR SELECT TransactionDate
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
    		SELECT FYS.CreatedOn AS "TransactionDate"
    			,'opening' AS "ReferenceNoPrefix"
    			,'' AS "ReferenceName"
    			,NULL AS "ReferenceNo"
    			,NULL AS "ReferencePrintNo"
    			,'opening' AS "Type"
    			,COALESCE(FYS.OpeningQuantity, 0) AS "StockIn"
    			,0 AS "StockOut"
    			,FYS.CostPrice AS "Rate"
    			,FYS.SalePrice AS "SalePrice"
    			,to_char(FYS.ExpiryDate, 'yyyy-mm-dd') AS "ExpiryDate"
    			,store.Name AS StoreName
    			,E.FullName AS UserName
    		FROM PHRM_FiscalYearStock AS FYS
    		INNER JOIN PHRM_MST_Store store ON FYS.StoreId = store.StoreId
    		INNER JOIN EMP_Employee E ON FYS.CreatedBy = E.EmployeeId
    		WHERE (FYS.ItemId = p_itemid)
    			AND (
    				(FYS.CreatedOn)::DATE BETWEEN p_fromdate
    					AND p_todate
    				)
    		
    		UNION
    		
    		--Purchase from Goods Receipt Table
    		SELECT GR.GoodReceiptDate AS "TransactionDate"
    			,'gr' AS "ReferenceNoPrefix"
    			,Supp.SupplierName AS "ReferenceName"
    			,GR.GoodReceiptId AS "ReferenceNo"
    			,GR.GoodReceiptPrintId AS "ReferencePrintNo"
    			,'purchase' AS "Type"
    			,COALESCE(GRI.ReceivedQuantity, 0) + COALESCE(GRI.FreeQuantity, 0) AS "StockIn"
    			,0 AS "StockOut"
    			,GRI.GRItemPrice AS "Rate"
    			,GRI.SalePrice AS "SalePrice"
    			,to_char(GRI.ExpiryDate, 'yyyy-mm-dd') AS "ExpiryDate"
    			,store.Name AS StoreName
    			,E.FullName AS UserName
    		FROM PHRM_GoodsReceiptItems AS GRI
    		INNER JOIN PHRM_GoodsReceipt AS GR ON GR.GoodReceiptId = GRI.GoodReceiptId
    		INNER JOIN PHRM_MST_Supplier AS Supp ON gr.SupplierId = Supp.SupplierId
    		INNER JOIN PHRM_MST_Store store ON GR.StoreId = store.StoreId
    		INNER JOIN EMP_Employee E ON GR.CreatedBy = E.EmployeeId
    		WHERE (GRI.ItemId = p_itemid)
    			AND (
    				(GR.GoodReceiptDate)::DATE BETWEEN p_fromdate
    					AND p_todate
    				)
    		
    		UNION
    		
    		-- Purchase Return from Return To Supplier
    		SELECT RTS.ReturnDate AS "TransactionDate"
    			,'rts' AS "ReferenceNoPrefix"
    			,Supp.SupplierName AS "ReferenceName"
    			,RTS.CreditNoteId AS "ReferenceNo"
    			,RTS.CreditNotePrintId AS "ReferencePrintNo"
    			,'purchasereturn' AS "Type"
    			,0 AS "StockIn"
    			,(COALESCE(RTSI.Quantity, 0) + COALESCE(RTSI.FreeQuantity, 0)) AS "StockOut"
    			,RTSI.ItemPrice AS "Rate"
    			,RTSI.SalePrice AS "SalePrice"
    			,to_char(RTSI.ExpiryDate, 'yyyy-mm-dd') AS "ExpiryDate"
    			,'main store' AS StoreName
    			,E.FullName AS UserName
    		FROM PHRM_ReturnToSupplierItems RTSI
    		INNER JOIN PHRM_ReturnToSupplier RTS ON RTSI.ReturnToSupplierId = RTS.ReturnToSupplierId
    		INNER JOIN PHRM_MST_Supplier Supp ON rts.SupplierId = Supp.SupplierId
    		INNER JOIN EMP_Employee E ON RTS.CreatedBy = E.EmployeeId
    		WHERE RTSI.ItemId = p_itemid
    			AND (RTS.ReturnDate)::DATE BETWEEN p_fromdate
    				AND p_todate
    		
    		UNION
    		
    		--Purchase Cancel , txn type = cancel-gr
    		SELECT GR.GoodReceiptDate AS "TransactionDate"
    			,'cgr' AS "ReferenceNoPrefix"
    			,NULL AS "ReferenceName"
    			,GR.GoodReceiptId AS "ReferenceNo"
    			,GR.GoodReceiptPrintId AS "ReferencePrintNo"
    			,'purchasecancel' AS "Type"
    			,COALESCE(GRI.ReceivedQuantity, 0) + COALESCE(GRI.FreeQuantity, 0) AS "StockIn"
    			,0 AS "StockOut"
    			,GRI.GRItemPrice AS "Rate"
    			,GRI.SalePrice AS "SalePrice"
    			,to_char(GRI.ExpiryDate, 'yyyy-mm-dd') AS "ExpiryDate"
    			,store.Name AS StoreName
    			,E.FullName AS UserName
    		FROM PHRM_GoodsReceiptItems AS GRI
    		INNER JOIN PHRM_GoodsReceipt AS GR ON GR.GoodReceiptId = GRI.GoodReceiptId
    		INNER JOIN PHRM_MST_Store store ON GR.StoreId = store.StoreId
    		INNER JOIN EMP_Employee E ON GR.CreatedBy = E.EmployeeId
    		WHERE (GRI.ItemId = p_itemid)
    			AND GR.IsCancel = 1
    			AND (
    				(GR.GoodReceiptDate)::DATE BETWEEN p_fromdate
    					AND p_todate
    				)
    		
    		UNION
    		
    		--StockManageIn from PHRM_StoreStock
    		SELECT S.TransactionDate AS "TransactionDate"
    			,'smi' AS "ReferenceNoPrefix"
    			,'' AS "ReferenceName"
    			,S.ReferenceNo AS "ReferenceNo"
    			,S.ReferenceNo AS "ReferencePrintNo"
    			,'stockmanagein' AS "Type"
    			,COALESCE(S.InQty, 0) AS "StockIn"
    			,0 AS "StockOut"
    			,S.CostPrice AS "Rate"
    			,S.SalePrice AS "SalePrice"
    			,to_char(S.ExpiryDate, 'yyyy-mm-dd') AS "ExpiryDate"
    			,store.Name AS StoreName
    			,E.FullName AS UserName
    		FROM PHRM_TXN_StockTransaction S
    		INNER JOIN PHRM_MST_Store store ON S.StoreId = store.StoreId
    		INNER JOIN EMP_Employee E ON S.CreatedBy = E.EmployeeId
    		WHERE TransactionType = 'stock-managed-item'
    			AND S.InQty > 0
    			AND S.ItemId = p_itemid
    			AND (S.TransactionDate)::DATE BETWEEN p_fromdate
    				AND p_todate
    		
    		UNION
    		
    		--StockManageOut from PHRM_StoreStock
    		SELECT S.TransactionDate AS "TransactionDate"
    			,'smo' AS "ReferenceNoPrefix"
    			,'' AS "ReferenceName"
    			,S.ReferenceNo AS "ReferenceNo"
    			,S.ReferenceNo AS "ReferencePrintNo"
    			,'stockmanageout' AS "Type"
    			,0 AS "StockIn"
    			,COALESCE(S.OutQty, 0) AS "StockOut"
    			,S.CostPrice AS "Rate"
    			,S.SalePrice AS "SalePrice"
    			,to_char(S.ExpiryDate, 'yyyy-mm-dd') AS "ExpiryDate"
    			,store.Name AS StoreName
    			,E.FullName AS UserName
    		FROM PHRM_TXN_StockTransaction S
    		INNER JOIN PHRM_MST_Store store ON S.StoreId = store.StoreId
    		INNER JOIN EMP_Employee E ON S.CreatedBy = E.EmployeeId
    		WHERE TransactionType = 'stock-managed-item'
    			AND S.OutQty > 0
    			AND S.ItemId = p_itemid
    			AND (S.TransactionDate)::DATE BETWEEN p_fromdate
    				AND p_todate
    		
    		UNION
    		
    		-- Sale from Invoice Table
    		SELECT I.CreateOn AS "TransactionDate"
    			,'ph' AS "ReferenceNoPrefix"
    			,pat.ShortName AS "ReferenceName"
    			,I.InvoiceId AS "ReferenceNo"
    			,I.InvoicePrintId AS "ReferencePrintNo"
    			,'sale' AS "Type"
    			,0 AS "StockIn"
    			,(COALESCE(IItem.Quantity, 0) + COALESCE(IItem.FreeQuantity, 0)) AS "StockOut"
    			,IItem.Price AS "Rate"
    			,IItem.SalePrice AS "SalePrice"
    			,to_char(IItem.ExpiryDate, 'yyyy-mm-dd') AS "ExpiryDate"
    			,store.Name AS StoreName
    			,E.FullName AS UserName
    		FROM PHRM_TXN_InvoiceItems IItem
    		INNER JOIN PHRM_TXN_Invoice I ON I.InvoiceId = IItem.InvoiceId
    		INNER JOIN PAT_Patient pat ON I.PatientId = pat.PatientId
    		INNER JOIN PHRM_MST_Store store ON I.StoreId = store.StoreId
    		INNER JOIN EMP_Employee E ON I.CreatedBy = E.EmployeeId
    		WHERE IItem.ItemId = p_itemid
    			AND (I.CreateOn)::DATE BETWEEN p_fromdate
    				AND p_todate
    		
    		UNION
    		
    		-- Sales Return from Invoice Return Table
    		SELECT IR.CreatedOn AS "TransactionDate"
    			,'cr-ph' AS "ReferenceNoPrefix"
    			,NULL AS "ReferenceName"
    			,IR.InvoiceReturnId AS "ReferenceNo"
    			,IR.CreditNoteID AS "ReferencePrintNo"
    			,'salerefund' AS "Type"
    			,(COALESCE(IRI.ReturnedQty, 0)) AS "StockIn"
    			,0 AS "StockOut"
    			,IRI.Price AS "Rate"
    			,IRI.SalePrice AS "SalePrice"
    			,to_char(IItem.ExpiryDate, 'yyyy-mm-dd') AS "ExpiryDate"
    			,store.Name AS StoreName
    			,E.FullName AS UserName
    		FROM PHRM_TXN_InvoiceReturnItems IRI
    		INNER JOIN PHRM_TXN_InvoiceReturn IR ON IR.InvoiceReturnId = IRI.InvoiceReturnId
    		INNER JOIN PHRM_TXN_InvoiceItems IItem ON IItem.InvoiceItemId = IRI.InvoiceItemId
    		INNER JOIN PHRM_MST_Store store ON IR.StoreId = store.StoreId
    		INNER JOIN EMP_Employee E ON IR.CreatedBy = E.EmployeeId
    		WHERE IRI.ItemId = p_itemid
    			AND (IR.CreatedOn)::DATE BETWEEN p_fromdate
    				AND p_todate
    		
    		UNION
    		
    		-- Dispatches/Transfers
    		SELECT DI.DispatchedDate AS "TransactionDate"
    			,'tr' AS "ReferenceNoPrefix"
    			,'' AS "ReferenceName"
    			,DI.DispatchItemsId AS "ReferenceNo"
    			,DI.DispatchId AS "ReferencePrintNo"
    			,'transfer/dispatch' AS "Type"
    			,(SUM(ST.InQty)) AS "StockIn"
    			,(SUM(ST.OutQty)) AS "StockOut"
    			,ST.CostPrice AS "Rate"
    			,ST.SalePrice AS "SalePrice"
    			,to_char(ST.ExpiryDate, 'yyyy-mm-dd') AS "ExpiryDate"
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
    			and st.itemid = p_itemid
    			and (st.transactiondate)::date between p_fromdate
    				and p_todate
    		group by di.dispatchitemsid
    			,di.dispatcheddate
    			,di.dispatchid
    			,st.costprice
    			,st.saleprice
    			,st.expirydate
    			,store.name
    			,e.fullname
    		) itemtxns
    	order by itemtxns.transactiondate;
        return next ref1;
END;
$$ LANGUAGE plpgsql;