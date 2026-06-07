CREATE OR REPLACE FUNCTION sp_report_inventory_currentstocklevel(
    p_itemname VARCHAR DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
BEGIN
    /*
    filename: "sp_report_inventory_currentstocklevel"
    createdby/date: umed/2017-06-21
    description: to get details such as avaliable qty of stock with other data such as min stock qty , budgeted and item rate of respective items
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1       umed/2017-06-21	                   created the script
    */
    
    begin
    
    		if( (p_itemname is not null) or (len(p_itemname) > 0) )
    				then
    				         
    						open ref1 for select distinct itm.itemname,
    							   sum(stk.availablequantity) as availablequantity,
    								itm.minstockquantity,
    								itm.budgetedquantity, 
    								 gdrp.itemrate
    						 from inv_txn_stock stk
    						inner join inv_mst_item itm on itm.itemid = stk.itemid 
    						inner join inv_txn_goodsreceiptitems gdrp on gdrp.goodsreceiptitemid = stk.goodsreceiptitemid
    						where itm.itemname like '%'||coalesce(p_itemname,'')||'%'
    						group by itm.itemname, itm.minstockquantity,itm.budgetedquantity,itm.standardrate , gdrp.itemrate;
        return next ref1;
    				
            else 
    
    		     
    				         
    						open ref2 for select distinct itm.itemname,
    							   sum(stk.availablequantity) as availablequantity,
    								itm.minstockquantity,
    								itm.budgetedquantity, 
    								 gdrp.itemrate
    						 from inv_txn_stock stk
    						inner join inv_mst_item itm on itm.itemid = stk.itemid 
    						inner join inv_txn_goodsreceiptitems gdrp on gdrp.goodsreceiptitemid = stk.goodsreceiptitemid
    						group by itm.itemname, itm.minstockquantity,itm.budgetedquantity,itm.standardrate , gdrp.itemrate;
        return next ref2;
    				
    				end if;
     
    end;
END;
$$ LANGUAGE plpgsql;