CREATE OR REPLACE FUNCTION sp_lab_allrequisitionsby_visitandruntype(
    p_groupingindex INT,
    p_patientid INT,
    p_sampledate DATE,
    p_labtypename VARCHAR
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
    v_startdate DATE;
    v_enddate DATE;
    v_rangetype VARCHAR;
BEGIN
    
    	
    	
    	
    
    	select (
    			case 
    				when settingrow.resetdaily = 1
    					then 'day'
    				when settingrow.resetmonthly = 1
    					then 'month'
    				when settingrow.resetyearly = 1
    					then 'year'
    				else ''
    				end
    			) into v_rangetype from (
    		select  *
    		from lab_mst_runnumbersettings
    		where runnumbergroupingindex = p_groupingindex limit 1
    		) settingrow;
    
    	select daterange.startdate, daterange.enddate into v_startdate, v_enddate from (
    		select *
    		from fn_common_getnepstartenddate_byrangename(p_sampledate, v_rangetype)
    		) daterange;
    
    	open ref1 for select max(lastsamplenumber) + 1 as latestsamplecode
    	from (
    		select lastsamplenumber
    		from (
    			select max(samplecode) as lastsamplenumber
    			from lab_testrequisition req
    			join lab_mst_runnumbersettings sett on (lower(req.visittype) = lower(sett.visittype))
    				and (lower(req.runnumbertype) = lower(sett.runnumbertype))
    				and (req.hasinsurance = sett.underinsurance)
    			where sett.runnumbergroupingindex = p_groupingindex
    				and samplecode is not null
    				and req.labtypename = p_labtypename
    				and samplecreatedon is not null
    				and (samplecreatedon)::date between v_startdate
    					and v_enddate
    			group by req.samplecode
    			) as reqlist
    		
    		union
    		
    		(
    			select 0 as lastsamplenumber
    			)
    		) allreqlist;
        return next ref1;
    
    	open ref2 for select distinct  samplecode as samplenumber
    		,barcodenumber
    		,samplecodeformatted
    		,0 as isselected
    		,samplecreatedon as sampledate
    	from lab_testrequisition req
    	join lab_mst_runnumbersettings sett on (lower(req.visittype) = lower(sett.visittype))
    		and (lower(req.runnumbertype) = lower(sett.runnumbertype))
    		and (req.hasinsurance = sett.underinsurance)
    	where sett.runnumbergroupingindex = p_groupingindex
    		and samplecode is not null
    		and req.labtypename = p_labtypename
    		and samplecreatedon is not null
    		and (samplecreatedon)::date between v_startdate
    			and v_enddate
    		and req.patientid = p_patientid
    		and req.barcodenumber is not null
    	order by barcodenumber desc limit 1;
        return next ref2;
END;
$$ LANGUAGE plpgsql;