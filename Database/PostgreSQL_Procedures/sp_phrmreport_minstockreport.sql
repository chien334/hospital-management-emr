CREATE OR REPLACE FUNCTION sp_phrmreport_minstockreport(
    p_itemname VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "ItemId" INT,
    "ItemName" VARCHAR,
    "Quantity" INT,
    "ExpiryDate" TIMESTAMP,
    "BatchNo" VARCHAR,
    "MinStockQuantity" INT
) AS $$
BEGIN
    /*
    filename: "sp_phrmreport_minstockreport"
    createdby/date: vikas/2018-08-21
    description: 
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    	1.	vikas/28aug'18						created the script
    	2.	Rusha/04-01-2019					sum up quantity
    	3.	Rusha/07-08-2019					updated script
    	4.	Naveed/13-12-2019				    updated script for exclude zero quantity Items
    */
    Begin 
    IF (p_itemname IS NOT NULL)
    	THEN
    
    	RETURN QUERY SELECT * FROM
    	(
    		SELECT a.ItemId ,a.ItemName, SUM(InQty-OutQty+FInQty-FOutQty) AS "Quantity",(a.ExpiryDate)::date AS "ExpiryDate",
    		a.BatchNo,a.MinStockQuantity 
    		FROM 
    			(SELECT itm.ItemId ,itm.ItemName,itm.MinStockQuantity,(stk.ExpiryDate)::dateas AS "ExpiryDate",stk.BatchNo,
    					SUM(CASE WHEN stk.InOut = 'in' THEN stk.Quantity ELSE 0 END) AS "InQty",
    					SUM(CASE WHEN stk.InOut = 'out' THEN stk.Quantity ELSE 0 END) AS "OutQty",
    					SUM(CASE WHEN stk.InOut = 'in' THEN stk.FreeQuantity ELSE 0 END) AS "FInQty",
    					SUM(CASE WHEN stk.InOut = 'out' THEN stk.FreeQuantity ELSE 0 END) AS "FOutQty"
    			FROM  PHRM_StockTxnItems stk
    			JOIN  PHRM_MST_Item itm
    			ON stk.ItemId=itm.ItemId
    			WHERE itm.MinStockQuantity != 0 
    			GROUP BY itm.ItemId ,itm.ItemName,(stk.ExpiryDate)::date,stk.BatchNo,itm.MinStockQuantity) a
    		WHERE (((p_itemname=a.ItemName OR p_itemname='') or a.ItemName like '%'||COALESCE(p_itemname,'')||'%' )) 
    		group by a.itemid,a.itemname,a.batchno,a.expirydate,a.minstockquantity
    	) s		
    	where s.quantity < s.minstockquantity and s.quantity>0
    	group by s.itemid, s.itemname,s.quantity,s.expirydate,s.batchno,s.minstockquantity;
    
    	end if;
    end;
END;
$$ LANGUAGE plpgsql;