CREATE PROCEDURE [dbo].[SP_WardReport_StockReport]  
	    @ItemId int = null	, @StoreId int = null	
AS
/*
FileName: [SP_WardReport_StockReport]
CreatedBy/date: Rusha/03-24-2019
Description: To get the Stock Details Such As ItemName, BatchNo, AvailableQty of Each Item Selected By User 
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1.		Rusha/03-24-2019					   shows stock details by item wise
2.		Sanjit/02-03-2020					   substore integration
*/

BEGIN
  IF (@ItemId !=0)
		BEGIN
			select gen.GenericName,itm.ItemName,ward.BatchNo,sum(AvailableQuantity) as Quantity,ward.ExpiryDate, MRP from WARD_Stock as ward 
			join PHRM_MST_Item as itm on ward.ItemId= itm.ItemId 
			join PHRM_MST_Generic as gen on itm.GenericId = gen.GenericId  
			where itm.ItemId =@ItemId and ward.StoreId = @StoreId
			group by ItemName, MRP ,GenericName, ward.BatchNo, ward.ExpiryDate
		END	
		else if (@ItemId =0)	
		begin 
		select gen.GenericName,itm.ItemName,ward.BatchNo,sum(AvailableQuantity) as Quantity,ward.ExpiryDate, MRP from WARD_Stock as ward 
			join PHRM_MST_Item as itm on ward.ItemId= itm.ItemId 
			join PHRM_MST_Generic as gen on itm.GenericId = gen.GenericId
			where ward.StoreId = @StoreId
			--where itm.ItemId  like '%'+isnull (@ItemId,'')+'%'
			group by ItemName, MRP,GenericName, ward.BatchNo, ward.ExpiryDate
		end
End