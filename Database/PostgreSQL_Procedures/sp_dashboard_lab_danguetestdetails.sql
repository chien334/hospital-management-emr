CREATE OR REPLACE FUNCTION sp_dashboard_lab_danguetestdetails(

)
RETURNS TABLE (
    "TimePeriod" TIMESTAMP,
    "ResultNotFinalizedCount" INT,
    "PositiveCount" INT,
    "NegativeCount" INT,
    "TotalCount" INT
) AS $$
DECLARE
    v_testid INT;
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
    	
    	
    	 
    			v_testid := (
    					select labtestid from lab_labtests 
    					where labtestname like 'Dengue%');
    	
    	RETURN QUERY SELECT 'TillNow' AS "TimePeriod", sum(resultnotfinalized) AS "ResultNotFinalizedCount" , sum(positivecount) AS "PositiveCount",sum(negativecount) AS "NegativeCount",
    	sum(resultnotfinalized+positivecount+negativecount) AS "TotalCount"
    	from
    	(select  req.labtypename,  req.patientid,
    		req.labtestname, req.createdon,
    	   case when req.orderstatus in ('active','pending') then 1 else 0 end as resultnotfinalized   ,
    	   case when req.orderstatus in ('report-generated','result-added') and res.value = 'Positive' then 1 else 0 end AS "PositiveCount",
    	   case when req.orderstatus in ('report-generated','result-added') and res.value is null then 1 else 0 end AS "NegativeCount"
    	from lab_testrequisition req
    	left join (select distinct requisitionid, value
    				from lab_txn_testcomponentresult
    				where labtestid=v_testid and value='Positive' and isactive=1
    				) res
    	on req.requisitionid = res.requisitionid
    	where req.labtestid = v_testid
    	and req.billingstatus in ('paid','unpaid','provisional')
    	)restemptillnow   
    	union all
    	select 'Today' AS "TimePeriod",coalesce(sum(resultnotfinalized),0) AS "ResultNotFinalizedCount"  , sum(resultnotfinalized+positivecount+negativecount) AS "TotalCount",
    			coalesce(sum(positivecount),0) AS "PositiveCount"   ,coalesce(sum(negativecount),0) AS "NegativeCount"   
    	from
    	(select  req.labtypename,  req.patientid,
    		req.labtestname, req.createdon,
    	   case when req.orderstatus in ('active','pending') then 1 else 0 end as resultnotfinalized   ,
    	   case when req.orderstatus in ('report-generated','result-added') and res.value = 'Positive' then 1 else 0 end AS "PositiveCount",
    	   case when req.orderstatus in ('report-generated','result-added') and res.value is null then 1 else 0 end AS "NegativeCount"
    	from lab_testrequisition req
    	left join (select distinct requisitionid, value
    				from lab_txn_testcomponentresult
    				where labtestid=v_testid and value='Positive' and isactive=1
    				) res
    	on req.requisitionid = res.requisitionid
    	where req.labtestid = v_testid
    	and (req.orderdatetime)::date=current_timestamp
    	and req.billingstatus in ('paid','unpaid','provisional')
    	)restemptoday;
END;
$$ LANGUAGE plpgsql;