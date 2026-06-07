CREATE OR REPLACE FUNCTION sp_phrmreport_itemwisepurchasereport(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_itemid INT DEFAULT NULL,
    p_invoiceno VARCHAR DEFAULT NULL,
    p_goodsreceiptno INT DEFAULT NULL,
    p_supplierid INT DEFAULT NULL
)
RETURNS TABLE (
    "ItemId" INT,
    "GenericName" VARCHAR,
    "ItemName" VARCHAR,
    "BatchNo" VARCHAR,
    "ExpiryDate" TIMESTAMP,
    "SupplierName" VARCHAR,
    "GoodReceiptDate" TIMESTAMP,
    "InvoiceNo" VARCHAR,
    "GoodsReceiptNo" VARCHAR,
    "PurchaseRate" DECIMAL,
    "VATAmount" DECIMAL,
    "ReceivedQuantity" INT,
    "SubTotal" DECIMAL,
    "TotalAmount" DECIMAL
) AS $$
BEGIN
    /*
    filename: "sp_phrmreport_itemwisepurchasereport"  --- "sp_phrmreport_itemwisepurchasereport" '2021-01-01','2021-12-01', 3,null,null
    createdby/date: ramesh/2021-05-11
    description: to get the details of supplier, goodsreceiptdate, gr no, rate, vat amount and totalamount of the selected item by user.
    
    changes:
    sn       user/date                              remarks
    1.      sud/sanjit/ramesh:4sep'21             Using this function for Supplier as well.
                                                  Removing Grouping/sums etc since we need item level data.
    2.   	Sud/Sanjit:15Jun'22					  itemwise purchase report now references iscancel from gr item table instead of gr table.
    
    
    */
      
    
        RETURN QUERY SELECT 
    	gritems.itemid, 
    	gen.genericname, 
    	item.itemname,
    	gritems.batchno, 
    	(gritems.expirydate)::date AS "ExpiryDate",
    	supplier.suppliername, 
    	(gr.goodreceiptdate)::date AS "GoodReceiptDate", 
    	gr.invoiceno, 
    	gr.goodreceiptprintid AS "GoodsReceiptNo", 
    	coalesce(gritems.gritemprice,0) AS "PurchaseRate", 
    	coalesce(gritems.grperitemvatamt,0) AS "VATAmount", 
    	coalesce(gritems.receivedquantity,0) AS "ReceivedQuantity", 
    		coalesce(gritems.subtotal,0) AS "SubTotal", 
    	coalesce(gritems.totalamount,0) AS "TotalAmount"
    
        from phrm_goodsreceiptitems as gritems inner join
            phrm_goodsreceipt as gr on gr.goodreceiptid = gritems.goodreceiptid inner join
            phrm_mst_item as item on item.itemid = gritems.itemid inner join
            phrm_mst_generic as gen on gen.genericid = item.genericid inner join
            phrm_mst_supplier as supplier on gr.supplierid = supplier.supplierid
        where  
    	   coalesce(gritems.iscancel,0) !=1 --exclude items from cancelled grs
    	   and (gritems.itemid = p_itemid or p_itemid is null) 
    	   and (gr.goodreceiptdate)::date between p_fromdate and p_todate 
           and (gr.goodreceiptprintid = p_goodsreceiptno or p_goodsreceiptno is null)
    	   -- this is special case 'null' was coming from frontend.. pls don't remove that check.. 
    	   AND (gr.InvoiceNo = p_invoiceno OR p_invoiceno IS NULL OR LOWER (p_invoiceno) = 'null' ) 
           and (gr.supplierid = p_supplierid or p_supplierid is null);
END;
$$ LANGUAGE plpgsql;