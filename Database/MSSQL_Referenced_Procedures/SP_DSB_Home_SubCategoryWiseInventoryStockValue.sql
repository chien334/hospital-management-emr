CREATE PROCEDURE [dbo].[SP_DSB_Home_SubCategoryWiseInventoryStockValue]
  @SourceStoreId INT = NULL
AS
/*
FileName: [SP_DSB_Home_SubCategoryWiseInventoryStockValue]
CreatedBy/date: Rajib/2022-Sept-13
Description: to get dashboard statistics of the home dashboards. these are used to fill labels.
Remarks:  
NOTE:  
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Rajib/2022-Sept-13               created

*/
BEGIN
			 IF ((@SourceStoreId IS NOT NULL) )
	
		SELECT  
				TOP(10)
				Isub.SubCategoryId, 
				Isub.SubCategoryName, 
				sum(stck.AvailableQuantity) as AvailableQuantity 
		FROM  INV_TXN_StoreStock Stck 
				join INV_MST_Item Item on Stck.ItemId = Item.ItemId 
				join INV_MST_ItemSubCategory Isub on Item.SubCategoryId = Isub.SubCategoryId 
				Where 
				Stck.StoreId = @SourceStoreId
		GROUP BY 
			Isub.SubCategoryName,Isub.SubCategoryId
		 order by 
			AvailableQuantity DESC
END