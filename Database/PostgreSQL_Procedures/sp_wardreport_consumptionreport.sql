CREATE OR REPLACE FUNCTION sp_wardreport_consumptionreport(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_storeid INT DEFAULT NULL
)
RETURNS TABLE (
    "Date" TIMESTAMP,
    "ItemName" VARCHAR,
    "GenericName" VARCHAR,
    "Quantity" INT
) AS $$
BEGIN
    /*
    filename: "sp_wardreport_consumptionreport"
    createdby/date: rusha/03-26-2019
    description: to get the consumption details of items from different ward 
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1.		rusha/03-29-2019					   add stock details of consumed item from different ward
    2.		sanjit/02-03-2020						substore integration
    3.      rajib/02-26-2020						update invoiceitemid
    */
    
    begin
      if ((p_fromdate is not null) and (p_todate is not null) and (p_storeid is not null))
    		then
    			RETURN QUERY SELECT (consum.createdon)::date AS "Date", consum.itemname, gene.genericname, consum.quantity AS "Quantity" 
    			from ward_consumption as consum 
    			join phrm_mst_item as itm on consum.itemid=itm.itemid
    			join phrm_mst_generic as gene on  itm.genericid=gene.genericid
    			where consum.storeid = p_storeid and (consum.createdon)::date between coalesce(p_fromdate,current_timestamp)  and coalesce(p_todate,current_timestamp)+1
    			group by (consum.createdon)::date,consum.itemname,consum.quantity, gene.genericname,consum.invoiceitemid;
    		end if;		
    end;
END;
$$ LANGUAGE plpgsql;