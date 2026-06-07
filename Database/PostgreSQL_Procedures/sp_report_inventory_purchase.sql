CREATE OR REPLACE FUNCTION sp_report_inventory_purchase(

)
RETURNS TABLE (
    "ItemName" VARCHAR,
    "VendorName" VARCHAR,
    "ContactNo" TIMESTAMP,
    "CreatedOn" TIMESTAMP,
    "TotalQuantity" INT,
    "StandardRate" DECIMAL,
    "TotalAmount" DECIMAL,
    "Discount" INT,
    "UOMName" VARCHAR,
    "Code" VARCHAR
) AS $$
BEGIN
    
    
          begin
                RETURN QUERY SELECT itm.itemname, vendor.vendorname,vendor.contactno,  format (pitms.createdon, 'dd MMM yyyy, hh:mm tt ') AS "CreatedOn",(gitms.receivedquantity + gitms.freequantity) AS "TotalQuantity",pitms.standardrate, po.totalamount,gr.discount
      	,unit.uomname,itm.code
     from inv_txn_goodsreceipt gr   
     join inv_txn_goodsreceiptitems gitms on gitms.goodsreceiptid = gr.goodsreceiptid
     join inv_txn_purchaseorderitems pitms on pitms.purchaseorderid = gr.purchaseorderid 
     join inv_mst_item itm on gitms.itemid = itm.itemid
     join inv_txn_purchaseorder po on po.purchaseorderid = pitms.purchaseorderid
     join inv_mst_vendor vendor on vendor.vendorid = gr.vendorid
    left join inv_mst_unitofmeasurement unit on itm.unitofmeasurementid = unit.uomid
     where gitms.itemid = pitms.itemid and gr.iscancel = 0
     order by gr.purchaseorderid desc;
    
            end;
END;
$$ LANGUAGE plpgsql;