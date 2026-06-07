CREATE OR REPLACE FUNCTION sp_report_totalrevenuefromlab(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL
)
RETURNS TABLE (
    "Date" TIMESTAMP,
    "TotalRevenue" DECIMAL,
    "TotalDiscount" INT,
    "TotalTax" DECIMAL
) AS $$
BEGIN
    /*
    filename: "sp_report_totalrevenuefromlab" 
    description: to get the total revenue from lab 
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1       rusha 2019-09-23					to get daily total revenue
    */
    begin
    	    if(p_fromdate is not null or p_todate is not null or len(p_fromdate)>0 or len(p_todate)>0)
    		then
    			RETURN QUERY SELECT   (paiddate)::date AS "Date",sum(totalamount) AS "TotalRevenue",
    					 sum(discountamount) AS "TotalDiscount", sum(coalesce(taxableamount,0)) AS "TotalTax" 
    					 from bil_txn_billingtransactionitems bt
    					 join bil_mst_servicedepartment sd on  sd.servicedepartmentid = bt.servicedepartmentid
    					 where sd.integrationname = 'LAB' and bt.returnstatus is null
    					 and (paiddate)::date between p_fromdate and p_todate 
    			group by (paiddate)::date; 
    		end if;
    end;
END;
$$ LANGUAGE plpgsql;