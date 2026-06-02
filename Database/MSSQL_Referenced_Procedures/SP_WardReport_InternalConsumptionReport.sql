CREATE PROCEDURE [dbo].[SP_WardReport_InternalConsumptionReport]  
	@FromDate datetime=null,
	@ToDate datetime=null,
	@StoreId int = null
AS
/*
FileName: [SP_WardReport_InternalConsumptionReport] '2018-01-01', '2020-02-18',2
CreatedBy/date: Rajib/02-10-2020
Description: To get the Internal Consumption Details of Items From different Ward 
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1.		Rajib/2/18/2020							Update StoreId
2.		Rajib/2/26/2020							Update ConsumptionItemId
*/

BEGIN
  IF ((@FromDate IS NOT NULL) and (@ToDate IS NOT NULL)and (@StoreId IS NOT NULL) )
		BEGIN
			select CONVERT(date,consum.CreatedOn) as [ConsumedDate], depitm.DepartmentName,consumitem.ItemName, consum.ConsumedBy, consumitem.Quantity as Quantity 
			from WARD_InternalConsumption as consum 
			join WARD_InternalConsumptionItems as consumitem on consum.ConsumptionId=consumitem.ConsumptionId
			join MST_Department as depitm on consum.DepartmentId=depitm.DepartmentId
			where consum.SubStoreId = @StoreId and CONVERT(date, consum.CreatedOn) BETWEEN ISNULL(@FromDate,GETDATE())  AND ISNULL(@ToDate,GETDATE())+1
			group by CONVERT(date,consum.CreatedOn),depitm.DepartmentName,consumitem.ItemName,consum.ConsumedBy,consumitem.Quantity,consumitem.ConsumptionItemId
		END		
End