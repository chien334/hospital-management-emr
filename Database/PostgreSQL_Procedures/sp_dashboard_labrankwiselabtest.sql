CREATE OR REPLACE FUNCTION sp_dashboard_labrankwiselabtest(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL
)
RETURNS TABLE (
    "Rank" VARCHAR,
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
    		pat.rank,
    		count(labreq.requisitionid) AS "TotalCount" 
    	from lab_testrequisition labreq 
    	inner join pat_patient pat on labreq.patientid = pat.patientid 
    	where 
    		labreq.isactive=1 
    		and (orderstatus='result-added' or orderstatus='report-generated') 
    		and (billingstatus='unpaid' or billingstatus='paid') 
    		and  billingstatus!='cancel'
    		and (pat.rank is not null or pat.rank!='')
    		and (orderdatetime)::date between p_fromdate and p_todate 
    	group by pat.rank;
END;
$$ LANGUAGE plpgsql;