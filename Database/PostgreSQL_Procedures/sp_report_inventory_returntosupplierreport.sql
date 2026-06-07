/*
Change History
S.No.	UpdatedBy/Date			          Remarks
1.		Dhanashri/ 8-10-2021		 Created Script for Return to Supplier Report
*/
CREATE OR REPLACE FUNCTION sp_report_inventory_returntosupplierreport(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_vendorid INT DEFAULT NULL,
    p_itemid INT DEFAULT NULL,
    p_batchnumber VARCHAR DEFAULT NULL,
    p_goodreceiptnumber INT DEFAULT NULL,
    p_creditnotenumber INT DEFAULT NULL
)
RETURNS TABLE (
    "VendorName" VARCHAR,
    "ReturnDate" TIMESTAMP,
    "ItemName" VARCHAR,
    "BatchNo" VARCHAR,
    "GoodsReceiptNo" VARCHAR,
    "Quantity" INT,
    "ItemRate" DECIMAL,
    "CreditNoteNo" VARCHAR,
    "DiscountAmount" INT,
    "VAT" VARCHAR,
    "TotalAmount" DECIMAL,
    "Remark" VARCHAR
) AS $$
BEGIN
    
    		RETURN QUERY SELECT ven.vendorname,rtv.returndate,itm.itemname,rtn.batchno,gr.goodsreceiptno,rtn.quantity,rtn.itemrate,
    		rtn.creditnoteno,rtv.discountamount,rtn.vat,rtn.totalamount,rtn.remark
    		from inv_txn_returntovendoritems as rtn
    		join inv_mst_vendor as ven on ven.vendorid = rtn.vendorid
    		join inv_mst_item as itm on itm.itemid = rtn.itemid
    		join inv_txn_goodsreceipt as gr on gr.goodsreceiptid = rtn.goodsreceiptid
    		left join inv_txn_returntovendor rtv on rtn.returntovendorid = rtv.returntovendorid
    		where (((rtn.createdon)::date between coalesce(p_fromdate,current_timestamp) and coalesce(p_todate,current_timestamp)))
    		and ((rtn.vendorid = p_vendorid or p_vendorid is null)
    		and (rtn.itemid = p_itemid or p_itemid is null)
    		and (rtn.batchno = p_batchnumber or p_batchnumber is null)
    		and (gr.goodsreceiptno = p_goodreceiptnumber or p_goodreceiptnumber is null)
    		and (rtn.creditnoteno  = p_creditnotenumber or p_creditnotenumber is null));
END;
$$ LANGUAGE plpgsql;