CREATE OR REPLACE FUNCTION sp_phrmreport_datewisepurchasereport(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_supplierid INT DEFAULT NULL
)
RETURNS TABLE (
    "SN" VARCHAR,
    "GoodReceiptDate" TIMESTAMP,
    "InvoiceNo" VARCHAR,
    "SupplierName" VARCHAR,
    "ItemName" VARCHAR,
    "GenericName" VARCHAR,
    "BatchNo" VARCHAR,
    "ExpiryDate" TIMESTAMP,
    "PurchaseRate" DECIMAL,
    "Quantity" INT,
    "VATAmount" DECIMAL,
    "FreeQuantity" INT,
    "TotalAmount" DECIMAL,
    "SubTotal" DECIMAL
) AS $$
BEGIN
    /*
    filename: sp_phrmreport_datewisepurchasereport '2021-05-13', '2021-05-13'
    createdby/date: ramesh/13-05-2021
    description: to get the details of goods receipt along with supplier, item, genericname and other parameters.
    
    changes:
    sn       user/date                              remarks
    1.      rohit/ramesh:4sep'21                  Dont show the Cancelled GR Details
                                                  Removing Grouping/sums etc since we need item level data.
    2.		Rohit/23Feb'22						  added new parameter as  supplierid to filter accordingy with supplierid.
    */
    
    
    	begin
    
        if ( p_fromdate is not null and p_todate is not null)
    	then
            RETURN QUERY SELECT (cast(row_number() over (order by  gr.goodreceiptdate)  as int)) AS "SN", 
    		gr.goodreceiptdate, 
    		gr.invoiceno,
    		supplier.suppliername,
    		item.itemname,
    		generic.genericname,
    		gri.batchno,
    		gri.expirydate,
    		coalesce(gri.gritemprice,0) AS "PurchaseRate",
            coalesce(gri.receivedquantity, 0) AS "Quantity",
    		round(coalesce(gri.grperitemvatamt,0),2) AS "VATAmount",
            coalesce(gri.freequantity, 0) AS "FreeQuantity",
    		round(((coalesce(gri.gritemprice,0)*  (coalesce(gri.receivedquantity, 0))) + coalesce(gri.grperitemvatamt,0)),2) AS "TotalAmount", 
    		round(((coalesce(gri.gritemprice,0)*  (coalesce(gri.receivedquantity, 0)))),2) AS "SubTotal"
            from phrm_goodsreceiptitems as gri inner join
                phrm_goodsreceipt as gr on gri.goodreceiptid = gr.goodreceiptid inner join
                phrm_mst_supplier as supplier on supplier.supplierid  = gr.supplierid inner join
                phrm_mst_item as item on item.itemid = gri.itemid inner join
                phrm_mst_generic as generic on generic.genericid = item.genericid
            where (gr.goodreceiptdate)::timestamp between coalesce(p_fromdate,current_timestamp) and coalesce(p_todate,current_timestamp)+1 
    		and (gr.supplierid = p_supplierid or p_supplierid is null)
    		and  coalesce(gr.iscancel,0) !=1; --exclude items from cancelled grs
    
        end if;
    end;
END;
$$ LANGUAGE plpgsql;