CREATE OR REPLACE FUNCTION sp_dashboard_lab_testcompletetoday(

)
RETURNS TABLE (
    "ReportTemplateShortName" VARCHAR,
    "TestCount" INT
) AS $$
BEGIN
    
    /************************************************************************
    filename: "sp_dashboard_lab_trendinglabtest"   
    createdby/date: prem: 3rd jan,2023
    description: to get details of  test completed for dashboard
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1.    prem						initial daft
    *************************************************************************/
    	RETURN QUERY SELECT labrpt.reporttemplateshortname,
    			count(requisitionid) AS "TestCount" 
    	from lab_testrequisition labreq 
    			 join lab_reporttemplate labrpt on labreq.reporttemplateid = labrpt.reporttemplateid				
    	where labreq.isactive=1 and (orderstatus='result-added' or orderstatus='report-generated') 
    	and (billingstatus='unpaid' or	billingstatus='paid')
    	and resultaddedon between((current_timestamp)::date) and (dateadd(day, 1, current_timestamp))::date
    	group by labrpt.reporttemplateshortname;
END;
$$ LANGUAGE plpgsql;