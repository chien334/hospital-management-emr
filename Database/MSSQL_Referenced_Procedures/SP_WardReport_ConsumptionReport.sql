CREATE PROCEDURE [dbo].[SP_WardReport_ConsumptionReport]  
	@FromDate datetime=null,
	@ToDate datetime=null,
	@StoreId int = null
AS
/*
FileName: [SP_WardReport_ConsumptionReport]
CreatedBy/date: Rusha/03-26-2019
Description: To get the Consumption Details of Items From different Ward 
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1.		Rusha/03-29-2019					   add stock details of consumed item from different ward
2.		Sanjit/02-03-2020						substore integration
3.      Rajib/02-26-2020						Update InvoiceItemId
*/

BEGIN
  IF ((@FromDate IS NOT NULL) and (@ToDate IS NOT NULL) and (@StoreId IS NOT NULL))
		BEGIN
			select CONVERT(date,consum.CreatedOn) as [Date], consum.ItemName, gene.GenericName, consum.Quantity as Quantity 
			FROM WARD_Consumption as consum 
			join PHRM_MST_Item as itm on consum.ItemId=itm.ItemId
			join PHRM_MST_Generic as gene on  itm.GenericId=gene.GenericId
			where consum.StoreId = @StoreId and CONVERT(date, consum.CreatedOn) BETWEEN ISNULL(@FromDate,GETDATE())  AND ISNULL(@ToDate,GETDATE())+1
			group by CONVERT(date,consum.CreatedOn),consum.ItemName,consum.Quantity, gene.GenericName,consum.InvoiceItemId
		END		
END