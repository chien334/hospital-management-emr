CREATE OR REPLACE FUNCTION sp_report_ageclassifiedreport(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_departmentid INT DEFAULT 0
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    v_cols VARCHAR;
    v_sqlquery VARCHAR;
BEGIN
    /*
    filename: "sp_report_ageclassifiedreport"
    createdby/date: 
    description: to get departmentwise ageclassification report  on a given date range
    remarks:    
    change history
    s.no.    updatedby/date            remarks
    1     santosh:28june'23               Complete rewrite as per new requirement to show sum in the given date range
    */
    
       
    OPEN ref1 FOR SELECT v_cols = (SELECT  FN_COMMON_AgeClassifiedColumnNames('ageclassification') );
        RETURN NEXT ref1;
    
    
    v_sqlquery := N'
    declare v_agegroup varchar(20)    
    declare v_mindate int    
    declare v_maxdate int     
    
    declare v_temp table(     
    departmentname text,    
    visitcount int,    
    agegroup text 
    )
    
    declare departmentagereport cursor for 
    select agename,minageindays,maxageindays from core_mst_ageclassification where reporttype=''ageclassification''
    open departmentagereport 
    fetch next from departmentagereport into v_agegroup,v_mindate,v_maxdate
    while @v_fetch_status=0 
    begin
    insert into v_temp   select 
    
        md.departmentname,
        count(pv.patientvisitid) as visitcount,
        v_agegroup+''m'' as agegroup
    from pat_patient    pt
        inner join pat_patientvisits pv on pt.patientid=pv.patientid
        inner join mst_department md on md.departmentid=pv.departmentid
    where 
    datediff(day,dateofbirth,pv.visitdate) between v_mindate and v_maxdate and gender=''male''
    and
    convert(date,pv.visitdate) between convert(date, '''||(p_fromdate)::VARCHAR||''')     and convert(date,'''|| (p_todate)::VARCHAR||''')
    and 
    pv.departmentid=iif(convert(int,'||(p_departmentid)::VARCHAR||')=0,pv.departmentid, convert(int,'||(p_departmentid)::VARCHAR||'))
    group by departmentname,gender;
    insert into v_temp 
    select 
    
        md.departmentname,
        count(pv.patientvisitid) as visitcount,
        v_agegroup+''f'' as agegroup
    from pat_patient    pt
        inner join pat_patientvisits pv on pt.patientid=pv.patientid
        inner join mst_department md on md.departmentid=pv.departmentid
    where 
        datediff(day,dateofbirth,pv.visitdate) between v_mindate and v_maxdate and gender=''female''
        and
    convert(date,pv.visitdate) between convert(date, '''||(p_fromdate)::VARCHAR||''') and convert(date,'''|| (p_todate)::VARCHAR||''')
    and 
    pv.departmentid=iif(convert(int,'||(p_departmentid)::VARCHAR||')=0,pv.departmentid, convert(int,'||(p_departmentid)::VARCHAR||'))
    group by departmentname,gender;
    fetch next from departmentagereport into v_agegroup,v_mindate,v_maxdate
    end
    close departmentagereport    
    deallocate departmentagereport
    select * from v_temp
    pivot
    (
        sum (visitcount)
        for 
        agegroup in (' || v_cols || N')
    )  p ';
    open ref1 for execute v_sqlquery;
        return next ref1;
END;
$$ LANGUAGE plpgsql;