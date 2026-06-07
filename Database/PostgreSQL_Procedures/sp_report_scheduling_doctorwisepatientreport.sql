CREATE OR REPLACE FUNCTION sp_report_scheduling_doctorwisepatientreport(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_performername VARCHAR DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    v_dynamicpivotquery VARCHAR;
    v_pivotcolumnnames VARCHAR;
    v_pivotselectcolumnnames VARCHAR;
BEGIN
    /*  
    filename: sp_report_scheduling_doctorwisepatientreport  
    createdby/date: umed/2017-06-02  
    description: to get count of appointments per doctor between given dates.  
    remarks:    default current_timestamp for both fromdate and todate.  
    change history  
    s.no.    updatedby/date                        remarks  
    1.       umed/2017-06-02                       created  
    2.       umed/2017-06-08                     modify the script   
                                               rename the script, formatting and some minor changes  
    3.  rusha/2021-06-30       show middlename of doctor  
    4.	krishna,9thjun'22		changed ProviderId to PerformerId and ProviderName to PerformerName
    */  
    BEGIN  
     IF (p_fromdate IS NOT NULL) OR (p_todate IS NOT NULL) OR (p_performername IS NOT NULL) OR (LEN(p_performername) > 0)  
     THEN  
        
          
       SELECT COALESCE(v_pivotcolumnnames || ',','')  
       || QUOTENAME(PerformerName) INTO v_pivotcolumnnames FROM (   
          SELECT DISTINCT E.Salutation||' '||E.FirstName||' '|| COALESCE(E.MiddleName,'')||' '||E.LastName AS PerformerName   
          FROM            EMP_Employee E   
          INNER JOIN     PAT_PatientVisits p   
          ON            p.PerformerId=E.EmployeeId  
          WHERE  p.VisitDate   
          BETWEEN COALESCE(p_fromdate,CURRENT_TIMESTAMP) AND COALESCE(p_todate,CURRENT_TIMESTAMP)+1  
          AND p.PerformerId like '%'|| COALESCE(p_performername,'') || '%'  
         )   AS dep;  
           
        --SELECT 'appointmentdate'+COALESCE(','+v_pivotcolumnnames,'') as ColumnName  
      
        OPEN ref1 FOR SELECT 'appointment date'||COALESCE(','||REPLACE(REPLACE(v_pivotcolumnnames,'"',''),'"',''),'') as ColumnName;
        RETURN NEXT ref1;  
      
       v_dynamicpivotquery := N'select "appointment date", ' || v_pivotcolumnnames || '  
         from (  
            select convert(date, a.visitdate) as "appointment date", e.salutation+'' ''+e.firstname+'' ''+coalesce(e.middlename,'''')  
            +'' ''+e.lastname as performername,   
             count(a.performerid) as totalappointment  
            from pat_patientvisits  a inner join emp_employee e   
            on  a.performerid=e.employeeid   
            where a.visitdate  
            between convert(timestamp,'''|| (COALESCE(p_fromdate,CURRENT_TIMESTAMP))::VARCHAR  || ''')   
            and convert(timestamp,'''||(COALESCE(p_todate,CURRENT_TIMESTAMP))::VARCHAR||''')+1     
            and performername like ''%'|| COALESCE(p_performername,'') || '%''   
            group by e.salutation+'' ''+e.firstname+'' ''+coalesce(e.middlename,'''')+'' ''+e.lastname, convert(date, a.visitdate)  
          ) a  
         pivot(sum(totalappointment) for performername in (' || v_pivotcolumnnames || ')) as pvt';  
      
      
       open ref1 for execute v_dynamicpivotquery;
        return next ref1;  
      
     end if;  
    end;
END;
$$ LANGUAGE plpgsql;