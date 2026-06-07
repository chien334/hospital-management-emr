CREATE OR REPLACE FUNCTION sp_dashboard_lab_membershipwiselabtest(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL
)
RETURNS TABLE (
    "MembershipTypeName" VARCHAR,
    "TotalCount" INT
) AS $$
BEGIN
    
    
    /************************************************************************
    filename: "sp_dashboard_lab_trendinglabtest"   
    createdby/date: prem: 3rd jan,2023
    description: to get details of  lab test done according to membershiptype for dashboard
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1.    prem						initial daft
    *************************************************************************/
    	RETURN QUERY SELECT 
    		mem.membershiptypename,
    		count(labreq.requisitionid) AS "TotalCount" 
    	from lab_testrequisition labreq 
    	inner join pat_patient pat on labreq.patientid = pat.patientid 
    	inner join pat_cfg_membershiptype mem on mem.membershiptypeid=pat.membershiptypeid
    	where 
    		labreq.isactive=1 
    		and (orderstatus='result-added' or orderstatus='report-generated') 
    		and (billingstatus='unpaid' or billingstatus='paid') 
    		and billingstatus!='cancel' and (orderdatetime)::date between p_fromdate and p_todate 
    	group by mem.membershiptypename;
END;
$$ LANGUAGE plpgsql;