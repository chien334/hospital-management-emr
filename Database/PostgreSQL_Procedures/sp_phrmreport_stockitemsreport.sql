CREATE OR REPLACE FUNCTION sp_phrmreport_stockitemsreport(
    p_itemname VARCHAR
)
RETURNS TABLE (
    "SN" VARCHAR,
    "ItemName" VARCHAR,
    "ItemCode" VARCHAR,
    "Qty" INT,
    "PurchaseValue" DECIMAL,
    "SalesValue" DECIMAL
) AS $$
BEGIN
    /*
    filename: "sp_phrmreport_stockitemsreport"
    createdby/date: umed/2018-02-21
    description: to get the details such as purchaseqty, purchasevalue, salesqty, salesvale of each items with its item code
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1       umed/2018-02-21	                 created the script
                                             (get the details such as purchaseqty, purchasevalue, salesqty, salesvale of each items with its item code)
    
    */
    
    begin
    
     if (p_itemname is not null)
     then
    		
    				
    		RETURN QUERY SELECT (cast(row_number() over (order by  x.itemcode)  as int)) AS "SN",
    			  x.itemname,x.itemcode,x.availablequantity AS "Qty",purchasevalue,salesvalue 
    	   from 
    			(
    			 select t1.itemname, itm.itemcode,itm.itemid,stk.availablequantity ,sum((gritemprice* receivedquantity)) AS "PurchaseValue"
    			 from phrm_goodsreceiptitems t1
    			 inner join phrm_mst_item itm on itm.itemid= t1.itemid
    			 inner join phrm_stock stk on stk.itemid = itm.itemid
    			 group by t1.itemname,itm.itemcode,itm.itemid,stk.availablequantity
    			 ) as x
    		full outer join 
    			(
    			select t2.itemname,itm.itemcode,  stk.availablequantity  ,sum((price* quantity)) AS "SalesValue"
    		   from phrm_txn_invoiceitems t2
    		   inner join phrm_mst_item itm on itm.itemid= t2.itemid
    		   inner join phrm_stock stk on stk.itemid = itm.itemid
    		   group by t2.itemname,itm.itemcode,stk.availablequantity
    		   ) as y
    		on x.itemname = y.itemname
    		where x.itemname  like '%'||coalesce(p_itemname,'')||'%'; 
    
    end if;
    
    end;
END;
$$ LANGUAGE plpgsql;