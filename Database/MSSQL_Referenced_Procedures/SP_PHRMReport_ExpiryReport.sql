CREATE PROCEDURE [dbo].[SP_PHRMReport_ExpiryReport]
	--[SP_PHRMReport_ExpiryReport] null, null,'2021-05-01','2040-05-10'
	@ItemId INT = NULL
	,@StoreId INT = NULL
	,@FromDate DATE = NULL
	,@ToDate DATE = NULL
AS
/*
FileName: [SP_PHRMReport_ExpiryReport]
CreatedBy/date: Abhishek/2018-05-06
Description: To get the Expired Products Details Such As ItemName, ItemCode, AvailableQty,ExpiryDate,BatchNo of Each Item Selected By User Datewise
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1.		Rusha/04-03-2019						Updated INOUT Quantity
2.		Vikas/07-06-2019						update table name, get data from PHRM_DispensaryStock table
3.      Naveed/13-12-2019                       Convert Expiry Date to varchar for showing well format date while Export
4.		Bikash/12-01-2020						items with generic name as surgical removed.
5.      Sanjit/Ramesh/10-05-2021                Show the Stocks expiry selecting available Stores.Also Date Filter added.
6.      Sanjit/10-06-2021                       Removed Dispensary Stock part and calculated from store stock table (Pharmacy Stock Redesign Impact Analysis)
7.      Ramesh/13-03-2021                       Supplier Name is Added in the report.
8.		Rohit/2Feb'22							Added filter to get only expired and nearly expired item(3 month)
9       Rohit/13Feb'23						    MRP-> SalePrice
*/
BEGIN
	SELECT (
			Cast(ROW_NUMBER() OVER (
					ORDER BY x.ItemName
					) AS INT)
			) AS SN
		,x.*
	FROM (
		SELECT t1.ItemId
			,t1.BatchNo
			,t1.ExpiryDate
			,t1.SalePrice
			,t1.CostPrice
			,item.ItemName
			,generic.GenericName
			,SUM(t2.AvailableQuantity) AS AvailableQuantity
			,store.Name
			,ISNULL(Supplier.SupplierName, '') AS SupplierName
		FROM PHRM_MST_Stock AS t1
		INNER JOIN PHRM_TXN_StoreStock AS t2 ON t1.StockId = t2.StockId
		LEFT JOIN PHRM_GoodsReceiptItems AS GRI ON t2.StoreStockId = GRI.StoreStockId
		LEFT JOIN PHRM_GoodsReceipt AS GR ON GRI.GoodReceiptId = GR.GoodReceiptId
		LEFT JOIN PHRM_MST_Supplier Supplier ON GR.SupplierId = Supplier.SupplierId
		INNER JOIN PHRM_MST_Item AS item ON item.ItemId = t1.ItemId
		INNER JOIN PHRM_MST_Generic AS generic ON generic.GenericId = item.GenericId
		INNER JOIN PHRM_MST_Store AS store ON store.StoreId = t2.StoreId
		WHERE (
				t1.ItemId = @ItemId
				OR @ItemId IS NULL
				)
			AND (
				t2.StoreId = @StoreId
				OR @StoreId IS NULL
				)
			AND CONVERT(DATE, t1.ExpiryDate) BETWEEN @FromDate
				AND CONVERT(DATE, DATEADD(MONTH, 3, @ToDate))
			AND (t2.AvailableQuantity > 0)
			AND (generic.GenericName NOT LIKE '%SURGICAL%')
		GROUP BY t1.ItemId
			,t1.BatchNo
			,t1.ExpiryDate
			,t1.SalePrice
			,t1.CostPrice
			,item.ItemName
			,generic.GenericName
			,store.Name
			,Supplier.SupplierName
		) AS x
END