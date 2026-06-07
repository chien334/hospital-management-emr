CREATE OR REPLACE FUNCTION sp_report_bildsb_dailyrevenuetrend(

)
RETURNS TABLE (
    "Date" TIMESTAMP,
    "Revenue" VARCHAR
) AS $$
DECLARE
    v_today DATE := (CURRENT_TIMESTAMP)::date; 
    v_startdate TIMESTAMP := (CURRENT_TIMESTAMP-6)::date;
BEGIN
    /*
      need to check the data correctness of this storedproc: sudarshan:9jul2017
    */
    
      
    
      RETURN QUERY SELECT d.dates AS "Date", 
      coalesce(bil.totalamount,0) - coalesce(billcancel.cancelamount,0) - coalesce(billret.returnamount,0)    AS "Revenue"
      from "fn_common_getalldatesbetweenrange" (v_startdate,v_today) d
    
           left join   
    	   (   select (createdon)::date as "billdate", sum(coalesce(totalamount,0)) as "totalamount"
    			from bil_txn_billingtransactionitems
    			group by (createdon)::date
    			
    	  ) bil
    
    	    on d.dates = bil.billdate
    		left  join
    		( 
    		   select (cancelledon)::date as "canceldate", sum(coalesce(totalamount,0)) as "cancelamount"
    			from bil_txn_billingtransactionitems
    			where  billstatus='cancel' 
    			 and (cancelledon)::date between v_startdate and v_today
    			 group by (cancelledon)::date 
    
    		) billcancel
    
    		on d.dates=billcancel.canceldate
    
    		 left  join
    		( 
    		   select (returndate)::dateas as "returndate",sum(coalesce(totalamount,0)) as "returnamount" 
    		   from bil_txn_billingreturn
    		   where (returndate)::date between v_startdate and v_today
    		   group by (returndate)::date
    
    		) billret
    		on d.dates=billret.returndate
    
    
        order by d.dates desc;
    
    
    --end of sp
END;
$$ LANGUAGE plpgsql;