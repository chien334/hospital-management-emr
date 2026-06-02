CREATE PROCEDURE [dbo].[SP_PHRMReport_BatchStockReport] @ItemName VARCHAR(200) = NULL
AS
/*
FileName: [SP_PHRMReport_BatchStockReport]
CreatedBy/date: Umed/2018-02-22
Description: To get the Details Such As ItemTypeName, ItemCode, AvailableQty,ExpiryDate,BatchNo, PurchaseRate, PurchaseValue, SalesRate, SalesVale of Each Item Selected By User BatchWise
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Umed/2018-02-22	                 created the script
										(To get the Details Such As ItemTypeName, ItemCode, AvailableQty,ExpiryDate,BatchNo, PurchaseRate, PurchaseValue, SalesRate, SalesVale of Each Item Selected By User BatchWise)
2       Umed/2018-02-23					Modified Sp i.e correction in SalePrice and SaleValue Field 
										(previously i am getting Salevale= SaleQty*Price but Write is SaleValue= AvailQty*Price and Added IsNull on some Attribute)
3		Rusha/2019-04-10				Modify Batch report showing stocks according to batchwise 
4		Vikas/2019-06-07				modify table name PHRM_StockTxnItem to PHRM_DispensarStock, get data from PHRM_DispensaryStock table
5.		Naveed/2019-12-13				updated script for exclude zero quantity Items from Report
6.      Rohit/13Feb'23						MRP-> SalePrice
*/
BEGIN
	IF (@ItemName IS NOT NULL)
	BEGIN
		SELECT (
				CAST(ROW_NUMBER() OVER (
						ORDER BY itm.ItemName
						) AS INT)
				) AS SN
			,stk.ItemId
			,stk.BatchNo
			,itm.ItemName
			,gen.GenericName
			,stk.ExpiryDate
			,stk.AvailableQuantity AS TotalQty
			,stk.SalePrice
		FROM PHRM_DispensaryStock AS stk
		JOIN PHRM_MST_Item AS itm ON stk.ItemId = itm.ItemId
		JOIN PHRM_MST_Generic gen ON itm.GenericId = gen.GenericId
		WHERE BatchNo LIKE '%' + ISNULL(@ItemName, '') + '%'
			AND stk.AvailableQuantity > 0
		GROUP BY stk.ItemId
			,stk.BatchNo
			,itm.ItemName
			,stk.SalePrice
			,gen.GenericName
			,stk.ExpiryDate
			,stk.AvailableQuantity
	END
END