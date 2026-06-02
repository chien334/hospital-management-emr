CREATE PROCEDURE [dbo].[SP_PHRMReport_StockManageDetailReport] @FromDate DATETIME = NULL
	,@ToDate DATETIME = NULL
AS
/*
FileName: SP_PHRMReport_StockManageDetailReport
CreatedBy/date:Salakha/18/09/2018
Description: .
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Salakha/18/09/2018	                     created the script
2.      Vikas/2019-01-02						 modify sp for Stock management remark.
3.		Rusha/2019-03-05						 add SalePrice,Price and Total amt of stock
4.		Naveed/2019-12-13						 updated script for exclude zero quantity Items
5.		Rusha/ 2020-07-24						Old script used to show dispensary and store item manage but now only from store
												item can be manage, so now report will show only list of those items manage in store only 
6.     Sanjesh/2021-05-11                       Order by StoreStockId for stock management data
7.     Rohit/13Feb'23						    MRP-> SalePrice
*/
BEGIN
	IF (
			(@FromDate IS NOT NULL)
			AND (@ToDate IS NOT NULL)
			)
	BEGIN
		SELECT convert(DATE, stkMng.CreatedOn) AS [Date]
			,itm.ItemName
			,stkMng.BatchNo
			,stkMng.ExpiryDate
			,stkMng.Quantity
			,stkMng.Remark
			,CASE 
				WHEN stkMng.InOut = 'in'
					THEN 'stock added'
				ELSE 'stock deducted'
				END AS InOut
			,stkMng.SalePrice
			,stkMng.Price
			,Round(stkMng.SalePrice * stkMng.Quantity, 2, 0) AS TotalAmount
		FROM PHRM_StoreStock stkMng
		INNER JOIN PHRM_MST_Item itm ON itm.ItemId = stkMng.ItemId
		WHERE convert(DATETIME, stkMng.CreatedOn) BETWEEN ISNULL(@FromDate, GETDATE())
				AND ISNULL(@ToDate, GETDATE()) + 1
			AND stkMng.Quantity > 0
			AND stkMng.TransactionType = 'stockmanage'
		ORDER BY stkMng.StoreStockId DESC
	END
END