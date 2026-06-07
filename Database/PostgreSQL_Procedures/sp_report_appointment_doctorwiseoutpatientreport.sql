CREATE OR REPLACE FUNCTION sp_report_appointment_doctorwiseoutpatientreport(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL
)
RETURNS TABLE (
    "DoctorName" VARCHAR,
    "NEW" VARCHAR,
    "FOLLOWUP" VARCHAR
) AS $$
BEGIN
    /*  
    change history  
    s.no.    updatedby/date          remarks  
    1    ramavtar/06aug'18      created the script  
    2.     Sud/31-Oct'21                excluding inpatient visits and returned/cancelled visits from this report.  
                                        correction in employeefullname field (for doctor name). 
    3.	krishna,3rdjun'22		changed ProviderId to PerformerId
    */  
      
    RETURN QUERY SELECT   
      e.FullName AS "DoctorName",  
        SUM(CASE WHEN vis.AppointmentType = 'new' THEN 1 ELSE 0 END) AS "NEW",  
        SUM(CASE WHEN vis.AppointmentType = 'followup' THEN 1 ELSE 0 END) AS "FOLLOWUP"  
    FROM PAT_PatientVisits vis  
    JOIN EMP_Employee E ON PerformerId = EmployeeId  
    WHERE (vis.VisitDate)::DATE BETWEEN p_fromdate AND p_todate  
        --excluding returned and cancelled visits  
      and vis.BillingStatus NOT IN('returned','cancel')  
      --exclude inpatient visits..  
      and vis.VisitType !='inpatient'  
    group by vis.performerid, e.fullname  
    order by vis.performerid;
END;
$$ LANGUAGE plpgsql;