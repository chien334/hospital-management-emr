CREATE OR REPLACE FUNCTION sp_phrmreport_supplierstockreport(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_supplierid INT DEFAULT NULL
)
RETURNS TABLE (
    "GoodReceiptDate" TIMESTAMP,
    "SupplierName" VARCHAR,
    "ItemName" VARCHAR,
    "BatchNo" VARCHAR,
    "ExpiryDate" TIMESTAMP,
    "PurchaseRate" DECIMAL,
    "ReceivedQuantity" INT,
    "VATAmount" DECIMAL,
    "FreeQuantity" INT,
    "TotalAmount" DECIMAL,
    "SubTotal" DECIMAL
) AS $$
BEGIN
    /*
    filename: sp_phrmreport_supplierstockreport
    createdby/date: rusha/04-07-2019
    description: to get the details of goods receipt from supplier such as received qty, rate per qty, and so on
    example: exec sp_phrmreport_supplierstockreport '2021-01-01', '2021-12-01',78
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1        rusha/04-07-2019	                 to get details of goods receipts from supplier 
    2		 sanjit/27-05-2020					 added fromdate and todate in the sp for date filter (emr-1618)
    3        ramesh/12-05-2021                   suppliername is replaced by supplierid and other details like vat amt, batchno etc were added
    4.		sanjit/1-09-2021					conerted p_fromdate and p_todate into date type instead of timestamp
    5.      rohit/23feb'22						do not show the cancelled gr details
    */
    
    	begin
    
        if ( p_fromdate is not null and p_todate is not null and p_supplierid is not null )
    	then
            RETURN QUERY SELECT  gr.goodreceiptdate, supplier.suppliername, gri.itemname, gri.batchno, gri.expirydate, coalesce(gri.gritemprice,0) AS "PurchaseRate",
    		    sum (coalesce(gri.receivedquantity, 0)) AS "ReceivedQuantity", coalesce(gri.grperitemvatamt,0) AS "VATAmount",
                sum (coalesce(gri.freequantity, 0)) AS "FreeQuantity", ((coalesce(gri.gritemprice,0)* sum (coalesce(gri.receivedquantity, 0))) + coalesce(gri.grperitemvatamt,0)) AS "TotalAmount", ((coalesce(gri.gritemprice,0)* sum (coalesce(gri.receivedquantity, 0)))) AS "SubTotal"
            from phrm_goodsreceiptitems as gri inner join
                phrm_goodsreceipt as gr on gri.goodreceiptid = gr.goodreceiptid inner join
                phrm_mst_supplier as supplier on supplier.supplierid  = gr.supplierid
            where (gr.goodreceiptdate)::date between p_fromdate and p_todate and gr.supplierid = p_supplierid and  coalesce(gr.iscancel,0) !=1 --exclude items from cancelled grs
    
            group by gri.goodreceiptid, gri.itemid, gri.expirydate, gri.batchno, gri.gritemprice, gri.itemname, gri.grperitemvatamt, gr.goodreceiptdate, supplier.suppliername;
        end if;
      end;
END;
$$ LANGUAGE plpgsql;