CREATE OR REPLACE FUNCTION sp_bedinformation(

)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
BEGIN
    
    open ref1 for select * from 
    	(select count(distinct b.bedid) as "total" from adt_bed b 
    	 inner join	adt_map_bedfeaturesmap map on map.bedid = b.bedid and b.isactive='true'
    	 inner join adt_mst_ward ward on ward.wardid = map.wardid and ward.isactive='true'
    	 inner join adt_mst_bedfeature bf on map.bedfeatureid=bf.bedfeatureid and bf.isactive='true') as total,
    	(select count( distinct b.bedid) as "available" from adt_bed b
    	 inner join	adt_map_bedfeaturesmap map on map.bedid = b.bedid and b.isactive='true'
    	 inner join adt_mst_ward ward on ward.wardid = map.wardid and ward.isactive='true'
    	 inner join adt_mst_bedfeature bf on map.bedfeatureid=bf.bedfeatureid and bf.isactive='true' and b.isoccupied = 'false') as available,
    	(select count( distinct b.bedid) as "occupied" from adt_bed b 
    	 inner join	adt_map_bedfeaturesmap map on map.bedid = b.bedid and b.isactive='true'
    	 inner join adt_mst_ward ward on ward.wardid = map.wardid and ward.isactive='true'
    	 inner join adt_mst_bedfeature bf on map.bedfeatureid=bf.bedfeatureid and bf.isactive='true' and b.isoccupied = 'true') as occupied;
        return next ref1;
    
    open ref2 for select b.bednumber,f.bedfeaturename,f.bedprice,b.isoccupied,w.wardname from adt_bed b 
    inner join
    adt_mst_ward w on b.wardid = w.wardid and w.isactive='true'
    inner join
    adt_map_bedfeaturesmap map on map.bedid = b.bedid
    inner join
    adt_mst_bedfeature f on f.bedfeatureid = map.bedfeatureid;
        return next ref2;
END;
$$ LANGUAGE plpgsql;