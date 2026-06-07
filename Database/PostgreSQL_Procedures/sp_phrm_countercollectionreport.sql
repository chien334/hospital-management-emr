CREATE OR REPLACE FUNCTION sp_phrm_countercollectionreport(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL
)
RETURNS TABLE (
    "Date" TIMESTAMP,
    "CounterName" INT,
    "UserName" VARCHAR,
    "TotalAmount" DECIMAL,
    "ReturnedAmount" DECIMAL,
    "NetAmount" DECIMAL,
    "DiscountAmount" INT
) AS $$
BEGIN
    /*
    filename: "sp_phrm_countercollectionreport" '05/01/2018','08/08/2018'
    createdby/date: nagesh/vikas/2018-07-31
    description: .
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1      nagesh/vikas/2018-08-01	              created the script
    2	   rusha/04-08-2019						  remove sum() function to get details of each counter and user		
    */
    -- begin
    --  if ((p_fromdate is not null) and (p_todate is not null)) 
    --		begin
    			
    --			select convert(date,inv.createdon) AS "Date", usr.username AS "UserName",cnt.countername AS "CounterName", 
    --			sum(inv.totalamount)AS "TotalAmount", sum(inv.subtotal*inv.discountpercentage / 100.0) AS "DiscountAmount"
    --			 from phrm_txn_invoiceitems inv
    --				join rbac_user usr
    --				on inv.createdby=usr.employeeid
    --				join phrm_mst_counter cnt on inv.counterid=cnt.counterid
    --				where convert(date,inv.createdon) between coalesce(p_fromdate,current_timestamp) and coalesce(p_todate,current_timestamp)+1
    --			    group by  username,countername,convert(date,inv.createdon)
    --				order by "date"
    					
    --		end
    --end
    
    begin
      if ((p_fromdate is not null) and (p_todate is not null)) 
        then
    	RETURN QUERY SELECT "date", countername,username, totalamount, returnamount AS "ReturnedAmount", totalamount-returnamount AS "NetAmount", 
    	discountamount
    	from ( 
              select (inv.createon)::date AS "Date", phrmcnt.countername,usr.username,inv.paidamount AS "TotalAmount", 0 as returnamount,inv.discountamount AS "DiscountAmount"
                from "phrm_txn_invoice" inv
                  inner join rbac_user usr
                 on inv.createdby=usr.employeeid  
    			 left join phrm_txn_invoiceitems as item
    			  on inv.invoiceid= item.invoiceid
    			 inner join phrm_mst_counter phrmcnt
    			 on item.counterid = phrmcnt.counterid    
                  where  (inv.createon)::timestamp   between coalesce(p_fromdate,current_timestamp)  and coalesce(p_todate,current_timestamp)+1 
                  group by (inv.createon)::date,username, countername,inv.paidamount,inv.discountamount
    			  
    			  union all
    			 
    			  select (invret.createdon)::date AS "Date", phrmcnt.countername, usr.username, 0 AS "TotalAmount",invret.totalamount as returnamount, (-(invret.discountpercentage/100)*invret.subtotal ) as discountpercentage
    			  from"phrm_txn_invoicereturnitems" invret
    			  inner join rbac_user usr
    			  on invret.createdby = usr.employeeid
    			  inner join phrm_mst_counter phrmcnt
    			 on invret.counterid = phrmcnt.counterid  
    			  where (invret.createdon)::timestamp   between coalesce(p_fromdate,current_timestamp)  and coalesce(p_todate,current_timestamp)+1
    			  group by (invret.createdon)::date,username, countername,invret.totalamount,invret.discountpercentage,invret.subtotal
    			  )	  tabletotal
    			  group by "date", username, countername,totalamount, returnamount, discountamount;
          end if;
    end;
END;
$$ LANGUAGE plpgsql;