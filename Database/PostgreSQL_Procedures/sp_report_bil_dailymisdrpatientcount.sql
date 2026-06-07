CREATE OR REPLACE FUNCTION sp_report_bil_dailymisdrpatientcount(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL
)
RETURNS TABLE (
    "PerformerId" INT,
    "PerformerName" VARCHAR,
    "PatientCount" INT
) AS $$
BEGIN
    /*  
    filename: sp_report_bill_dailymisreport  
    change history  
    s.no.    updatedby/date  remarks  
    1       ramavtar/2018-08-30     created the script  
    2		krishna/2022-06-08		changed providerid to performerid and providername to performername
    */  
      
     RETURN QUERY SELECT  
      coalesce(performerid,0) AS "PerformerId",  
      coalesce(emp.firstname || ' ' || emp.lastname,'NoDoctor') AS "PerformerName",  
      count(distinct patientid) AS "PatientCount"   
     from "fn_bil_gettxnitemsinfowithdateseparation"(p_fromdate,p_todate) bil  
     left join emp_employee emp on bil.performerid = emp.employeeid  
     group by bil.performerid,emp.firstname,emp.lastname  
     order by 2;
END;
$$ LANGUAGE plpgsql;