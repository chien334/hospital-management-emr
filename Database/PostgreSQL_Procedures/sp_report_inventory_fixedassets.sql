CREATE OR REPLACE FUNCTION sp_report_inventory_fixedassets(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL
)
RETURNS TABLE (
    "Date" TIMESTAMP,
    "Name" VARCHAR,
    "ItemName" VARCHAR,
    "Qty" INT,
    "MRP" VARCHAR,
    "TotalAmt" DECIMAL,
    "UOMName" VARCHAR,
    "Code" VARCHAR
) AS $$
DECLARE
    v_inv_name VARCHAR;
BEGIN
    /*
    filename: "sp_report_inventory_fixedassets"
    createdby/date: rusha/07-05-2019
    description: to get the details of fixed assets goods of inventory
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    
    */
    
    begin
      if ((p_fromdate is not null) and (p_todate is not null))
    		then
    			
    			v_inv_name := 'Inventory Store';
    
    			RETURN QUERY SELECT x."date",x."name",x.itemname,x.qty,x.mrp,sum(x.qty * x.mrp) AS "TotalAmt" ,x.uomname,x.code
    			from (
    					select 
    						(gritm.createdon)::date AS "Date",
    						dep.departmentname AS "Name",
    						itm.itemname,
    						dis.dispatchedquantity AS "Qty",
    						gritm.itemrate AS "MRP",
    						unit.uomname,itm.code
    					from inv_txn_stock as stk
    						join inv_txn_goodsreceiptitems as gritm on gritm.goodsreceiptitemid = stk.goodsreceiptitemid
    						join inv_txn_dispatchitems as dis on stk.itemid = dis.itemid
    						join inv_mst_item as itm on itm.itemid = stk.itemid
    						join mst_department as dep on dep.departmentid = dis.departmentid
    						left join inv_mst_unitofmeasurement unit on itm.unitofmeasurementid = unit.uomid
    					where 
    						itm.itemtype = 'Capital Goods' and 
    						(gritm.createdon)::date between coalesce(p_fromdate,current_timestamp)  and 
    						coalesce(p_todate,current_timestamp)+1
    					group by (gritm.createdon)::date,
    						itm.itemname,dep.departmentname,gritm.itemrate,dis.dispatchedquantity,unit.uomname,itm.code
    
    					union all
    
    					select  
    						(gritm.createdon)::date AS "Date",
    						v_inv_name AS "Name",
    						itm.itemname,
    						sum(stk.availablequantity) AS "Qty",
    						gritm.itemrate AS "MRP" ,
    						unit.uomname,itm.code
    					from inv_txn_stock as stk
    						join inv_mst_item as itm on itm.itemid = stk.itemid
    						join inv_txn_goodsreceiptitems as gritm on gritm.goodsreceiptitemid = stk.goodsreceiptitemid					
    						left join inv_mst_unitofmeasurement unit on itm.unitofmeasurementid = unit.uomid
    					where itm.itemtype = 'Capital Goods' and (gritm.createdon)::date between coalesce(p_fromdate,current_timestamp)  and coalesce(p_todate,current_timestamp)+1
    					group by (gritm.createdon)::date,itm.itemname,gritm.itemrate,unit.uomname,itm.code) x
    			group by x."date",x."name",x.itemname,x.qty,x.mrp,x.uomname,x.code;
    
    		end if;	
    end;
END;
$$ LANGUAGE plpgsql;