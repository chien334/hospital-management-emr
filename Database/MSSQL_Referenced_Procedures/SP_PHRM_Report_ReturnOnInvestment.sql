/* =================================================  
 Author:      Sanjit  
 Create date: 2022-06-22  
 Description: The report shows the profit%, return of investment for each stock in the system  
 Example:   EXEC SP_PHRM_Report_ReturnOnInvestment @FromDate = '2022-01-08', @ToDate = '2022-01-14'  
 ===================================================  
 SP History  
 ===================================================  
 SN. Update Date  Updated by  Description  
 1.  22Jun'22	  Sanjit      Get Return On Investment Report Data  
 2.  11Jul'22	  Sanjit      Purchase Returns added in calculation
 3.  Rohit/13Feb'23						MRP-> SalePrice
 ===================================================  
*/
CREATE PROCEDURE SP_PHRM_Report_ReturnOnInvestment @FromDate DATE
	,@ToDate DATE
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from  
	-- interfering with SELECT statements.  
	SET NOCOUNT ON;

	SELECT S.SupplierName
		,GR.GoodReceiptPrintId
		,GR.GoodReceiptDate AS TransactionDate
		,I.ItemName
		,GRI.BatchNo
		,GRI.GRItemPrice AS ItemRate
		,
		-- discountOnRate = (discountPercent * rate)/100
		CONVERT(DECIMAL(18, 4), (GRI.GRItemPrice * GRI.DiscountPercentage) / 100) AS DiscountOnRate
		,
		-- rate after discount = rate - discountOnRate
		CONVERT(DECIMAL(18, 4), GRI.GRItemPrice - ((GRI.GRItemPrice * GRI.DiscountPercentage) / 100)) AS RateAfterDiscount
		,
		-- invoicedQty = purchaseQty - returnedQty (if any)
		GRI.ReceivedQuantity - ISNULL(RTSI.Quantity, 0) AS InvoicedQuantity
		,
		-- freeQty = freeQtyReceivedOnPurchase - freeQtyReturned (if any)
		GRI.FreeQuantity - ISNULL(RTSI.FreeQuantity, 0) AS FreeQuantity
		,
		-- totalQty = invoicedQty - freeQty (ref from above)
		GRI.ReceivedQuantity + GRI.FreeQuantity - ISNULL(RTSI.Quantity, 0) - ISNULL(RTSI.FreeQuantity, 0) AS TotalQuantity
		,
		-- totalTax = vatOnPurchase -  vatOnReturn = ((vatPercentage * subTotalWithDiscount )/100) - vatOnReturn
		CONVERT(DECIMAL(18, 4), GRI.VATPercentage * (GRI.ReceivedQuantity * GRI.GRItemPrice - ((GRI.ReceivedQuantity * GRI.GRItemPrice * GRI.DiscountPercentage) / 100)) / 100) - ISNULL(RTSI.VATAmount, 0) AS TotalTax
		,
		-- otherCharges = ccAmount - returnCCAmount = (freeQty * rate * ccPercent)/100  - returnCCAmount
		CONVERT(DECIMAL(18, 4), (GRI.FreeQuantity * GRI.GRItemPrice * ISNULL(GRI.CCCharge, 0)) / 100) - ISNULL(RTSI.CCAmount, 0) AS OtherCharges
		,
		-- discountAmount = dicountOnPurchase - discountOnReturn
		CONVERT(DECIMAL(18, 4), (GRI.DiscountPercentage * GRI.GRItemPrice * GRI.ReceivedQuantity) / 100) - ISNULL(RTSI.DiscountedAmount, 0) AS DiscountAmount
		,
		-- totalAmount = totalAmountOnPurchase - totalAmountOnReturn
		GRI.TotalAmount - ISNULL(RTSI.TotalAmount, 0) AS TotalAmount
		,
		-- costPricePerUnit = totalAmount / totalQty  (ref from above)
		CASE 
			WHEN (GRI.ReceivedQuantity + GRI.FreeQuantity - ISNULL(RTSI.Quantity, 0) - ISNULL(RTSI.FreeQuantity, 0)) = 0
				THEN 0
			ELSE CONVERT(DECIMAL(18, 4), (GRI.TotalAmount - ISNULL(RTSI.TotalAmount, 0)) / (GRI.ReceivedQuantity + GRI.FreeQuantity - ISNULL(RTSI.Quantity, 0) - ISNULL(RTSI.FreeQuantity, 0)))
			END AS CostPricePerUnit
		,
		-- stockValue = totalAmountOnPurchase - totalAmountOnReturn
		CONVERT(DECIMAL(18, 4), GRI.TotalAmount - ISNULL(RTSI.TotalAmount, 0)) AS StockValue
		,
		--salesValue = totalQty * SalePrice 
		CONVERT(DECIMAL(18, 4), (GRI.ReceivedQuantity + GRI.FreeQuantity - ISNULL(RTSI.Quantity, 0) - ISNULL(RTSI.FreeQuantity, 0)) * GRI.SalePrice) AS SalesValue
		,
		-- profit = salesValue - stockValue = (totalQty * SalePrice ) - (totalAmountOnPurchase - totalAmountOnReturn)
		CONVERT(DECIMAL(18, 4), ((GRI.ReceivedQuantity + GRI.FreeQuantity - ISNULL(RTSI.Quantity, 0) - ISNULL(RTSI.FreeQuantity, 0)) * GRI.SalePrice) - (GRI.TotalAmount - ISNULL(RTSI.TotalAmount, 0))) AS Profit
		,
		-- profitPercent = ((SalePrice - costPricePerUnit)/SalePrice) * 100
		CASE 
			WHEN GRI.SalePrice = 0
				OR GRI.SalePrice IS NULL
				THEN 0
			WHEN (GRI.ReceivedQuantity + GRI.FreeQuantity - ISNULL(RTSI.Quantity, 0) - ISNULL(RTSI.FreeQuantity, 0)) = 0
				THEN 0
			ELSE CONVERT(DECIMAL(18, 4), ((GRI.SalePrice - ((GRI.TotalAmount - ISNULL(RTSI.TotalAmount, 0)) / (GRI.ReceivedQuantity + GRI.FreeQuantity - ISNULL(RTSI.Quantity, 0) - ISNULL(RTSI.FreeQuantity, 0)))) / GRI.SalePrice) * 100)
			END AS ProfitPercentage
		,
		-- roiPercent = (profit/costPricePerUnit) *100 ((SalePrice-costPricePerUnit) / costPricePerUnit)* 100
		CASE 
			WHEN GRI.TotalAmount = 0
				THEN 0
			WHEN (GRI.ReceivedQuantity + GRI.FreeQuantity - ISNULL(RTSI.Quantity, 0) - ISNULL(RTSI.FreeQuantity, 0)) = 0
				THEN 0
			WHEN (GRI.TotalAmount - ISNULL(RTSI.TotalAmount, 0)) / (GRI.ReceivedQuantity + GRI.FreeQuantity - ISNULL(RTSI.Quantity, 0) - ISNULL(RTSI.FreeQuantity, 0)) <= 0
				THEN 100
			ELSE CONVERT(DECIMAL(18, 4), ((GRI.SalePrice - ((GRI.TotalAmount - ISNULL(RTSI.TotalAmount, 0)) / (GRI.ReceivedQuantity + GRI.FreeQuantity - ISNULL(RTSI.Quantity, 0) - ISNULL(RTSI.FreeQuantity, 0)))) / ((GRI.TotalAmount - ISNULL(RTSI.TotalAmount, 0)) / (GRI.ReceivedQuantity + GRI.FreeQuantity - ISNULL(RTSI.Quantity, 0) - ISNULL(RTSI.FreeQuantity, 0)))) * 100)
			END AS ReturnOnInvestmentPercentage
	FROM PHRM_GoodsReceiptItems GRI
	INNER JOIN PHRM_GoodsReceipt GR ON GRI.GoodReceiptId = GR.GoodReceiptId
	INNER JOIN PHRM_MST_Supplier S ON GR.SupplierId = S.SupplierId
	INNER JOIN PHRM_MST_Item I ON GRI.ItemId = I.ItemId
	LEFT JOIN (
		SELECT RTSI.GoodReceiptItemId
			,SUM(RTSI.Quantity) AS Quantity
			,SUM(RTSI.FreeQuantity) AS FreeQuantity
			,SUM(RTSI.DiscountedAmount) AS DiscountedAmount
			,SUM(RTSI.VATAmount) AS VATAmount
			,SUM(RTSI.CCAmount) AS CCAmount
			,SUM(RTSI.TotalAmount) AS TotalAmount
		FROM PHRM_ReturnToSupplierItems RTSI
		GROUP BY RTSI.GoodReceiptItemId
		) RTSI ON GRI.GoodReceiptItemId = RTSI.GoodReceiptItemId
	WHERE CONVERT(DATE, GR.GoodReceiptDate) BETWEEN @FromDate
			AND @ToDate
		AND ISNULL(GRI.IsCancel, 0) != 1
	
	UNION ALL
	
	SELECT 'OPENING' AS SupplierName
		,NULL AS GoodReceiptPrintId
		,ST.TransactionDate
		,I.ItemName
		,ST.BatchNo
		,ST.CostPrice AS ItemRate
		,0 AS DiscountOnRate
		,ST.CostPrice AS RateAfterDiscount
		,ST.InQty AS InvoicedQuantity
		,0 AS FreeQuantity
		,ST.InQty AS TotalQuantity
		,0 AS TotalTax
		,0 AS OtherCharges
		,0 AS DiscountAmount
		,CONVERT(DECIMAL(18, 4), ST.InQty * ST.CostPrice) AS TotalAmount
		,ST.CostPrice CostPricePerUnit
		,CONVERT(DECIMAL(18, 4), ST.InQty * ST.CostPrice) AS StockValue
		,CONVERT(DECIMAL(18, 4), ST.InQty * ST.SalePrice) AS SalesValue
		,CONVERT(DECIMAL(18, 4), ST.InQty * ST.SalePrice) - CONVERT(DECIMAL(18, 4), ST.InQty * ST.CostPrice) AS Profit
		,CASE 
			WHEN ST.SalePrice = 0
				OR ST.SalePrice IS NULL
				THEN 0
			ELSE CONVERT(DECIMAL(18, 4), ((ST.SalePrice - ST.CostPrice) / ST.SalePrice) * 100)
			END AS ProfitPercentage
		,CASE 
			WHEN ST.CostPrice = 0
				OR ST.CostPrice IS NULL
				THEN 0
			ELSE CONVERT(DECIMAL(18, 4), ((ST.SalePrice - ST.CostPrice) / ST.CostPrice) * 100)
			END AS ReturnOnInvestmentPercentage
	FROM PHRM_TXN_StockTransaction ST
	INNER JOIN PHRM_MST_Item I ON ST.ItemId = I.ItemId
	WHERE CONVERT(DATE, ST.TransactionDate) BETWEEN @FromDate
			AND @ToDate
		AND ST.TransactionType = 'opening-item'
	ORDER BY TransactionDate ASC
END