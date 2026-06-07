CREATE OR REPLACE FUNCTION sp_dsb_pharmacy_salespurchasegraph_dashboardstatistics(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_status VARCHAR DEFAULT NULL,
    p_itemidcommaseprated VARCHAR DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
    ref3 refcursor := 'cursor3';
    v_dynamicpivotquery VARCHAR;
    v_pivotcolumnnames VARCHAR;
    v_pivotselectcolumnnames VARCHAR;
BEGIN
    begin
    
    
    
    create temp table temp_temptable(
     itemid int,
     itemname varchar(200));
     
     insert into temp_temptable  (itemid , itemname )
      select itemid, itemname
          from phrm_mst_item
          where itemid in(
    	         select item
                from splitstring(p_itemidcommaseprated, ',')
          );
    
    
    
    --if status is sales then this sql -----
    if (p_status != 'sales')
        then
    	             select coalesce(v_pivotcolumnnames || ',','')
    					|| quotename(itemname) into v_pivotcolumnnames from ( 
    					      select distinct itemname from temp_temptable
    						 )   as dep;
    				 
    					 open ref1 for select 'Date'||coalesce(','||replace(replace(v_pivotcolumnnames,'"',''),'"',''),'') as columnname;
        return next ref1;
    
    					v_dynamicpivotquery := n'SELECT "Date", ' || v_pivotcolumnnames || '
    							FROM (
    									  SELECT convert(date,grItm.CreatedOn) as "Date", itm.ItemName, COALESCE(grItm.ReceivedQuantity,0) as Qty       
    									  FROM PHRM_GoodsReceipt gr           
    									      Inner join PHRM_GoodsReceiptItems grItm on gr.GoodReceiptId = grItm.GoodReceiptId       
    										  Inner Join PHRM_MST_Item itm on grItm.ItemId = itm.ItemId
    										  WHERE convert(date,grItm.CreatedOn) 
    										  BETWEEN  CONVERT(TIMESTAMP,'''|| (coalesce(p_fromdate,current_timestamp))::varchar  || ''') and CONVERT(TIMESTAMP,'''||(coalesce(p_todate,current_timestamp))::varchar||''')+1
    								) A
    							PIVOT(sum(Qty) for ItemName in (' || v_pivotcolumnnames || ')) as pvt';
    
    
    					open ref3 for execute v_dynamicpivotquery;
        return next ref3;
    
        
    
    else 
    	   
                      open ref2 for select v_pivotcolumnnames= coalesce(v_pivotcolumnnames || ',','')
    					|| quotename(itemname)
    					from ( 
    					      select distinct itemname from temp_temptable
    						)   as dep;
        return next ref2;
    				 
    					 open ref3 for select 'Date'||coalesce(','||replace(replace(v_pivotcolumnnames,'"',''),'"',''),'') as columnname;
        return next ref3;
    
    					v_dynamicpivotquery := n'SELECT "Date", ' || v_pivotcolumnnames || '
    							FROM (
    									 SELECT  convert(date,txInvItm.CreatedOn) as "Date", itm.ItemName 
    				                            , txInvItm.Quantity as Qty         
    									  FROM PHRM_TXN_Invoice txInv  
    			                          Inner join PHRM_TXN_InvoiceItems txInvItm on txInv.InvoiceId = txInvItm.InvoiceId
    			                          Inner Join PHRM_MST_Item itm on txInvItm.ItemId = itm.ItemId 
    									   where convert(date,txInvItm.CreatedOn) 
    										  BETWEEN  CONVERT(TIMESTAMP,'''|| (coalesce(p_fromdate,current_timestamp))::varchar  || ''') and CONVERT(TIMESTAMP,'''||(coalesce(p_todate,current_timestamp))::varchar||''')+1
    										        and txInv.BilStatus = ''paid''
    								) A
    							PIVOT(sum(Qty) for ItemName in (' || v_pivotcolumnnames || ')) as pvt';
    
    
    					open ref3 for execute v_dynamicpivotquery;
        return next ref3;
    
    	   end if;
    
    drop table if exists temp_temptable;
    
    end;
END;
$$ LANGUAGE plpgsql;