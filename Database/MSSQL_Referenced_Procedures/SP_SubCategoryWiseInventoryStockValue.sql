CREATE PROCEDURE [dbo].[SP_SubCategoryWiseInventoryStockValue] 
@SourceStoreId INT = NULL
AS
/*
FileName: [SP_SubCategoryWiseInventoryStockValue]
CreatedBy/date: ROHIT/2Dec'22
Description: To get subcategory wise inventory stock value 
Remarks:  
NOTE:  
Change History
S.No.    UpdatedBy/Date                        Remarks
1       ROHIT/2Dec'22							 created
*/
BEGIN
	SELECT Isub.SubCategoryName
		,ROUND(SUM(stck.AvailableQuantity), 3) AS AvailableQuantity
		,ROUND(SUM(stck.AvailableQuantity * stck.CostPrice), 3) AS TotalStockValue
	FROM INV_TXN_StoreStock Stck
	JOIN INV_MST_Item Item ON Stck.ItemId = Item.ItemId
	JOIN INV_MST_ItemSubCategory Isub ON Item.SubCategoryId = Isub.SubCategoryId
	WHERE (
			Stck.StoreId = @SourceStoreId
			OR @SourceStoreId IS NULL
			)
	GROUP BY Isub.SubCategoryName
	ORDER BY AvailableQuantity DESC
END