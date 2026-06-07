CREATE OR REPLACE FUNCTION sp_wardreport_breakagereport(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_storeid INT DEFAULT NULL
)
RETURNS TABLE (
    "Date" TIMESTAMP,
    "ItemName" VARCHAR,
    "Quantity" INT,
    "MRP" VARCHAR,
    "TotalAmt" DECIMAL,
    "Remarks" VARCHAR
) AS $$
BEGIN
    /*
    filename: "sp_wardreport_breakagereport"
    createdby/date: rusha/03-26-2019
    description: to get the details of breakage items from different ward 
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1.		rusha/03-29-2019					   get details of breakage items
    2.		sanjit/02-03-2020						substore integration
    */
    
    begin
      if ((p_fromdate is not null) and (p_todate is not null) and (p_storeid is not null))
    		then
    			RETURN QUERY SELECT (transc.createdon)::date AS "Date", itemname, transc.quantity,stk.mrp,
    			round(stk.mrp*transc.quantity,2,0) AS "TotalAmt",transc.remarks 
    			from ward_transaction as transc
    			join phrm_mst_item as itm on transc.itemid=itm.itemid
    			join ward_stock as stk on transc.stockid=stk.stockid and transc.itemid = stk.itemid 
    			where transc.storeid = p_storeid and transactiontype = 'BreakageItem' and (transc.createdon)::date 
    			between coalesce(p_fromdate,current_timestamp)  and coalesce(p_todate,current_timestamp)+1
    			group by (transc.createdon)::date, itm.itemname, transc.quantity,transc.remarks,stk.mrp,transc.quantity;
    		end if;	
    end;
END;
$$ LANGUAGE plpgsql;