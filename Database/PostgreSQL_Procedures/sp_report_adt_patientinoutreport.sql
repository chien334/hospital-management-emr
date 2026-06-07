/* =============================================
-- Author:		Anish Bhattarai
-- Create date: June 4, 2020
S.No.   Date/Author           Remarks
1.     14June'10/Sud         Excluded Action='cancel' from patientbedinfo. this is when admission is cancelled.
-- ============================================= */
CREATE OR REPLACE FUNCTION sp_report_adt_patientinoutreport(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
    ref3 refcursor := 'cursor3';
    ref4 refcursor := 'cursor4';
BEGIN
    begin
    	if(p_fromdate is not null or p_todate is not null)
    	then
    
    	
    	--table1 for all wardname
    	open ref1 for select distinct(ward.wardname) from adt_txn_patientbedinfo bedinf join adt_mst_ward ward on bedinf.wardid=ward.wardid;
        return next ref1;
    
    	--table2 for all admisssion and transin
    	open ref2 for select flatdata.wardname, flatdata.action, count(*) as totalcount
    	from (select bedinfo.*,ward.wardname from adt_txn_patientbedinfo bedinfo
    	join adt_mst_ward ward on bedinfo.wardid=ward.wardid
    	where bedinfo.isactive=1 
    	and bedinfo.action !='cancel'
    	and (bedinfo.startedon)::date between p_fromdate and p_todate) as flatdata group by flatdata.wardname, flatdata.action;
        return next ref2; 
    
    	--table3 for all discharged and transout
    	open ref3 for select flatdata.wardname, flatdata.outaction, count(*) as totalcount
    	from (select bedinfo.*,ward.wardname from adt_txn_patientbedinfo bedinfo
    	join adt_mst_ward ward on bedinfo.wardid=ward.wardid
    	where bedinfo.isactive=1 
    	and bedinfo.action !='cancel'
    	and (bedinfo.endedon)::date between p_fromdate and p_todate) as flatdata group by flatdata.wardname, flatdata.outaction;
        return next ref3;
    
    
    	--table4 for total inbed count
    	open ref4 for select flatdata.wardname, count(*) as totalcount
    	from (select bedinfo.*,ward.wardname from adt_txn_patientbedinfo bedinfo
    	join adt_mst_ward ward on bedinfo.wardid=ward.wardid
    	where bedinfo.isactive=1 
    	and bedinfo.action !='cancel'
    	and (bedinfo.startedon)::date < p_fromdate 
    	and   p_fromdate <= (coalesce(bedinfo.endedon,current_timestamp))::date)
    	as flatdata group by flatdata.wardname;
        return next ref4;
    
    	--select flatdata.wardname, count(*) as totalcount
    	--from (select bedinfo.*,ward.wardname from adt_txn_patientbedinfo bedinfo
    	--join adt_mst_ward ward on bedinfo.wardid=ward.wardid
    	--where bedinfo.isactive=1 and bedinfo.endedon is null 
    	--and bedinfo.outaction is null and convert(date,bedinfo.startedon) < p_fromdate
    	--and ((bedinfo.action='admission') or (bedinfo.action='transfer'))) as flatdata group by flatdata.wardname, flatdata.outaction
    
    	end if;
    
    end;
END;
$$ LANGUAGE plpgsql;