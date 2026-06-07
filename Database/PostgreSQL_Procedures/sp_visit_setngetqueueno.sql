CREATE OR REPLACE FUNCTION sp_visit_setngetqueueno(
    p_visitid INT
)
RETURNS TABLE (
    "QueueNo" VARCHAR
) AS $$
DECLARE
    v_queuelevel VARCHAR := (Select  ParameterValue from CORE_CFG_Parameters where ParameterGroupName='Appointment' and ParameterName='QueueLevel' LIMIT 1);
    v_doctorid INT;
    v_departmentid INT;
    v_visitdate DATE;
    v_latestqunum INT := 0;
BEGIN
    /*  
     file: sp_visit_setngetqueueno -- exec sp_visit_setngetqueueno 4  
     description:   
        * to set the queuenumber for current visit based on queuelevel parameter   
     * there are 3 available options: department, doctor, hospital (default)  
      
    change history:  
    s.no  author/date                remarks  
    1.    sud/pratik/5mar'20         Initial Draft  
    2.   Anish/Anjana/26Feb'21  handle case of registration of er patient before outpatient  
    3.    prem					queue for the emergency   
    4.	 krishna,9thjun			changed providerid to performerid
    */  
    begin  
       
    --read and set queuelevel value from parameter  
      
      
      
      
      
    --assign values of doctorid, departemntid, visitdate for current visit.  
    select performerid, departmentid, (visitdate)::date into v_doctorid, v_departmentid, v_visitdate from pat_patientvisits where patientvisitid=p_visitid;  
      
    --case1: if departmentlevel then take max that department for that day of visit  
    if(v_queuelevel='department')  
    then  
       select coalesce(max(coalesce(queueno,0)),0) into v_latestqunum from pat_patientvisits  
       where (visittype='outpatient' or visittype='emergency') and departmentid=v_departmentid   
         and (visitdate)::date= v_visitdate;   
      
    --case2: if doctorlevel then take max that doctor for that day of visit  
    elsif (v_queuelevel='doctor')  
    then  
       select coalesce(max(coalesce(queueno,0)),0) into v_latestqunum from pat_patientvisits  
       where (visittype='outpatient' or visittype='emergency') and performerid=v_doctorid   
         and (visitdate)::date= v_visitdate;   
      
    else--case3: by default it'll be hospital level, in this case take max of that day's visit  
      
       select coalesce(max(coalesce(queueno,0)),0) into v_latestqunum from pat_patientvisits  
       where (visittype='outpatient' or visittype='emergency') and (visitdate)::date= v_visitdate;   
    end if;  
      
    --update the queue numebr of given visit and return the same to the caller---  
    v_latestqunum := v_latestqunum+1;  
    update pat_patientvisits  
    set queueno=v_latestqunum  
    where patientvisitid=p_visitid;  
    RETURN QUERY SELECT v_latestqunum AS "QueueNo";  
      
    end;
END;
$$ LANGUAGE plpgsql;