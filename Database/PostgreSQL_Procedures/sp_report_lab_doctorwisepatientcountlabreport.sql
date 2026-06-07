CREATE OR REPLACE FUNCTION sp_report_lab_doctorwisepatientcountlabreport(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL
)
RETURNS TABLE (
    "SN" VARCHAR,
    "Doctor" VARCHAR,
    "OP" VARCHAR,
    "IP" VARCHAR,
    "Emergency" VARCHAR
) AS $$
BEGIN
    /*  
    filename: "sp_report_lab_doctorwisepatientcountlabreport"  '2019-12-02','2019-12-02'  
    createdby/date: dinesh 1st jan 2020  
    description: to get the total count of test conducted   
    remarks:      
    change history  
    s.no.    updatedby/date                        remarks  
    1       dinesh					hams requirement(to identify the no of patient entered from op/ip/er)  
    2		krishna,9thjun'22		changed RequestedBy to PrescriberId
    */  
    BEGIN  
      IF (p_fromdate IS NOT NULL OR p_todate IS NOT NULL OR LEN(p_fromdate) > 0 OR LEN(p_todate) > 0)  
      THEN  
        
      
      
    RETURN QUERY SELECT (Cast(ROW_NUMBER() OVER (ORDER BY  FullName asc)  AS int)) AS "SN",FullName AS "Doctor",Sum(OP) AS "OP" ,Sum(IP) AS "IP",SUm(Emergency) AS "Emergency" from (  
    select  
      
    COALESCE(case   
    when (visit.VisitType in ('outpatient')) then count(distinct(bt.PatientId))  
    END ,0) AS "OP",  
    COALESCE(case   
    when (visit.VisitType in ('inpatient')) then count(distinct(bt.PatientId))  
    END ,0) AS "IP",  
    COALESCE(case   
    when (visit.VisitType in ('emergency')) then count(distinct(bt.PatientId))  
    END ,0) AS "Emergency"  
      
    ,bt.PrescriberId,em.FullName from BIL_TXN_BillingTransactionItems bt  
    join BIL_MST_ServiceDepartment sd   
    on bt.ServiceDepartmentId=sd.ServiceDepartmentId  
    join PAT_PatientVisits visit on visit.PatientVisitId=bt.PatientVisitId  
    join EMP_Employee em on em.EmployeeId=bt.PrescriberId  
    where (bt.CreatedOn)::date = p_fromdate and bt.PrescriberId is not null and sd.IntegrationName='lab'  
    group by bt.prescriberid,em.fullname,visit.visittype  
    ) vt group by vt.prescriberid,vt.fullname;  
      
      end if;  
    end;
END;
$$ LANGUAGE plpgsql;