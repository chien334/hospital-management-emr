CREATE OR REPLACE FUNCTION sp_report_appointment_departmentwiseappointmentreport(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_departmentid INT DEFAULT NULL,
    p_gender VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "DepartmentId" INT,
    "DepartmentName" VARCHAR,
    "NewAppointment" VARCHAR,
    "Followup" VARCHAR,
    "Referral" VARCHAR,
    "TotalAppointments" DECIMAL
) AS $$
BEGIN
    /*
    filename: "sp_report_appointment_departmentwiseappointmentreport"
    createdby/date: 
    description: to get departments total appointments(new,followup,referral) on a given date range
    remarks:    
    change history
    s.no.    updatedby/date            remarks
    1      sud:21sep'21               Complete rewrite as per new requirement to show sum in the given date range
    */
    
    
    RETURN QUERY SELECT DepartmentId, COALESCE(DepartmentName,'not assigned') AS "DepartmentName", 
    	COALESCE("New",0) AS "NewAppointment",
    	COALESCE("followup",0) AS "Followup",
    	COALESCE("Referral",0) AS "Referral",
    	COALESCE("New",0) + COALESCE("followup",0) + COALESCE("Referral",0)  AS "TotalAppointments"
    
    	from 
    	(
            SELECT
                "DepartmentId",
                "DepartmentName",
                COALESCE(SUM(CASE WHEN "appointmenttype" = 'new' THEN "appointmentcount" ELSE 0 END), 0) AS "New",
                COALESCE(SUM(CASE WHEN "appointmenttype" = 'followup' THEN "appointmentcount" ELSE 0 END), 0) AS "Followup",
                COALESCE(SUM(CASE WHEN "appointmenttype" = 'referral' THEN "appointmentcount" ELSE 0 END), 0) AS "Referral"
            FROM (
                
    	Select dept.DepartmentId, dept.DepartmentName, vis.AppointmentType, Count(*) AS "AppointmentCount"
    	FROM PAT_PatientVisits VIS
    	INNER JOIN PAT_Patient pat
    	  on vis.PatientId = pat.PatientId
    	LEFT JOIN MST_Department dept ON VIS.DepartmentId = DEPT.DepartmentId
    	
    	WHERE (VIS.VisitDate)::Date BETWEEN p_fromdate AND p_todate AND 
    	   --make deptid= null if it came as Zero---
    	   COALESCE(NULLIF(p_departmentid,0),vis.DepartmentId)=vis.DepartmentId
    
    	and vis.BillingStatus NOT IN('returned','cancel')
    	--exclude inpatient visits..
    	and vis.VisitType !='inpatient'
    
    	and COALESCE(NULLIF(p_gender,'all'),pat.gender)=pat.gender
    
    	group by dept.departmentid,vis.appointmenttype, dept.departmentname
    
    	
            ) tbl
            group by "departmentid", "departmentname"
        ) pvtdata
    
    	order by departmentname;
END;
$$ LANGUAGE plpgsql;