CREATE OR REPLACE FUNCTION sp_adt_getbedoccupanciesofallwards(

)
RETURNS TABLE (
    "WardName" VARCHAR,
    "WardId" INT,
    "Occupied" VARCHAR,
    "Vacant" VARCHAR,
    "Reserved" VARCHAR,
    "Total" DECIMAL
) AS $$
BEGIN
    /*
    file: adt_getbedoccupanciesofallwards
    created: sud:16sep'21
    Description: To get Occupied, Reserved and Vacant beds per Ward.
    Remarks: This may give incorrect data because of IsActive-Checks in different tables.
           --Needs proper revision on this.. 
    
    SN    User/Date              Remarks
    1.    Sud/16Sep'21          added comments, renamed from last sp: adt_bedfeature
    
     */
    
    RETURN QUERY SELECT x.wardname,x.wardid,x.occupied,x.vacant, x.reserved, (x.occupied + x.vacant+ x.reserved) AS "Total"  from 
    (	
    	select  y.wardid,y.wardname,
    		 count( case when y.isoccupied=1 and y.bdia='true' and y.wia='true' and y.bfia='true' then 1 end) AS "Occupied",
    		 count( case when y.isoccupied=0  and y.bdia='true' and y.wia='true' and y.bfia='true' then 1 end) AS "Vacant",
    		 (0) AS "Reserved"
    			
    	from (
    	select distinct bd.bedid,bd.bedcode, ward.wardid,bd.isoccupied,ward.wardname,bd.isactive as bdia,ward.isactive as wia,bf.isactive as bfia from
    	adt_bed bd		 
    	 inner join	adt_map_bedfeaturesmap map on map.bedid = bd.bedid
    	 inner join adt_mst_ward ward on ward.wardid = map.wardid 	
    	 inner join adt_mst_bedfeature bf on map.bedfeatureid=bf.bedfeatureid
    	 where ward.isactive=1
    	) as y group by wardname,wardid
    	
    	
    	) as x	
     order by x.wardname;
END;
$$ LANGUAGE plpgsql;