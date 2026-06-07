CREATE OR REPLACE FUNCTION sp_phrmreport_stockmovementreport(
    p_itemname VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "SN" VARCHAR,
    "ItemName" VARCHAR,
    "ItemCode" VARCHAR,
    "PurchaseQty" INT,
    "PurchaseRate" DECIMAL,
    "PurchaseValue" DECIMAL,
    "SalesQty" INT,
    "SalesRate" DECIMAL,
    "SalesValue" DECIMAL
) AS $$
BEGIN
    /*
    filename: "sp_phrmreport_stockmovementreport"
    createdby/date: umed/2018-02-21
    description: to get the details such AS "PurchaseQty",purchaserate, purchasevalue, salesqty,salesrate, salesvale of each items with its item code
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1       umed/2018-02-21	                 created the script
                                             (to get the details such AS "PurchaseQty",purchaserate, purchasevalue, salesqty,salesrate, salesvale of each items with its item code)
    
    */
    
    begin
    
     if (p_itemname is not null)
    	 then
    		
    			RETURN QUERY SELECT (cast(row_number() over (order by  x.itemcode)  as int)) AS "SN",
    				   x.itemname,x.itemcode,purchaseqty,purchaserate,purchasevalue,salesqty,salesrate ,salesvalue 
    			from 
    				(
    				  select t1.itemname, itm.itemcode, sum(receivedquantity) AS "PurchaseQty", t1.gritemprice AS "PurchaseRate" ,sum((gritemprice* receivedquantity)) AS "PurchaseValue"
    				  from phrm_goodsreceiptitems t1
    				  inner join phrm_mst_item itm on itm.itemid= t1.itemid
    				  group by t1.itemname,itm.itemcode,t1.gritemprice
    				) as x
    			full outer join 
    				(
    				  select t2.itemname,itm.itemcode,  sum(quantity) AS "SalesQty" , price AS "SalesRate" ,sum((price* quantity)) AS "SalesValue"
    				  from phrm_txn_invoiceitems t2
    				  inner join phrm_mst_item itm on itm.itemid= t2.itemid
    				  group by t2.itemname,itm.itemcode,price 
    				) as y
    			  on x.itemname = y.itemname
    			 where x.itemname  like '%'||coalesce(p_itemname,'')||'%'; 
    	 end if;
    end;
END;
$$ LANGUAGE plpgsql;