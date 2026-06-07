CREATE OR REPLACE FUNCTION sp_report_appointment_rankwisedailyappointmentreport(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_membership VARCHAR DEFAULT NULL,
    p_rank VARCHAR DEFAULT NULL,
    p_appointmenttype VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "Date" TIMESTAMP,
    "PatientCode" VARCHAR,
    "Rank" VARCHAR,
    "Membership" VARCHAR,
    "PatientName" VARCHAR,
    "Address" VARCHAR,
    "PhoneNumber" TIMESTAMP,
    "Age" VARCHAR,
    "Gender" VARCHAR,
    "DepartmentName" VARCHAR,
    "AppointmentType" VARCHAR,
    "VisitType" VARCHAR,
    "VisitStatus" VARCHAR
) AS $$
BEGIN
    /*  
    filename: "sp_report_appointment_rankwisedailyappointmentreport"
    example: exec "sp_report_appointment_rankwisedailyappointmentreport" '2022-11-01','2022-12-29','6,8','',''
    createdby/date: rusha/2023-01-09  
    description: rankwise daily appointment report  
    remarks:      
    change history  
    s.no.    updatedby/date                        remarks  
    1.        rusha/ 09thjan'23                    Initial draft
    */
    
        RETURN QUERY SELECT
        ((vis.VisitDate)::date)::TIMESTAMP + (VisitTime)::TIMESTAMP AS "Date",
        pat.PatientCode,
        COALESCE(pat.Rank, '') AS "Rank",
        mem.MembershipTypeName AS "Membership",
        pat.ShortName AS "PatientName",
        pat.Address,
        pat.PhoneNumber,
        pat.Age,
        pat.Gender,
        COALESCE(dept.DepartmentName, 'not assigned') AS "DepartmentName",
        vis.AppointmentType,
        vis.VisitType,
        vis.VisitStatus 
    FROM
      PAT_PatientVisits AS vis 
      INNER JOIN PAT_Patient pat ON vis.PatientId = pat.PatientId 
      INNER JOIN MST_CountrySubDivision dist on pat.CountrySubDivisionId = dist.CountrySubDivisionId 
      left join MST_Department dept on vis.DepartmentId = dept.DepartmentId 
      left join EMP_Employee emp on emp.EmployeeId = vis.PerformerId 
      INNER JOIN pat_cfg_membershiptype mem
             ON pat.membershiptypeid = mem.membershiptypeid
      INNER JOIN (SELECT value AS "MembershipTypeId"
                  FROM   String_split(p_membership, ',')) membership
             ON mem.membershiptypeid = membership.membershiptypeid
    WHERE
      (vis.VisitDate)::date BETWEEN p_fromdate AND p_todate
      and vis.VisitType != 'inpatient' --excluding inpatient visits (those can be seen from admission reports)  
      and vis.AppointmentType LIKE '%' || COALESCE(p_appointmenttype, '') || '%'
      AND(pat.Rank IN (select value AS "Ranks" from string_split(p_rank, ',')) OR p_rank = '')
      AND vis.BillingStatus NOT IN('cancel', 'returned') --exclude cancelled and returned visits.  
    order by
      ((vis.visitdate)::date)::timestamp + (vis.visittime)::timestamp desc;
END;
$$ LANGUAGE plpgsql;