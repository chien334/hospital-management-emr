CREATE OR REPLACE FUNCTION sp_rpt_departmentwiserankcountreport(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_departmentids VARCHAR DEFAULT NULL,
    p_ranknames VARCHAR DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    v_columns VARCHAR := '';
		
    v_sql VARCHAR := '';
BEGIN
    begin
    	if(p_departmentids is null or p_departmentids = '')
    	then p_departmentids := ''; end if; 
    
    	if(p_ranknames is null or p_ranknames ='')
    	then p_ranknames := ''; end if; 
    	
    	
    	begin
    		open ref1 for select v_columns ||= quotename(membershiptypename) || ','
    		from pat_cfg_membershiptype;
        return next ref1;
    		v_columns := left(v_columns, len(v_columns) - 1);
    
    		v_sql := 'SELECT *
    						FROM (
    							SELECT dep.DepartmentName
    								,pat.Rank
    								,pat.PatientId
    								,memtype.MembershipTypeName
    							FROM PAT_Patient pat
    							INNER JOIN PAT_PatientVisits visit ON pat.PatientId = visit.PatientId
    							INNER JOIN MST_Department dep ON visit.DepartmentId = dep.DepartmentId
    							INNER JOIN PAT_CFG_MembershipType memtype ON pat.MembershipTypeId=memtype.MembershipTypeId
    							WHERE pat.Rank IS NOT NULL AND 
    							CONVERT(DATE,visit.VisitDate) BETWEEN CONVERT(DATE,''' || ((coalesce(p_fromdate, current_timestamp))::date)::varchar || ''') 
    							AND CONVERT(DATE,''' || ((coalesce(p_todate, current_timestamp))::date)::varchar || ''')
    							AND (dep.DepartmentId IN (SELECT VALUE FROM STRING_SPLIT('''||p_departmentids||''' ,'''||','||''')) OR  '''||p_departmentids||''' = '''||''')
    							AND (pat.Rank IN (SELECT VALUE FROM STRING_SPLIT('''||p_ranknames||''' ,'''||','||''')) OR   '''||p_ranknames||''' = '''||''')
    							) AS SourceTable
    						PIVOT(
    						COUNT(PatientId)  FOR SourceTable.MembershipTypeName  IN (' || v_columns || ')
    						) AS Pvt';
    	end;
    	open ref1 for execute v_sql;
        return next ref1;
    end;
END;
$$ LANGUAGE plpgsql;