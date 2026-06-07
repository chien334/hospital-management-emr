CREATE OR REPLACE FUNCTION sp_phrm_cashcollectionsummaryreport(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_storeid INT DEFAULT NULL
)
RETURNS TABLE (
    "Date" TIMESTAMP,
    "UserName" VARCHAR,
    "TotalAmount" DECIMAL,
    "ReturnedAmount" DECIMAL,
    "NetAmount" DECIMAL,
    "DiscountAmount" INT,
    "DepositAmount" DECIMAL,
    "DepositReturn" VARCHAR,
    "StoreName" VARCHAR
) AS $$
BEGIN
    /*
    filename: "[sp_phrm_cashcollectionsummaryreport"]
    createdby/date: dinesh 2nd sept 2019 
    description: .
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1       dinesh 2nd sept 2019                created the script
    2		ashish 14th jan 2020				fix bug provisional credit invoice amount showing  --if transaction is provisional and paymenttype is credit then entry into settlement tbl  	
    3       shankar 17th march 2020	            deducted from deposit amount was showing in user collection which is fixed here on.
    4       ramesh/sanjit 5th may 2021          added storeid as a parameter for selected store details
    5		ramesh/sanjit 7th sep, 2021			invoice return payment mode filter added.
    */
     begin
      if ((p_fromdate is not null) and (p_todate is not null)) 
        then
    	RETURN QUERY SELECT tabletotal."date", tabletotal.username, sum(tabletotal.totalamount) AS "TotalAmount", sum(tabletotal.returnamount) AS "ReturnedAmount", sum((tabletotal.totalamount+tabletotal.depositamount)-(tabletotal.returnamount+tabletotal.depositreturn)) AS "NetAmount", sum(tabletotal.discountamount) AS "DiscountAmount", sum(tabletotal.depositamount) AS "DepositAmount", sum(tabletotal.depositreturn) AS "DepositReturn", coalesce(s.name,'') AS "StoreName"
    	from ( 
              select (inv.createon)::date AS "Date" ,usr.username,sum(inv.paidamount)AS "TotalAmount", 0 as returnamount,sum(inv.discountamount) AS "DiscountAmount",  0 AS "DepositAmount", 0 AS "DepositReturn", inv.storeid as storeid
                from "phrm_txn_invoice" inv
                  inner join rbac_user usr
                 on inv.createdby=usr.employeeid      
                  where  ((inv.createon)::timestamp   between coalesce(p_fromdate,current_timestamp)  and coalesce(p_todate,current_timestamp)+1 ) and inv.bilstatus='paid' and inv.settlementid is null and inv.depositdeductamount=0 and (inv.storeid = p_storeid or p_storeid is null)
                  group by (inv.createon)::date,username, storeid
    			  
    			 
    			  union all 
    			    select (stl.createdon)::date AS "Date" ,usr.username,sum(stl.payableamount)AS "TotalAmount", 0 as returnamount,sum(stl.discountamount) AS "DiscountAmount",  0 AS "DepositAmount", 0 AS "DepositReturn", null as storeid
                from "phrm_txn_settlement" stl
                  inner join rbac_user usr
                 on stl.createdby=usr.employeeid
                  where  ((stl.createdon)::timestamp   between coalesce(p_fromdate,current_timestamp)  and coalesce(p_todate,current_timestamp)+1 ) and (p_storeid is null)
                  group by (stl.createdon)::date,username
    			  
    			  union all
    			  select (invret.createdon)::date AS "Date", usr.username, 0 AS "TotalAmount",sum(invret.totalamount ) as returnamount,  sum(discountamount) AS "DiscountAmount", 0 AS "DepositAmount", 0 AS "DepositReturn",invret.storeid as storeid
    			  from"phrm_txn_invoicereturn" invret
    			  inner join rbac_user usr
    			  on invret.createdby = usr.employeeid
    			  where (invret.createdon)::timestamp   between coalesce(p_fromdate,current_timestamp)  and coalesce(p_todate,current_timestamp)+1 
    					and invret.paymentmode != 'credit'
    					and invret.invoiceid is not null and (invret.storeid = p_storeid or p_storeid is null)
    			  group by (invret.createdon)::date,username, storeid
    
    			  union all
    			  select (depo.createdon)::date AS "Date", usr.username, 0 AS "TotalAmount", 0 as returnamount, 0 AS "DiscountAmount", sum(depo.depositamount) AS "DepositAmount", 0 AS "DepositReturn",depo.storeid as storeid
    			  from phrm_deposit as depo
    			  inner join rbac_user as usr
    			  on depo.createdby = usr.employeeid
    			  where (depo.createdon)::timestamp   between coalesce(p_fromdate,current_timestamp)  and coalesce(p_todate,current_timestamp)+1 and depo.deposittype = 'deposit' and (depo.storeid = p_storeid or p_storeid is null)
    			  group by (depo.createdon)::date, username, storeid
    
    			  union all
    			  select (depo.createdon)::date AS "Date", usr.username, 0 AS "TotalAmount", 0 as returnamount, 0 AS "DiscountAmount", 0 AS "DepositAmount", sum(depo.depositamount) AS "DepositReturn",depo.storeid as storeid
    			  from phrm_deposit as depo
    			  inner join rbac_user as usr
    			  on depo.createdby = usr.employeeid
    			  where (depo.createdon)::timestamp   between coalesce(p_fromdate,current_timestamp)  and coalesce(p_todate,current_timestamp)+1 and depo.deposittype ='depositreturn' and (depo.storeid = p_storeid or p_storeid is null)
    			  group by (depo.createdon)::date, username, storeid
    
    
    			  )	  tabletotal
    			  left join phrm_mst_store s on tabletotal.storeid = s.storeid
    			  group by "date", username, s.name;
          end if;
    end;
END;
$$ LANGUAGE plpgsql;