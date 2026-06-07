CREATE OR REPLACE FUNCTION sp_report_inventory_purchaseitemsreport(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_fiscalyearid INT DEFAULT NULL,
    p_itemid INT DEFAULT NULL
)
RETURNS TABLE (
    "Dates" TIMESTAMP,
    "GoodsReceiptNo" VARCHAR,
    "VendorName" VARCHAR,
    "SubCategoryName" VARCHAR,
    "ItemName" VARCHAR,
    "TotalQty" INT,
    "ItemRate" DECIMAL,
    "SubTotal" DECIMAL,
    "DiscountAmount" INT,
    "VATAmount" DECIMAL,
    "TotalAmount" DECIMAL,
    "MRP" VARCHAR,
    "ItemId" INT,
    "ItemType" VARCHAR,
    "GRItemSpecification" TIMESTAMP,
    "BillNo" VARCHAR
) AS $$
BEGIN
    /*
     filename: "sp_report_inventory_purchaseitemsreport" 
     created: 9th sep 2020/vikas
     description: to get the summary of inventory purchase report
     remarks: 
     change history
     s.no.    date/user              change          remarks
     1.		vikas:10th sep2020		sp for purchase items summary
     2.		nageshbb: 17 sep 2020	updated column list and remove unwanted code, excluing cancel gr
     3.		rohit/9jun'22			SP modified to get purchase details with ItemId(before this list of item are checking)
    */
    BEGIN
    	RETURN QUERY SELECT (gr.GoodsReceiptDate)::DATE AS "Dates"
    		,gr.GoodsReceiptNo
    		,v.VendorName
    		,sb.SubCategoryName
    		,itm.ItemName
    		,(gritm.ReceivedQuantity + gritm.FreeQuantity) AS "TotalQty"
    		,gritm.ItemRate
    		,gritm.SubTotal
    		,gritm.DiscountAmount
    		,gritm.VATAmount
    		,gritm.TotalAmount
    		,gritm.MRP
    		,gritm.ItemId
    		,itm.ItemType
    		,Case
    				WHEN gritm.BatchNO IS NOT NULL THEN Concat(gritm.GRItemSpecification,'/'||gritm.batchno)
    				else gritm.gritemspecification
    		end AS "GRItemSpecification"
    		,gr.billno
    	from inv_txn_goodsreceipt gr
    	join inv_txn_goodsreceiptitems gritm on gr.goodsreceiptid = gritm.goodsreceiptid
    	join inv_mst_item itm on gritm.itemid = itm.itemid
    	join inv_mst_vendor v on v.vendorid = gr.vendorid
    	join inv_mst_itemsubcategory sb on itm.subcategoryid = sb.subcategoryid
    	where (
    			(gr.goodsreceiptdate)::date between (p_fromdate)::date
    				and (p_todate)::date
    			)
    		and gr.iscancel != 1
    		and (
    			itm.itemid = p_itemid
    			or p_itemid is null
    			);
    end;
END;
$$ LANGUAGE plpgsql;