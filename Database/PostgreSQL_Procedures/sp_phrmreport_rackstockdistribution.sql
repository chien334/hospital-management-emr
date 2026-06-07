CREATE OR REPLACE FUNCTION sp_phrmreport_rackstockdistribution(
    p_rackids VARCHAR DEFAULT NULL,
    p_locationid INT DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
    ref3 refcursor := 'cursor3';
    ref4 refcursor := 'cursor4';
BEGIN
    DROP TABLE IF EXISTS v_rackidtable;
    CREATE TEMP TABLE v_rackidtable (
        RackId int
    );
    /*
    filename: "sp_phrmreport_rackstockdistribution" "1;2",2
    createdby/date: sanjit/2020-06-01
    description: 
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1        sanjit/2020-06-01          created the script
    2        sanjit/2020-06-03          updated the script for store
    */
     begin
        if((p_rackids is not null) and (p_locationid is not null))
        then
          
          insert into v_rackidtable
          select value from string_split(p_rackids, ';');
          if(p_locationid = 1)
            then
              open ref1 for select mr.name as "rackname",i.itemid,i.itemname,ds.availablequantity,ds.batchno, ds.expirydate, ds.price,((ds.availablequantity)::decimal(18,1)*((ds.price)::decimal(18,1))) as "stockvalue", 'Dispensary' as "location"
              from phrm_dispensarystock as ds 
              inner join phrm_mst_item as i on ds.itemid = i.itemid
              inner join v_rackidtable as r on r.rackid = i.rack
              inner join phrm_mst_rack as mr on mr.rackid = r.rackid
              where ds.availablequantity>0;
        return next ref1;
    
    
              open ref2 for select sum(ds.availablequantity) as "totalavailablequantity", sum((ds.availablequantity)::decimal(18,1)*((ds.price)::decimal(18,1))) as "totalstockvaluation"
              from phrm_dispensarystock as ds 
              inner join phrm_mst_item as i on ds.itemid = i.itemid
              inner join v_rackidtable as r on r.rackid = i.rack
              where ds.availablequantity>0;
        return next ref2;
            
          else
            
              open ref3 for select  x1.rackname,x1.itemid,x1.itemname,sum(inqty- outqty+finqty-foutqty) as "availablequantity",x1.batchno as batchno, x1.expirydate,round(x1.price,2,0) as price, (sum(inqty - outqty + finqty - foutqty) * round(x1.price,2,0)) as "stockvalue", 'Store' as "location"
              from(select mr.name as "rackname",s.itemid,s.itemname, s.batchno, s.expirydate, s.price,
                sum(case when s.inout = 'in' then s.quantity else 0 end) as "inqty",
                sum(case when s.inout = 'out' then s.quantity else 0 end) as "outqty",
                sum(case when s.inout = 'in' then s.freequantity else 0 end) as "finqty",
                sum(case when s.inout = 'out' then s.freequantity else 0 end) as "foutqty"
              from "phrm_storestock" as s
              inner join phrm_mst_item as i on i.itemid = s.itemid
              inner join v_rackidtable as r on r.rackid = i.storerackid
              inner join phrm_mst_rack as mr on mr.rackid = r.rackid
              group by s.itemname,s.itemid, s.batchno , s.expirydate,s.price,mr.name)as x1
              group by x1.itemid,x1.itemname, x1.batchno, x1.expirydate, x1.price,x1.rackname
              having sum(finqty + inqty - foutqty - outqty) > 0  -- filtering out quantity > 0
              order by x1.itemname;
        return next ref3;
    		  open ref4 for select sum(x2.availablequantity) as "totalavailablequantity",sum(x2.stockvalue)  as "totalstockvaluation"
              from 
                (select  x1.rackname,x1.itemid,x1.itemname,sum(inqty- outqty+finqty-foutqty) as "availablequantity",x1.batchno as batchno, x1.expirydate,round(x1.price,2,0) as price, (sum(inqty - outqty + finqty - foutqty) * round(x1.price,2,0)) as "stockvalue", 'Store' as "location"
              from(select mr.name as "rackname",s.itemid,s.itemname, s.batchno, s.expirydate, s.price,
                sum(case when s.inout = 'in' then s.quantity else 0 end) as "inqty",
                sum(case when s.inout = 'out' then s.quantity else 0 end) as "outqty",
                sum(case when s.inout = 'in' then s.freequantity else 0 end) as "finqty",
                sum(case when s.inout = 'out' then s.freequantity else 0 end) as "foutqty"
              from "phrm_storestock" as s
              inner join phrm_mst_item as i on i.itemid = s.itemid
              inner join v_rackidtable as r on r.rackid = i.storerackid
              inner join phrm_mst_rack as mr on mr.rackid = r.rackid
              group by s.itemname,s.itemid, s.batchno , s.expirydate,s.price,mr.name)as x1
              group by x1.itemid,x1.itemname, x1.batchno, x1.expirydate, x1.price,x1.rackname
              having sum(finqty + inqty - foutqty - outqty) > 0  -- filtering out quantity > 0
    		  )as x2;
        return next ref4;
            end if;
        end if;
      end;
    return;
END;
$$ LANGUAGE plpgsql;