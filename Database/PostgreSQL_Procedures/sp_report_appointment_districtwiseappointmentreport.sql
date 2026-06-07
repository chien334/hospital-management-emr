CREATE OR REPLACE FUNCTION sp_report_appointment_districtwiseappointmentreport(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_countrysubdivisionname VARCHAR DEFAULT NULL,
    p_gender VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "DistrictId" INT,
    "DistrictName" VARCHAR,
    "NewAppointment" VARCHAR,
    "Followup" VARCHAR,
    "Referral" VARCHAR,
    "TotalAppointments" DECIMAL
) AS $$
BEGIN
    /*
    filename: "sp_report_appointment_districtwiseappointmentreport"
    createdby/date: 
    description: to get district wise total appointments(new,followup,referral) on a given date range
    remarks:    
    change history
    s.no.    updatedby/date            remarks
    1      sud:21sep'21               Complete rewrite as per new requirement to show sum in the given date range
    */
    
    	RETURN QUERY SELECT CountrySubDivisionId AS "DistrictId", CountrySubDivisionName AS "DistrictName", 
    	COALESCE("New",0) AS "NewAppointment",
    	COALESCE("followup",0) AS "Followup",
    	COALESCE("Referral",0) AS "Referral",
    	COALESCE("New",0) + COALESCE("followup",0) + COALESCE("Referral",0)  AS "TotalAppointments"
    
    	from 
    	(
            SELECT
                "CountrySubDivisionId",
                "CountrySubDivisionName",
                COALESCE(SUM(CASE WHEN "appointmenttype" = 'new' THEN "appointmentcount" ELSE 0 END), 0) AS "New",
                COALESCE(SUM(CASE WHEN "appointmenttype" = 'followup' THEN "appointmentcount" ELSE 0 END), 0) AS "Followup",
                COALESCE(SUM(CASE WHEN "appointmenttype" = 'referral' THEN "appointmentcount" ELSE 0 END), 0) AS "Referral"
            FROM (
                
    	Select dist.CountrySubDivisionId, dist.CountrySubDivisionName,
    	vis.AppointmentType, Count(*) AS "AppointmentCount"
    	FROM PAT_PatientVisits VIS
    	INNER JOIN PAT_Patient pat
    		on vis.PatientId = pat.PatientId
    	INNER JOIN MST_CountrySubDivision dist ON pat.CountrySubDivisionId = dist.CountrySubDivisionId
    
    	WHERE (VIS.VisitDate)::Date BETWEEN p_fromdate AND p_todate AND 
    		 CountrySubDivisionName LIKE  '%'||COALESCE(p_countrysubdivisionname,'')||'%'
    
    	and vis.BillingStatus NOT IN('returned','cancel')
    	--exclude inpatient visits..
    	and vis.VisitType !='inpatient'
    
    	and COALESCE(NULLIF(p_gender,'all'),pat.gender)=pat.gender
    	
    	group by dist.countrysubdivisionid, dist.countrysubdivisionname, vis.appointmenttype
    
    	
            ) tbl
            group by "countrysubdivisionid", "countrysubdivisionname"
        ) pvtdata
    
    	order by countrysubdivisionname;
END;
$$ LANGUAGE plpgsql;