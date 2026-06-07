CREATE OR REPLACE FUNCTION sp_dbs_home_invdashboardstats(
    p_sourcestoreid INT DEFAULT NULL
)
RETURNS TABLE (
    "TotalPurchaseRequest" BIGINT,
    "todaypurchaserequest" BIGINT,
    "yestardaypurchaserequest" BIGINT,
    "totalpurchaseorder" BIGINT,
    "todaypurchaseorder" BIGINT,
    "yestardaypurchaseorder" BIGINT,
    "totalgoodsreceipt" BIGINT,
    "todaygoodsreceipt" BIGINT,
    "yestardaygoodsreceipt" BIGINT,
    "totalgoodsarrivalnotification" BIGINT,
    "todaygoodsarrivalnotification" BIGINT,
    "yestardaygoodsarrivalnotification" BIGINT,
    "totalconsumablesrequisition" BIGINT,
    "todayconsumablesrequisition" BIGINT,
    "yestardayconsumablesrequisition" BIGINT,
    "totalcapitalgoodsrequisition" BIGINT,
    "todaycapitalgoodsrequisition" BIGINT,
    "yestardaycapitalgoodsrequisition" BIGINT,
    "totalconsumablesdispatchitems" BIGINT,
    "todayconsumablesdispatchitems" BIGINT,
    "yestardayconsumablesdispatchitems" BIGINT,
    "totalcapitalgoodsdispatchitems" BIGINT,
    "todaycapitalgoodsdispatchitems" BIGINT,
    "yestardaycapitalgoodsdispatchitems" BIGINT
) AS $$
BEGIN
    /*
    filename: "sp_dbs_home_invdashboardstats"
    createdby/date: rajib/2022-sept-13
    description: to get dashboard statistics of the home dashboards. these are used to fill labels.
    remarks:  
    note:  
    change history
    s.no.    updatedby/date                        remarks
    1       rajib/2022-sept-16               created
    
    */
    
    RETURN QUERY SELECT * from 
    ( select count(*) AS "TotalPurchaseRequest" from "INV_TXN_PurchaseRequest" 
      where "StoreId" = p_sourcestoreid ) pr,
    ( select count(*) as "todaypurchaserequest" from "INV_TXN_PurchaseRequest" where "CreatedOn"::date = current_date and "StoreId" = p_sourcestoreid ) today_pr,
    ( select count(*) as "yestardaypurchaserequest" from "INV_TXN_PurchaseRequest" where "CreatedOn"::date = (current_date - INTERVAL '1 day')::date and "StoreId" = p_sourcestoreid) yestarday_pr,

    ( select count(*) as "totalpurchaseorder" from "INV_TXN_PurchaseOrder"
      where "StoreId" = p_sourcestoreid) po,
    ( select count(*) as "todaypurchaseorder" from "INV_TXN_PurchaseOrder" where "CreatedOn"::date = current_date and "StoreId" = p_sourcestoreid ) today_po,
    ( select count(*) as "yestardaypurchaseorder" from "INV_TXN_PurchaseOrder" where "CreatedOn"::date = (current_date - INTERVAL '1 day')::date and "StoreId" = p_sourcestoreid) yestarday_po,

    ( select count(*) as "totalgoodsreceipt" from "INV_TXN_GoodsReceipt" where "StoreId" = p_sourcestoreid ) gr,
    ( select count(*) as "todaygoodsreceipt" from "INV_TXN_GoodsReceipt" where "ReceivedOn"::date = current_date and "StoreId" = p_sourcestoreid ) today_gr,
    ( select count(*) as "yestardaygoodsreceipt" from "INV_TXN_GoodsReceipt" where "ReceivedOn"::date = (current_date - INTERVAL '1 day')::date and "StoreId" = p_sourcestoreid) yestarday_gr,

    ( select count(*) as "totalgoodsarrivalnotification" from "INV_TXN_GoodsReceipt" where "StoreId" = p_sourcestoreid ) gan,
    ( select count(*) as "todaygoodsarrivalnotification" from "INV_TXN_GoodsReceipt" where "CreatedOn"::date = current_date and "StoreId" = p_sourcestoreid ) today_gan,
    ( select count(*) as "yestardaygoodsarrivalnotification" from "INV_TXN_GoodsReceipt" where "CreatedOn"::date = (current_date - INTERVAL '1 day')::date and "StoreId" = p_sourcestoreid) yestarday_gan,
    
    ( select count(*) as "totalconsumablesrequisition"
      from "INV_TXN_Requisition" req
      join "INV_TXN_RequisitionItems" reqi on req."RequisitionId" = reqi."RequisitionId"
      join "INV_MST_Item" item on reqi."ItemId" = item."ItemId"
      where item."ItemType" = 'Consumables' and req."RequestToStoreId" = p_sourcestoreid
    ) req,

    ( select count(*) as "todayconsumablesrequisition" from "INV_TXN_Requisition" req
      join "INV_TXN_RequisitionItems" reqi on req."RequisitionId" = reqi."RequisitionId"
      join "INV_MST_Item" item on reqi."ItemId" = item."ItemId"
      where req."CreatedOn"::date = current_date and item."ItemType" = 'Consumables' and req."RequestToStoreId" = p_sourcestoreid ) today_req,
    ( select count(*) as "yestardayconsumablesrequisition" from "INV_TXN_Requisition" req
      join "INV_TXN_RequisitionItems" reqi on req."RequisitionId" = reqi."RequisitionId"
      join "INV_MST_Item" item on reqi."ItemId" = item."ItemId" 
      where req."CreatedOn"::date = (current_date - INTERVAL '1 day')::date and item."ItemType" = 'Consumables' and req."RequestToStoreId" = p_sourcestoreid ) yestarday_req,

    ( select count(*) as "totalcapitalgoodsrequisition"
      from "INV_TXN_Requisition" req
      join "INV_TXN_RequisitionItems" reqi on req."RequisitionId" = reqi."RequisitionId"
      join "INV_MST_Item" item on reqi."ItemId" = item."ItemId"
      where item."ItemType" = 'Capital Goods' and req."RequestToStoreId" = p_sourcestoreid
    ) reqcapital,

    ( select count(*) as "todaycapitalgoodsrequisition" from "INV_TXN_Requisition" req
      join "INV_TXN_RequisitionItems" reqi on req."RequisitionId" = reqi."RequisitionId"
      join "INV_MST_Item" item on reqi."ItemId" = item."ItemId"
      where req."CreatedOn"::date = current_date and item."ItemType" = 'Capital Goods' and req."RequestToStoreId" = p_sourcestoreid ) today_reqcapital,
    ( select count(*) as "yestardaycapitalgoodsrequisition" from "INV_TXN_Requisition" req
      join "INV_TXN_RequisitionItems" reqi on req."RequisitionId" = reqi."RequisitionId"
      join "INV_MST_Item" item on reqi."ItemId" = item."ItemId" 
      where req."CreatedOn"::date = (current_date - INTERVAL '1 day')::date and item."ItemType" = 'Capital Goods' and req."RequestToStoreId" = p_sourcestoreid ) yestarday_reqcapital,

    ( select count(*) as "totalconsumablesdispatchitems" from "INV_TXN_DispatchItems" dis
      join "INV_MST_Item" item on dis."ItemId" = item."ItemId"
      where item."ItemType" = 'Consumables' and dis."SourceStoreId" = p_sourcestoreid
    ) dis,

    ( select count(*) as "todayconsumablesdispatchitems" from "INV_TXN_DispatchItems" dis
      join "INV_MST_Item" item on dis."ItemId" = item."ItemId"
      where dis."CreatedOn"::date = current_date and item."ItemType" = 'Consumables' and dis."SourceStoreId" = p_sourcestoreid ) today_dis,
    ( select count(*) as "yestardayconsumablesdispatchitems" from "INV_TXN_DispatchItems" dis
      join "INV_MST_Item" item on dis."ItemId" = item."ItemId"
      where dis."CreatedOn"::date = (current_date - INTERVAL '1 day')::date and item."ItemType" = 'Consumables' and dis."SourceStoreId" = p_sourcestoreid) yestarday_dis,

    ( select count(*) as "totalcapitalgoodsdispatchitems" from "INV_TXN_DispatchItems" dis
      join "INV_MST_Item" item on dis."ItemId" = item."ItemId"
      where item."ItemType" = 'Capital Goods' and dis."SourceStoreId" = p_sourcestoreid
    ) discapital,

    ( select count(*) as "todaycapitalgoodsdispatchitems" from "INV_TXN_DispatchItems" dis
      join "INV_MST_Item" item on dis."ItemId" = item."ItemId"
      where dis."CreatedOn"::date = current_date and item."ItemType" = 'Capital Goods' and dis."SourceStoreId" = p_sourcestoreid ) today_discapital,
    ( select count(*) as "yestardaycapitalgoodsdispatchitems" from "INV_TXN_DispatchItems" dis
      join "INV_MST_Item" item on dis."ItemId" = item."ItemId"
      where dis."CreatedOn"::date = (current_date - INTERVAL '1 day')::date and item."ItemType" = 'Capital Goods' and dis."SourceStoreId" = p_sourcestoreid) yestarday_discapital;
END;
$$ LANGUAGE plpgsql;