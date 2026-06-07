CREATE OR REPLACE FUNCTION sp_report_inventory_comparepoandgr(

)
RETURNS TABLE (
    "SNo" VARCHAR,
    "ItemName" VARCHAR,
    "VendorName" VARCHAR,
    "CreatedOn" TIMESTAMP,
    "Quantity" INT,
    "RecevivedQuantity" INT,
    "Receivedon" TIMESTAMP,
    "GoodsReceiptID" INT,
    "PurchaseOrderId" INT,
    "UOMName" VARCHAR,
    "Code" VARCHAR
) AS $$
BEGIN
    
    
    	begin
    		RETURN QUERY SELECT row_number() over(order by (select 1)) AS "SNo", itm.itemname, vendor.vendorname, pitms.createdon,pitms.quantity,(gitms.receivedquantity + gitms.freequantity) AS "RecevivedQuantity", gitms.createdon AS "Receivedon", gr.goodsreceiptid, gr.purchaseorderid
      	,unit.uomname,itm.code
     from inv_txn_goodsreceipt gr
     join inv_txn_goodsreceiptitems gitms on gitms.goodsreceiptid = gr.goodsreceiptid
     join inv_txn_purchaseorderitems pitms on pitms.purchaseorderid = gr.purchaseorderid 
     join inv_mst_item itm on gitms.itemid = itm.itemid
     join inv_mst_vendor vendor on vendor.vendorid = gr.vendorid
    				left join inv_mst_unitofmeasurement unit on itm.unitofmeasurementid = unit.uomid
     where gitms.itemid = pitms.itemid and gr.iscancel = 0
     order by gr.purchaseorderid desc;
    
    	end;
END;
$$ LANGUAGE plpgsql;