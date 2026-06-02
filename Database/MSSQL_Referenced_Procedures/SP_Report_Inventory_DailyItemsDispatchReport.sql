CREATE PROCEDURE [dbo].[SP_Report_Inventory_DailyItemsDispatchReport] 
	 @FromDate DATE = NULL
	,@ToDate DATE = NULL
	,@StoreId INT = NULL
AS
/*
FileName: [SP_Report_Inventory_DailyItemsDispatchReport] 
CreatedBy/date: Umed/2017-06-21
Description: to get Details such as itemNames , total dispatch qty of particular item with total amount generated between given dates along with StoreName.
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Umed/2017-06-21                     created the script
2       Rusha/2019-06-06                    updated the script
3       Ramesh/2020-04-14                   updated the script
4.		NIRMALA/ROHIT						group by with CostPrice
*/
	BEGIN
		SELECT IC.ItemCategoryName 'CategoryName'
			,ISUB.SubCategoryName 'SubCategory'
			,I.ItemName 'ItemName'
			,U.UOMName 'Unit'
			,SUM(ISNULL(D.DispatchedQuantity, 0)) 'DispatchedQty'
			,D.CostPrice
			,SUM(ISNULL((D.DispatchedQuantity * D.CostPrice), 0)) AS 'TotalDispatchedValue'
			,S.Name 'Substore' 
			,CONVERT(DATE,D.DispatchedDate) 'DispatchedDate'
		FROM INV_TXN_DispatchItems D
		INNER JOIN PHRM_MST_Store AS S ON D.TargetStoreId = S.StoreId
		INNER JOIN INV_MST_Item AS I ON I.ItemId = D.ItemId
		INNER JOIN INV_MST_ItemCategory AS IC ON I.ItemCategoryId = IC.ItemCategoryId
		INNER JOIN INV_MST_ItemSubCategory AS ISUB ON I.SubCategoryId = ISUB.SubCategoryId
		LEFT JOIN INV_MST_UnitOfMeasurement U ON I.UnitOfMeasurementId = U.UOMId
		WHERE CONVERT(DATE,D.DispatchedDate) BETWEEN @FromDate AND @ToDate
			AND (
				D.TargetStoreId = @StoreId
				OR @StoreId IS NULL
				)
		GROUP BY IC.ItemCategoryName
			,ISUB.SubCategoryName
			,I.ItemName
			,U.UOMName
			,D.CostPrice
			,S.Name
			,DispatchedDate
		ORDER BY DispatchedDate DESC
	END