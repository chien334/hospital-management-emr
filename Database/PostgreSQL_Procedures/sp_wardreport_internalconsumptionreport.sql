CREATE OR REPLACE FUNCTION sp_wardreport_internalconsumptionreport(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_storeid INT DEFAULT NULL
)
RETURNS TABLE (
    "ConsumedDate" TIMESTAMP,
    "DepartmentName" VARCHAR,
    "ItemName" VARCHAR,
    "ConsumedBy" TIMESTAMP,
    "Quantity" INT
) AS $$
BEGIN
    /*
    filename: "sp_wardreport_internalconsumptionreport" '2018-01-01', '2020-02-18',2
    createdby/date: rajib/02-10-2020
    description: to get the internal consumption details of items from different ward 
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1.		rajib/2/18/2020							update storeid
    2.		rajib/2/26/2020							update consumptionitemid
    */
    
    begin
      if ((p_fromdate is not null) and (p_todate is not null)and (p_storeid is not null) )
    		then
    			RETURN QUERY SELECT (consum.createdon)::date AS "ConsumedDate", depitm.departmentname,consumitem.itemname, consum.consumedby, consumitem.quantity AS "Quantity" 
    			from ward_internalconsumption as consum 
    			join ward_internalconsumptionitems as consumitem on consum.consumptionid=consumitem.consumptionid
    			join mst_department as depitm on consum.departmentid=depitm.departmentid
    			where consum.substoreid = p_storeid and (consum.createdon)::date between coalesce(p_fromdate,current_timestamp)  and coalesce(p_todate,current_timestamp)+1
    			group by (consum.createdon)::date,depitm.departmentname,consumitem.itemname,consum.consumedby,consumitem.quantity,consumitem.consumptionitemid;
    		end if;		
    end;
END;
$$ LANGUAGE plpgsql;