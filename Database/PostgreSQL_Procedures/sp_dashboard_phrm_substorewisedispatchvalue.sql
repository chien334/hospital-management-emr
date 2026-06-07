CREATE OR REPLACE FUNCTION sp_dashboard_phrm_substorewisedispatchvalue(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL
)
RETURNS TABLE (
    "Name" VARCHAR,
    "TotalDispatchValue" DECIMAL
) AS $$
BEGIN
    /*
     sp_dashboard_phrm_substorewisedispatchvalue '2022-10-3','2022-10-31'
    filename: "sp_dashboard_phrm_substorewisedispatchvalue"
    createdby/date: rohit/2022-12-30
    description: to get information of dispatched value in substores.
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1       rohit/2022-12-30                 created the script
    */
    
    
    	RETURN QUERY SELECT  mststr.name
    		,coalesce(sum(dispatchedquantity * costprice), 0) AS "TotalDispatchValue"
    	from phrm_storedispatchitems d  
    	inner join phrm_mst_store mststr on d.targetstoreid = mststr.storeid
    	where (dispatcheddate)::date between p_fromdate and p_todate and  mststr.category in ('substore','dispensary')
    	group by targetstoreid, mststr.name
    	order by totaldispatchvalue desc limit 10;
END;
$$ LANGUAGE plpgsql;