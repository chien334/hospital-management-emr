CREATE  PROCEDURE [dbo].[SP_DBS_Home_InvDashboardStats]
  @SourceStoreId INT = NULL
AS
/*
FileName: [SP_DBS_Home_InvDashboardStats]
CreatedBy/date: Rajib/2022-Sept-13
Description: to get dashboard statistics of the home dashboards. these are used to fill labels.
Remarks:  
NOTE:  
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Rajib/2022-Sept-16               created

*/
BEGIN
			 --IF ((@SourceStoreId IS NOT NULL) )
	
	SELECT * FROM 
	 ( Select Count(*) 'TotalPurchaseRequest' from INV_TXN_PurchaseRequest 
	where StoreId = @SourceStoreId ) pr,
	( Select Count(*) 'TodayPurchaseRequest' from INV_TXN_PurchaseRequest where CAST(CreatedOn AS DATE) = CAST(GETDATE() AS DATE)  AND  StoreId = @SourceStoreId ) today_pr,
	( Select Count(*) 'YestardayPurchaseRequest' from INV_TXN_PurchaseRequest where CAST(CreatedOn AS DATE) = dateadd(day,-1, cast(getdate() as date) ) AND  StoreId = @SourceStoreId) yestarday_pr,

    ( Select Count(*) 'TotalPurchaseOrder' from INV_TXN_PurchaseOrder
	where StoreId = @SourceStoreId) po,
	( Select Count(*) 'TodayPurchaseOrder' from INV_TXN_PurchaseOrder where CAST(CreatedOn AS DATE) = CAST(GETDATE() AS DATE) AND  StoreId = @SourceStoreId ) today_po,
	( Select Count(*) 'YestardayPurchaseOrder' from INV_TXN_PurchaseOrder where CAST(CreatedOn AS DATE) = dateadd(day,-1, cast(getdate() as date) ) AND  StoreId = @SourceStoreId) yestarday_po,

	 ( Select Count(*) 'TotalGoodsReceipt' from INV_TXN_GoodsReceipt where StoreId = @SourceStoreId ) gr,
	( Select Count(*) 'TodayGoodsReceipt' from INV_TXN_GoodsReceipt where CAST(ReceivedOn AS DATE) = CAST(GETDATE() AS DATE) AND  StoreId = @SourceStoreId ) today_gr,
	( Select Count(*) 'YestardayGoodsReceipt' from INV_TXN_GoodsReceipt where CAST(ReceivedOn AS DATE) = dateadd(day,-1, cast(getdate() as date) ) AND  StoreId = @SourceStoreId) yestarday_gr,

	( Select Count(*) 'TotalGoodsArrivalNotification' from INV_TXN_GoodsReceipt where StoreId = @SourceStoreId ) gan,
	( Select Count(*) 'TodayGoodsArrivalNotification' from INV_TXN_GoodsReceipt where CAST(CreatedOn AS DATE) = CAST(GETDATE() AS DATE) AND  StoreId = @SourceStoreId ) today_gan,
	( Select Count(*) 'YestardayGoodsArrivalNotification' from INV_TXN_GoodsReceipt where CAST(CreatedOn AS DATE) = dateadd(day,-1, cast(getdate() as date) ) AND  StoreId = @SourceStoreId) yestarday_gan,
	( Select Count(*) 'TotalConsumablesRequisition'
	from INV_TXN_Requisition  Req
	join INV_TXN_RequisitionItems Reqi on Req.RequisitionId = Reqi.RequisitionId
	Join INV_MST_Item  Item on  Reqi.ItemId = Item.ItemId
	where Item.ItemType = 'Consumables' AND Req.RequestToStoreId= @SourceStoreId
	) req,

	( Select Count(*) 'TodayConsumablesRequisition' from INV_TXN_Requisition  Req
	join INV_TXN_RequisitionItems Reqi on Req.RequisitionId = Reqi.RequisitionId
	Join INV_MST_Item  Item on  Reqi.ItemId = Item.ItemId
	where CAST(Req.CreatedOn AS DATE) = CAST(GETDATE() AS DATE) AND Item.ItemType = 'Consumables' AND Req.RequestToStoreId= @SourceStoreId ) today_req,
	( Select Count(*) 'YestardayConsumablesRequisition' from INV_TXN_Requisition  Req
	join INV_TXN_RequisitionItems Reqi on Req.RequisitionId = Reqi.RequisitionId
	Join INV_MST_Item  Item on  Reqi.ItemId = Item.ItemId 
	where CAST(Req.CreatedOn AS DATE) = dateadd(day,-1, cast(getdate() as date) ) AND  Item.ItemType = 'Consumables' AND Req.RequestToStoreId= @SourceStoreId ) yestarday_req,

	( Select Count(*) 'TotalCapitalGoodsRequisition'
	from INV_TXN_Requisition  Req
	join INV_TXN_RequisitionItems Reqi on Req.RequisitionId = Reqi.RequisitionId
	Join INV_MST_Item  Item on  Reqi.ItemId = Item.ItemId
	where Item.ItemType = 'Capital Goods' AND Req.RequestToStoreId= @SourceStoreId
	) reqcapital,

	( Select Count(*) 'TodayCapitalGoodsRequisition' from INV_TXN_Requisition  Req
	join INV_TXN_RequisitionItems Reqi on Req.RequisitionId = Reqi.RequisitionId
	Join INV_MST_Item  Item on  Reqi.ItemId = Item.ItemId
	where CAST(Req.CreatedOn AS DATE) = CAST(GETDATE() AS DATE) AND Item.ItemType = 'Capital Goods' AND Req.RequestToStoreId= @SourceStoreId ) today_reqcapital,
	( Select Count(*) 'YestardayCapitalGoodsRequisition' from INV_TXN_Requisition  Req
	join INV_TXN_RequisitionItems Reqi on Req.RequisitionId = Reqi.RequisitionId
	Join INV_MST_Item  Item on  Reqi.ItemId = Item.ItemId 
	where CAST(Req.CreatedOn AS DATE) = dateadd(day,-1, cast(getdate() as date) ) AND  Item.ItemType = 'Capital Goods' AND Req.RequestToStoreId= @SourceStoreId ) yestarday_reqcapital,

	
	( Select Count(*) 'TotalConsumablesDispatchItems' from INV_TXN_DispatchItems Dis
		join INV_MST_Item Item on Dis.ItemId = Item.ItemId
		where Item.ItemType = 'Consumables' AND Dis.SourceStoreId= @SourceStoreId
	) dis,

	( Select Count(*) 'TodayConsumablesDispatchItems' from INV_TXN_DispatchItems  Dis
			join INV_MST_Item Item on Dis.ItemId = Item.ItemId
	where CAST(Dis.CreatedOn AS DATE) = CAST(GETDATE() AS DATE) AND  Item.ItemType = 'Consumables' AND Dis.SourceStoreId= @SourceStoreId ) today_dis,
	( Select Count(*) 'YestardayConsumablesDispatchItems' from INV_TXN_DispatchItems Dis
		join INV_MST_Item  Item on Dis.ItemId = Item.ItemId
	where CAST(Dis.CreatedOn AS DATE) = dateadd(day,-1, cast(getdate() as date) ) AND  Item.ItemType = 'Consumables' AND Dis.SourceStoreId= @SourceStoreId) yestarday_dis,

	
	( Select Count(*) 'TotalCapitalGoodsDispatchItems' from INV_TXN_DispatchItems Dis
		join INV_MST_Item Item on Dis.ItemId = Item.ItemId
		where Item.ItemType = 'Capital Goods' AND Dis.SourceStoreId= @SourceStoreId
	) discapital,

	( Select Count(*) 'TodayCapitalGoodsDispatchItems' from INV_TXN_DispatchItems  Dis
			join INV_MST_Item Item on Dis.ItemId = Item.ItemId
	where CAST(Dis.CreatedOn AS DATE) = CAST(GETDATE() AS DATE) AND  Item.ItemType = 'Capital Goods' AND Dis.SourceStoreId= @SourceStoreId ) today_discapital,
	( Select Count(*) 'YestardayCapitalGoodsDispatchItems' from INV_TXN_DispatchItems Dis
		join INV_MST_Item  Item on Dis.ItemId = Item.ItemId
	where CAST(Dis.CreatedOn AS DATE) = dateadd(day,-1, cast(getdate() as date) ) AND  Item.ItemType = 'Capital Goods' AND Dis.SourceStoreId= @SourceStoreId) yestarday_discapital

END