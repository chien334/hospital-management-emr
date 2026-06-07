CREATE OR REPLACE FUNCTION sp_dashboard_lab_trendinglabtest(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL
)
RETURNS TABLE (
    "LabTestName" VARCHAR,
    "Counts" INT
) AS $$
BEGIN
    
    /************************************************************************
    filename: "sp_dashboard_lab_trendinglabtest"   
    createdby/date: prem: 3rd jan,2023
    description: to get details of top 10 trending lab test for dashboard
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1.    prem						initial daft
    *************************************************************************/
    	RETURN QUERY SELECT  
    		labtestname,
    		count(labtestname) AS "Counts" 
    	from 
    		lab_testrequisition 
    	where 
    		isactive=1 
    		and (billingstatus='paid' or billingstatus='unpaid')
    		and (orderdatetime)::date between p_fromdate and p_todate
    	group by labtestname
    	order by counts desc limit 10;
END;
$$ LANGUAGE plpgsql;