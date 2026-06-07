CREATE OR REPLACE FUNCTION sp_lab_getpatientexistingrequisition_with_samerunnumber(
    p_groupingindex INT,
    p_sampledate DATE,
    p_samplecode INT,
    p_patientid INT
)
RETURNS TABLE (
    "*" VARCHAR
) AS $$
DECLARE
    v_startdate DATE;
    v_enddate DATE;
    v_rangetype VARCHAR;
BEGIN
    
    	
    	
    	
    	
    
    
    	select (case 
    						when settingrow.resetdaily=1 
    						then 'day'
    						when settingrow.resetmonthly=1
    						then 'month'
    						when settingrow.resetyearly=1
    						then 'year'
    						else ''
    						end
    						) into v_rangetype from (select  * from lab_mst_runnumbersettings where runnumbergroupingindex=p_groupingindex limit 1) settingrow;
    
    	select daterange.startdate, daterange.enddate into v_startdate, v_enddate from (select * from fn_common_getnepstartenddate_byrangename(p_sampledate,v_rangetype)) daterange;
    
    	RETURN QUERY SELECT * from lab_testrequisition req join lab_mst_runnumbersettings sett 
    		on (lower(req.visittype) = lower(sett.visittype)) and (lower(req.runnumbertype) = lower(sett.runnumbertype)) and (req.hasinsurance=sett.underinsurance) 
    		where sett.runnumbergroupingindex=p_groupingindex and samplecode is not null and (samplecode=p_samplecode) and req.patientid=p_patientid
    		and samplecreatedon is not null and (samplecreatedon)::date between v_startdate and v_enddate;
END;
$$ LANGUAGE plpgsql;