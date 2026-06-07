CREATE OR REPLACE FUNCTION sp_phrmreport_itemwisestockreport(

)
RETURNS TABLE (
    "ItemName" VARCHAR,
    "ItemTypeName" VARCHAR,
    "StockQuantity" INT,
    "StockValue" DECIMAL
) AS $$
BEGIN
    /*
    filename: "sp_phrmreport_itemwisestockreport"
    createdby/date: umed/2017-11-23
    description: to get the itemwise stock quantity with stock value
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1       umed/2017-11-23	                     created the script
    2       umed/2017-11-28                     modify because we have drop the stockin table 
                                              and now available qty is get from gritms tables
    */
    
    
         RETURN QUERY SELECT  itm.itemname,ittyp.itemtypename ,coalesce(sum(gritm.availablequantity),0) AS "StockQuantity" ,
                coalesce(sum(gritm.availablequantity *gritm.gritemprice),0) AS "StockValue"
    	 from  phrm_goodsreceiptitems gritm 
    	 inner join phrm_mst_item itm on itm.itemid = gritm.itemid
    	 inner join phrm_mst_itemtype ittyp on ittyp.itemtypeid = itm.itemtypeid
    	 group by itm.itemname,ittyp.itemtypename;
END;
$$ LANGUAGE plpgsql;