CREATE OR REPLACE FUNCTION sp_phrmreport_endingstocksummaryreport(
    p_itemname VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "SN" VARCHAR,
    "ItemName" VARCHAR,
    "ItemCode" VARCHAR,
    "Quantity" INT,
    "BatchNo" VARCHAR,
    "PurchaseRate" DECIMAL,
    "PurchaseValue" DECIMAL
) AS $$
BEGIN
    /*
    filename: "sp_phrmreport_endingstocksummaryreport"
    createdby/date: umed/2018-02-22
    description: to get the details such AS "ItemName", itemcode, availableqty, purchaserate, purchasevalue, of each item selected by user on that itemprice
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1       umed/2018-02-22	                 created the script
                                        (to get the details such AS "ItemName", itemcode, availableqty, purchaserate, purchasevalue, of each item selected by user on that itemprice)
    2       umed/2018-02-23             modified sp i.e added batch no 
    */
    
    begin
    
     if (p_itemname is not null)
    	 then
    		
    			RETURN QUERY SELECT (cast(row_number() over (order by  t1.itemname)  as int)) AS "SN", 
    			      t1.itemname, itm.itemcode, t1.availablequantity AS "Quantity", t1.batchno, t1.gritemprice AS "PurchaseRate" ,
    				   (t1.availablequantity*t1.gritemprice) AS "PurchaseValue"
    				  from phrm_goodsreceiptitems t1
    				  inner join phrm_mst_item itm on itm.itemid= t1.itemid
    				  inner join phrm_stock stk on stk.itemid = itm.itemid
    				   where t1.itemname  like '%'||coalesce(p_itemname,'')||'%'  
    				  group by t1.itemname,itm.itemcode,t1.batchno, t1.gritemprice,t1.availablequantity;
    			     
    			       
    	 end if;
    end;
END;
$$ LANGUAGE plpgsql;