CREATE OR REPLACE FUNCTION sp_dbs_home_invdashboardstats(
    p_sourcestoreid INT DEFAULT NULL
)
RETURNS TABLE (
    "TotalPurchaseRequest" DECIMAL
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
    
    			 --if ((p_sourcestoreid is not null) )
    	
    	RETURN QUERY SELECT * from 
    	 ( select count(*) AS "TotalPurchaseRequest" from inv_txn_purchaserequest 
    	where storeid = p_sourcestoreid ) pr,
    	( select count(*) as "todaypurchaserequest" from inv_txn_purchaserequest where cast(createdon as date) = cast(current_timestamp as date)  and  storeid = p_sourcestoreid ) today_pr,
    	( select count(*) as "yestardaypurchaserequest" from inv_txn_purchaserequest where cast(createdon as date) = dateadd(day,-1, cast(current_timestamp as date) ) and  storeid = p_sourcestoreid) yestarday_pr,
    
        ( select count(*) as "totalpurchaseorder" from inv_txn_purchaseorder
    	where storeid = p_sourcestoreid) po,
    	( select count(*) as "todaypurchaseorder" from inv_txn_purchaseorder where cast(createdon as date) = cast(current_timestamp as date) and  storeid = p_sourcestoreid ) today_po,
    	( select count(*) as "yestardaypurchaseorder" from inv_txn_purchaseorder where cast(createdon as date) = dateadd(day,-1, cast(current_timestamp as date) ) and  storeid = p_sourcestoreid) yestarday_po,
    
    	 ( select count(*) as "totalgoodsreceipt" from inv_txn_goodsreceipt where storeid = p_sourcestoreid ) gr,
    	( select count(*) as "todaygoodsreceipt" from inv_txn_goodsreceipt where cast(receivedon as date) = cast(current_timestamp as date) and  storeid = p_sourcestoreid ) today_gr,
    	( select count(*) as "yestardaygoodsreceipt" from inv_txn_goodsreceipt where cast(receivedon as date) = dateadd(day,-1, cast(current_timestamp as date) ) and  storeid = p_sourcestoreid) yestarday_gr,
    
    	( select count(*) as "totalgoodsarrivalnotification" from inv_txn_goodsreceipt where storeid = p_sourcestoreid ) gan,
    	( select count(*) as "todaygoodsarrivalnotification" from inv_txn_goodsreceipt where cast(createdon as date) = cast(current_timestamp as date) and  storeid = p_sourcestoreid ) today_gan,
    	( select count(*) as "yestardaygoodsarrivalnotification" from inv_txn_goodsreceipt where cast(createdon as date) = dateadd(day,-1, cast(current_timestamp as date) ) and  storeid = p_sourcestoreid) yestarday_gan,
    	( select count(*) as "totalconsumablesrequisition"
    	from inv_txn_requisition  req
    	join inv_txn_requisitionitems reqi on req.requisitionid = reqi.requisitionid
    	join inv_mst_item  item on  reqi.itemid = item.itemid
    	where item.itemtype = 'Consumables' and req.requesttostoreid= p_sourcestoreid
    	) req,
    
    	( select count(*) as "todayconsumablesrequisition" from inv_txn_requisition  req
    	join inv_txn_requisitionitems reqi on req.requisitionid = reqi.requisitionid
    	join inv_mst_item  item on  reqi.itemid = item.itemid
    	where cast(req.createdon as date) = cast(current_timestamp as date) and item.itemtype = 'Consumables' and req.requesttostoreid= p_sourcestoreid ) today_req,
    	( select count(*) as "yestardayconsumablesrequisition" from inv_txn_requisition  req
    	join inv_txn_requisitionitems reqi on req.requisitionid = reqi.requisitionid
    	join inv_mst_item  item on  reqi.itemid = item.itemid 
    	where cast(req.createdon as date) = dateadd(day,-1, cast(current_timestamp as date) ) and  item.itemtype = 'Consumables' and req.requesttostoreid= p_sourcestoreid ) yestarday_req,
    
    	( select count(*) as "totalcapitalgoodsrequisition"
    	from inv_txn_requisition  req
    	join inv_txn_requisitionitems reqi on req.requisitionid = reqi.requisitionid
    	join inv_mst_item  item on  reqi.itemid = item.itemid
    	where item.itemtype = 'Capital Goods' and req.requesttostoreid= p_sourcestoreid
    	) reqcapital,
    
    	( select count(*) as "todaycapitalgoodsrequisition" from inv_txn_requisition  req
    	join inv_txn_requisitionitems reqi on req.requisitionid = reqi.requisitionid
    	join inv_mst_item  item on  reqi.itemid = item.itemid
    	where cast(req.createdon as date) = cast(current_timestamp as date) and item.itemtype = 'Capital Goods' and req.requesttostoreid= p_sourcestoreid ) today_reqcapital,
    	( select count(*) as "yestardaycapitalgoodsrequisition" from inv_txn_requisition  req
    	join inv_txn_requisitionitems reqi on req.requisitionid = reqi.requisitionid
    	join inv_mst_item  item on  reqi.itemid = item.itemid 
    	where cast(req.createdon as date) = dateadd(day,-1, cast(current_timestamp as date) ) and  item.itemtype = 'Capital Goods' and req.requesttostoreid= p_sourcestoreid ) yestarday_reqcapital,
    
    	
    	( select count(*) as "totalconsumablesdispatchitems" from inv_txn_dispatchitems dis
    		join inv_mst_item item on dis.itemid = item.itemid
    		where item.itemtype = 'Consumables' and dis.sourcestoreid= p_sourcestoreid
    	) dis,
    
    	( select count(*) as "todayconsumablesdispatchitems" from inv_txn_dispatchitems  dis
    			join inv_mst_item item on dis.itemid = item.itemid
    	where cast(dis.createdon as date) = cast(current_timestamp as date) and  item.itemtype = 'Consumables' and dis.sourcestoreid= p_sourcestoreid ) today_dis,
    	( select count(*) as "yestardayconsumablesdispatchitems" from inv_txn_dispatchitems dis
    		join inv_mst_item  item on dis.itemid = item.itemid
    	where cast(dis.createdon as date) = dateadd(day,-1, cast(current_timestamp as date) ) and  item.itemtype = 'Consumables' and dis.sourcestoreid= p_sourcestoreid) yestarday_dis,
    
    	
    	( select count(*) as "totalcapitalgoodsdispatchitems" from inv_txn_dispatchitems dis
    		join inv_mst_item item on dis.itemid = item.itemid
    		where item.itemtype = 'Capital Goods' and dis.sourcestoreid= p_sourcestoreid
    	) discapital,
    
    	( select count(*) as "todaycapitalgoodsdispatchitems" from inv_txn_dispatchitems  dis
    			join inv_mst_item item on dis.itemid = item.itemid
    	where cast(dis.createdon as date) = cast(current_timestamp as date) and  item.itemtype = 'Capital Goods' and dis.sourcestoreid= p_sourcestoreid ) today_discapital,
    	( select count(*) as "yestardaycapitalgoodsdispatchitems" from inv_txn_dispatchitems dis
    		join inv_mst_item  item on dis.itemid = item.itemid
    	where cast(dis.createdon as date) = dateadd(day,-1, cast(current_timestamp as date) ) and  item.itemtype = 'Capital Goods' and dis.sourcestoreid= p_sourcestoreid) yestarday_discapital;
END;
$$ LANGUAGE plpgsql;