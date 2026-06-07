CREATE OR REPLACE FUNCTION sp_dsb_lab_dashboardstatistics(

)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
    ref3 refcursor := 'cursor3';
BEGIN
    /*
    =============================================================================================
    filename: "sp_dsb_lab_dashboardstatistics"
    description: table1:to get stats for lab dashboard --> to fill labels
    					-->> for sample pending	-->> orderstatus = active && (billingstatus == unpaid || billingstatus == paid) && isactive=true
    					-->> for results pending	-->> orderstatus = pending && (billingstatus == unpaid || billingstatus == paid) && isactive=true
    					-->> for test completed	-->> orderstatus = result-added or report-generated && (billingstatus == unpaid || billingstatus == paid) && isactive=true
    					-->> for tests cancelled	-->> billingstatus = cancel && isactive=true
    					-->> for tests returned	-->> billingstatus = return && isactive=true
    					-->> for total test		-->> count all where isactive=true
    			table2:to get stats for lab dashboard --> for trending labtest (last 30 days)
    					takes count of labtest - grouping by them with labtestname, ordering them in descending order and selecting top 10 only
    			table3:to get count of labtest performed today ( templete wise count is shown)
    
    
    edited by anish: 2 june, 2020 new updated status added 
    =============================================================================================
    */
    
    
    --table1
    	open ref1 for select * from 
    		(select count(*) as "totalavailabletest" from lab_labtests where isactive=1) labtest,
    		(select
    			coalesce(sum(1),0) as "testrequisitedtoday",
    			coalesce(sum( case when orderstatus = 'active' and isactive=1 and (billingstatus <> 'cancel' and billingstatus <> 'returned') then 1 else 0 end ),0) as "samplependingtoday",
    			coalesce(sum( case when orderstatus = 'pending' and isactive=1 and (billingstatus <> 'cancel' and billingstatus <> 'returned') then 1 else 0 end ),0) as "addresultspendingtoday",
    			coalesce(sum( case when (orderstatus = 'result-added' or orderstatus = 'report-generated') and isactive=1 and (billingstatus <> 'cancel' and billingstatus <> 'returned') then 1 else 0 end ),0) as "completedtoday",
    			coalesce(sum( case when billingstatus='cancel'and isactive=1 then 1 else 0 end ),0) as "cancelledteststoday",
    			coalesce(sum( case when billingstatus = 'returned'and isactive=1 then 1 else 0 end ),0) as "returnedteststoday"
    			from lab_testrequisition where (orderdatetime)::date = (current_timestamp)::date
    		) today,
    		(select
    			sum(1) as "testrequisitedtilldate",
    			sum( case when orderstatus = 'active' and isactive=1 and (billingstatus <> 'cancel' and billingstatus <> 'returned') then 1 else 0 end ) as "samplependingtilldate",
    			sum( case when orderstatus = 'pending' and isactive=1 and (billingstatus <> 'cancel' and billingstatus <> 'returned') then 1 else 0 end ) as "addresultspendingtilldate",
    			sum( case when (orderstatus = 'result-added' or orderstatus = 'report-generated') and isactive=1 and (billingstatus <> 'cancel' and billingstatus <> 'returned') then 1 else 0 end ) as "completedtilldate",
    			sum( case when billingstatus='cancel'and isactive=1 then 1 else 0 end ) as "cancelledteststilldate",
    			sum( case when billingstatus = 'returned' and isactive=1 then 1 else 0 end ) as "returnedteststilldate"
    			from lab_testrequisition
    		) tilldate;
        return next ref1;
    --table2
    	open ref2 for select  labtestname,count(labtestname) as counts from lab_testrequisition 
    		where isactive=1 and (datediff(day,orderdatetime,current_timestamp) between 0 and 30)
    		group by labtestname
    		order by counts desc limit 10;
        return next ref2;
    --table3
    	open ref3 for select reporttemplatename,count(req.labtestname) as "counts" from lab_testrequisition req 
    		join lab_labtests test on req.labtestid=test.labtestid
    		join lab_reporttemplate reprt on test.reporttemplateid=reprt.reporttemplateid
    		where  req.isactive=1 and ((orderdatetime)::date = (current_timestamp)::date)
    		group by reporttemplatename;
        return next ref3;
END;
$$ LANGUAGE plpgsql;