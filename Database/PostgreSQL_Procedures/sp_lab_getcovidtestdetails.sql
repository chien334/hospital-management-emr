CREATE OR REPLACE FUNCTION sp_lab_getcovidtestdetails(
    p_testname VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "TotalTest" DECIMAL,
    "TotalNegative" DECIMAL,
    "TotalPositive" DECIMAL,
    "TotalPendingTests" DECIMAL
) AS $$
BEGIN
    
    RETURN QUERY SELECT * from 
    
    (select count(*) AS "TotalTest",
    	sum( case when "value" = 'Negative' then 1 else 0 end) AS "TotalNegative",
    	sum( case when "value" = 'Positive' then 1 else 0 end) AS "TotalPositive",
    	sum( case when (req.orderstatus ='pending' or req.orderstatus ='active') then 1 else 0 end) AS "TotalPendingTests"
    	from lab_testrequisition req
    	left join lab_txn_testcomponentresult result on req.requisitionid = result.requisitionid
    	join lab_labtests test on req.labtestid = test.labtestid
    	--where test.labtestname = 'RT-PCR NCOV-2' and test.isactive = 1) tilldate,
        where test.labtestname = p_testname and test.isactive = 1) tilldate,
    
    	(select count(*) as "totaltesttoday",
    	coalesce( sum( case when "value" = 'Negative' then 1 else 0 end),0) as totalnegativetoday,
    	coalesce( sum( case when "value" = 'Positive' then 1 else 0 end),0) as totalpositivetoday,
    	coalesce( sum( case when (req.orderstatus ='pending' or req.orderstatus ='active') then 1 else 0 end),0) as pendingteststoday
    	from lab_testrequisition req
    	left join lab_txn_testcomponentresult result on req.requisitionid = result.requisitionid
    	join lab_labtests test on req.labtestid = test.labtestid
    	where test.labtestname = p_testname and test.isactive = 1 
    	and req.orderdatetime between((current_timestamp)::date) and (dateadd(day, 1, current_timestamp))::date) today;
END;
$$ LANGUAGE plpgsql;