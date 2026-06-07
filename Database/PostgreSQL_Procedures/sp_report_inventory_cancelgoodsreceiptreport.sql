CREATE OR REPLACE FUNCTION sp_report_inventory_cancelgoodsreceiptreport(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL
)
RETURNS TABLE (
    "GoodsReceiptID" INT,
    "GoodsReceiptNo" VARCHAR,
    "GoodsReceiptDate" TIMESTAMP,
    "VendorName" VARCHAR,
    "BillNo" VARCHAR,
    "TotalAmount" DECIMAL,
    "CancelledOn" TIMESTAMP,
    "CancelledBy" VARCHAR,
    "CancelRemarks" VARCHAR
) AS $$
BEGIN
    /*
    filename: "sp_report_inventory_cancelgoodsreceiptreport" '2022-08-29','2022-08-29'
    createdby/date: shankar/2019-09-26
    description: report for cancelled gr in inventory
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1.		nageshbb/13 sep 2020			column list updated for gr cancelled 
    2.		rusha/07th sep 2022				reflect employee name in cancelledby and formatted date 
    */
    begin
    --gr no, vendorbilldate, vendorname, billno, totalamount, cancelleddate, cancelledby, cancelremarks
    		if(p_fromdate is not null or p_todate is not null or len(p_fromdate)>=0 or len(p_todate)>=0)
    				then
    					RETURN QUERY SELECT  
    					gr.goodsreceiptid,
    					gr.goodsreceiptno,
    					(gr.goodsreceiptdate)::date AS "GoodsReceiptDate",
    					v.vendorname, 
    					gr.billno,
    					gr.totalamount,
    					gr.cancelledon,
    					empcancel.fullname AS "CancelledBy",
    					gr.cancelremarks
    					from    inv_txn_goodsreceipt gr				
    					inner join inv_mst_vendor v on v.vendorid = gr.vendorid
    					inner join emp_employee empcancel on empcancel.employeeid = gr.cancelledby
    				    where
    					(gr.cancelledon)::date between coalesce(p_fromdate,current_timestamp) and coalesce(p_todate,current_timestamp)
    			     	and gr.iscancel = 1;										
    				end if;
    	
    end;
END;
$$ LANGUAGE plpgsql;