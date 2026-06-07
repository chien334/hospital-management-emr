CREATE OR REPLACE FUNCTION sp_report_phrm_daily_stockvalue(

)
RETURNS TABLE (
    "Date" TIMESTAMP,
    "Quantity" INT
) AS $$
DECLARE
    v_today DATE := (CURRENT_TIMESTAMP)::date; 
    v_startdate TIMESTAMP := (CURRENT_TIMESTAMP-6)::date;
BEGIN
    /*
    */
    
      
    
      RETURN QUERY SELECT d.dates AS "Date",coalesce(inv.quantity,0) AS "Quantity"
      from "fn_common_getalldatesbetweenrange" (v_startdate,v_today) d
      left join   
    	   (   select (createdon)::date as "billdate", sum(coalesce(quantity,0)) AS "Quantity"
    			from phrm_stocktxnitems
    			where inout='out'
    			group by (createdon)::date
    			
    	  ) inv
    on d.dates = inv.billdate
      order by d.dates desc;
    --end of sp
END;
$$ LANGUAGE plpgsql;