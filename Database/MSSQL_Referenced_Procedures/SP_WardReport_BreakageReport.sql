CREATE PROCEDURE [dbo].[SP_WardReport_BreakageReport]  		
	@FromDate datetime=null,
	@ToDate datetime=null,
	@StoreId int = null
AS
/*
FileName: [SP_WardReport_BreakageReport]
CreatedBy/date: Rusha/03-26-2019
Description: To get the Details of Breakage Items From different Ward 
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1.		Rusha/03-29-2019					   get details of breakage items
2.		Sanjit/02-03-2020						substore integration
*/

BEGIN
  IF ((@FromDate IS NOT NULL) and (@ToDate IS NOT NULL) and (@StoreId IS NOT NULL))
		BEGIN
			select convert(date,transc.CreatedOn) as [Date], ItemName, transc.Quantity,stk.MRP,
			Round(stk.MRP*transc.Quantity,2,0) as TotalAmt,transc.Remarks 
			FROM WARD_Transaction as transc
			join PHRM_MST_Item as itm on transc.ItemId=itm.ItemId
			join WARD_Stock as stk on transc.StockId=stk.StockId and transc.ItemId = stk.ItemId 
			where transc.StoreId = @StoreId and TransactionType = 'BreakageItem' and CONVERT(date, transc.CreatedOn) 
			BETWEEN ISNULL(@FromDate,GETDATE())  AND ISNULL(@ToDate,GETDATE())+1
			group by convert(date,transc.CreatedOn), itm.ItemName, transc.Quantity,transc.Remarks,stk.MRP,transc.Quantity
		END	
End