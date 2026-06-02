CREATE PROCEDURE [dbo].[SP_DSB_Home_DeptWiseConsumerItems]
  @SourceStoreId INT = NULL
AS
/*
FileName: [SP_DSB_Home_DeptWiseConsumerItems]
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
	  Dis.TargetStoreId, 
	 phrm.Name, 
	 SUM( Dis.DispatchedQuantity ) as DispatchedQuantity 
	from PHRM_MST_Store  phrm 
	Join  INV_TXN_DispatchItems Dis on phrm.StoreId = Dis.TargetStoreId 
	Where 
	Dis.SourceStoreId = @SourceStoreId 
	GROUP BY
	phrm.Name,Dis.TargetStoreId
	order by DispatchedQuantity DESC
  
END