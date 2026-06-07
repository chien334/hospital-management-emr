CREATE OR REPLACE FUNCTION sp_dashboard_lab_abnormalnormaltestcount(
    p_labtestid INT
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
    ref3 refcursor := 'cursor3';
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
    
    	create temp table temp_daterangeinmonths
    	(
    		sn int,
    		months varchar(20)
    	);
    	insert into temp_daterangeinmonths
    		(sn,months)
    	values
    			(1,'Jan'),
    			(2,'Feb'),
                (3,'Mar'),
                (4,'Apr'),
                (5,'May'),
                (6,'Jun'),
                (7,'Jul'),
                (8,'Aug'),
                (9,'Sep'),
                (10,'Oct'),
    			(11,'Nov'),
                (12,'Dec');
    
    
    select months.months,count(res.testcomponentresultid) as totalcount,'Normal' as "testresulttype" from temp_daterangeinmonths months
    left join  
    (select 
    testcomponentresultid ,
    "datedifferenefordashboard"(createdon) as months
    from lab_txn_testcomponentresult where range is not null
    and isabnormal=0  and isactive=1 and labtestid=p_labtestid
    )res
    on months.months=res.months 
    group by months.months;
    
    --abnormal count
    open ref1 for select months.months,count(res.testcomponentresultid) as totalcount,'Abnormal' as "testresulttype" from temp_daterangeinmonths months
    left join  
    (select 
    testcomponentresultid ,
    "datedifferenefordashboard"(createdon) as months
    from lab_txn_testcomponentresult where range is not null
    and isabnormal=1 and isactive=1 and labtestid=p_labtestid
    )res
    on months.months=res.months 
    group by months.months;
        return next ref1;
    
    --number of visits
    open ref2 for select months.months,count(res.patientvisitid) as totalcount,'NoOfVisits' as "testresulttype" from temp_daterangeinmonths months
    left join  
    (
    select 
    distinct(req.patientvisitid),
    "datedifferenefordashboard"(res.createdon) as months
    from lab_txn_testcomponentresult res
    inner join lab_testrequisition req
    on req.requisitionid=res.requisitionid
    where res.isactive=1 and res.range is not null and res.labtestid=p_labtestid
    )res
    on months.months=res.months 
    group by months.months;
        return next ref2;
    drop table if exists temp_daterangeinmonths;
END;
$$ LANGUAGE plpgsql;