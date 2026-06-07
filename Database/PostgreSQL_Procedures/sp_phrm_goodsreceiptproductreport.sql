CREATE OR REPLACE FUNCTION sp_phrm_goodsreceiptproductreport(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_itemid INT DEFAULT NULL
)
RETURNS TABLE (
    "Date" TIMESTAMP,
    "GoodReceiptPrintId" INT,
    "InvoiceNo" VARCHAR,
    "ItemId" INT,
    "ItemName" VARCHAR,
    "BatchNo" VARCHAR,
    "ReceivedQuantity" INT,
    "FreeQuantity" INT,
    "ItemPrice" DECIMAL,
    "SalePrice" DECIMAL,
    "SupplierName" VARCHAR,
    "ContactNo" TIMESTAMP,
    "SubTotal" DECIMAL,
    "TotalAmount" DECIMAL,
    "VATAmount" DECIMAL
) AS $$
BEGIN
    /*
    filename: "sp_phrm_goodsreceiptproductreport" '2021-07-09','2021-08-09'
    createdby/date:vikas/2018-08-10
    description: .
    remarks: 4sept'21/sud: This report may be hidden for temporary purpose, will correct it later after proper requirement
    Change History
    S.No.    UpdatedBy/Date                        Remarks
    1      Vikas/2018-08-10                created the script
    2      Nagesh/2018-08-11                updated
    3	   Abhishek/ 2018-09-7				updated
    4	   Naveed/2019-12-13				updated script for exclude zero quantity Items
    5      Ramesh/2021-08-01                show BillNo as well in Grid
    6      Rohit/Ramesh/2021-08-08          show SubTotal and Total Amt in Grid 
    7      Sud/Pawan:4Sept'21               * added vatamount column in return table.
                                            * taking goodreceiptdate from gr table instead of createdon of gri table. 
    										   since we're doing Stock Entry on GoodReceiptDate (Check TransactionDate table of StockTxnTable)
    8      Rohit/13Feb'23						mrp-> saleprice
    
    */
    
    	begin
    		RETURN QUERY SELECT (gr.goodreceiptdate)::date AS "Date"
    			,gr.goodreceiptprintid
    			,gr.invoiceno
    			,gri.itemid
    			,gri.itemname
    			,gri.batchno
    			,gri.receivedquantity
    			,gri.freequantity
    			,gri.gritemprice AS "ItemPrice"
    			,gri.saleprice
    			,spl.suppliername
    			,spl.contactno
    			,gri.subtotal
    			,gri.totalamount
    			,gri.grperitemvatamt AS "VATAmount"
    		from phrm_goodsreceiptitems gri
    		join phrm_goodsreceipt gr on gri.goodreceiptid = gr.goodreceiptid
    		join phrm_mst_supplier spl on gr.supplierid = spl.supplierid
    		where (gr.goodreceiptdate)::date between p_fromdate
    				and p_todate
    			and (
    				gri.itemid = p_itemid
    				or coalesce(p_itemid, 0) = 0
    				)
    		order by (gr.goodreceiptdate)::date desc;
    	end;
END;
$$ LANGUAGE plpgsql;