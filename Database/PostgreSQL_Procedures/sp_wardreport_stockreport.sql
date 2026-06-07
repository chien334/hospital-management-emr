CREATE OR REPLACE FUNCTION sp_wardreport_stockreport(
    p_itemid INT DEFAULT NULL,
    p_storeid INT DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
BEGIN
    /*
    filename: "sp_wardreport_stockreport"
    createdby/date: rusha/03-24-2019
    description: to get the stock details such as itemname, batchno, availableqty of each item selected by user 
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1.		rusha/03-24-2019					   shows stock details by item wise
    2.		sanjit/02-03-2020					   substore integration
    */
    
    begin
      if (p_itemid !=0)
    		then
    			open ref1 for select gen.genericname,itm.itemname,ward.batchno,sum(availablequantity) as quantity,ward.expirydate, mrp from ward_stock as ward 
    			join phrm_mst_item as itm on ward.itemid= itm.itemid 
    			join phrm_mst_generic as gen on itm.genericid = gen.genericid  
    			where itm.itemid =p_itemid and ward.storeid = p_storeid
    			group by itemname, mrp ,genericname, ward.batchno, ward.expirydate;
        return next ref1;
    			
    		elsif (p_itemid =0)	
    		then 
    		open ref2 for select gen.genericname,itm.itemname,ward.batchno,sum(availablequantity) as quantity,ward.expirydate, mrp from ward_stock as ward 
    			join phrm_mst_item as itm on ward.itemid= itm.itemid 
    			join phrm_mst_generic as gen on itm.genericid = gen.genericid
    			where ward.storeid = p_storeid
    			--where itm.itemid  like '%'+coalesce(p_itemid,'')+'%'
    			group by itemname, mrp,genericname, ward.batchno, ward.expirydate;
        return next ref2;
    		end if;
    end;
END;
$$ LANGUAGE plpgsql;