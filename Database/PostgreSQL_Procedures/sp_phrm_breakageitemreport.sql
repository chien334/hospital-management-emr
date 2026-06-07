CREATE OR REPLACE FUNCTION sp_phrm_breakageitemreport(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL
)
RETURNS TABLE (
    "Date" TIMESTAMP,
    "UserName" VARCHAR,
    "ItemName" VARCHAR,
    "SalePrice" DECIMAL,
    "BreakageQty" INT,
    "TotalAmount" DECIMAL
) AS $$
BEGIN
    /*
    filename: "[sp_phrm_breakageitemreport"]
    createdby/date:vikas/2018-08-10
    description: .
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1      vikas/2018-08-10	              created the script
    2	   rusha/2019-03-31				  add writeoff quantity 
    3      rohit/13feb'23						mrp-> saleprice
    */
    begin
    	if (
    			(p_fromdate is not null)
    			and (p_todate is not null)
    			)
    	then
    		RETURN QUERY SELECT (wi.createdon)::date AS "Date"
    			,usr.username
    			,i.itemname
    			,itemprice AS "SalePrice"
    			,writeoffquantity AS "BreakageQty"
    			,round(sum(wi.totalamount), 2, 0) AS "TotalAmount"
    		from phrm_writeoffitems wi
    		join rbac_user usr on wi.createdby = usr.employeeid
    		join phrm_mst_item i on i.itemid = wi.itemid
    		where (wi.createdon)::date between p_fromdate
    				and p_todate
    		group by (wi.createdon)::date
    			,usr.username
    			,i.itemname
    			,itemprice
    			,writeoffquantity;
    	end if;
    end;
END;
$$ LANGUAGE plpgsql;