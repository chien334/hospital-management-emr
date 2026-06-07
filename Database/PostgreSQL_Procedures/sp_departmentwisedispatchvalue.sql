CREATE OR REPLACE FUNCTION sp_departmentwisedispatchvalue(
    p_sourcestoreid INT DEFAULT NULL,
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
BEGIN
    /*
    filename: "sp_departmentwisedispatchvalue"
    createdby/date: rohit/1dec'22
    Description: to get Department and DepartmentWiseDispatchedvalue
    Remarks:  
    To Execute : Exec SP_DepartmentWiseDispatchValue NULL,'2022-07-07','2022-12-01'
    			 Exec SP_DepartmentWiseDispatchValue NULL,NULL,NULL
    NOTE:  
    Change History
    S.No.    UpdatedBy/Date                        Remarks
    1       ROHIT/2Dec'22				           created
    
    */
    
    	open ref1 for select dis.targetstoreid
    		,phrm.name
    		,round(sum(dispatchedquantity), 0) as "dispatchedquantity"
    		,round(sum(dis.dispatchedquantity * dis.costprice), 3) as totaldispatchvalue
    	from phrm_mst_store phrm
    	join inv_txn_dispatchitems dis on phrm.storeid = dis.targetstoreid
    	where (
    			dis.sourcestoreid = p_sourcestoreid
    			or p_sourcestoreid is null
    			)
    		and (dis.dispatcheddate)::date between p_fromdate
    			and p_todate
    	group by phrm.name
    		,dis.targetstoreid
    	order by totaldispatchvalue desc;
        return next ref1;
END;
$$ LANGUAGE plpgsql;