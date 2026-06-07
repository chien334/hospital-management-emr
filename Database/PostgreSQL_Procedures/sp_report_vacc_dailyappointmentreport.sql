CREATE OR REPLACE FUNCTION sp_report_vacc_dailyappointmentreport(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_appointmenttype VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "VisitDateTime" TIMESTAMP,
    "VaccinationRegNo" TIMESTAMP,
    "PatientName" VARCHAR,
    "PatientCode" VARCHAR,
    "PhoneNumber" TIMESTAMP,
    "Age" VARCHAR,
    "Gender" VARCHAR,
    "DateOfBirth" TIMESTAMP,
    "MotherName" VARCHAR,
    "EthnicGroup" VARCHAR,
    "DistrictName" VARCHAR,
    "Address" VARCHAR,
    "AppointmentType" VARCHAR,
    "UserName" VARCHAR
) AS $$
DECLARE
    v_vaccdepartmentname VARCHAR := (Select  ParameterValue from CORE_CFG_Parameters where ParameterName='immunizationdeptname' 
                                             and ParameterGroupName='Common' LIMIT 1);
    v_deptid INT := (Select  DepartmentId from MST_Department where DepartmentName=v_vaccdepartmentname LIMIT 1);
    v_appttype VARCHAR;
BEGIN
    /*
    filename: "sp_report_vacc_dailyappointmentreport"
    createdby/date: sud/2021-10-02
    description: to get appointemnt details of vaccination patients. 
    remarks: we're considering only patients who has VaccinationRegNumber (i.e: Patients registered from Vaccination module)  
    Change History
    S.No.    UpdatedBy/Date                        Remarks
    5		Sud/2021-10-02					      Initial Draft
    */
    BEGIN
    
    --DepartmentName for Immunization should be taken from Parameter table (since it could be different for diff hospitals).
      
      
    
      
      v_appttype := p_appointmenttype;
      if(COALESCE(p_appointmenttype,'all')='all')
      THEN
        v_appttype := '';  --change to empty input is 'null' or 'all' --- for string comparison..
      END IF;
    
      RETURN QUERY SELECT
    	   CAST((vis.VisitDate)::Date as TIMESTAMP) + CAST(vis.VisitTime AS TIMESTAMP) AS "VisitDateTime",
    	    pat.VaccinationRegNo,
    		pat.ShortName AS "PatientName",
    		pat.PatientCode,
            pat.PhoneNumber, 
    		pat.Age, 
    		pat.Gender,
    		pat.DateOfBirth,
    		pat.MotherName,
    		pat.EthnicGroup,
    		dist.CountrySubDivisionName AS "DistrictName",
    		pat.Address,
    		vis.AppointmentType,
    		emp.FullName AS "UserName"
    
        FROM PAT_Patient pat  INNER JOIN PAT_PatientVisits AS vis ON vis.PatientId = pat.PatientId
       
    	INNER JOIN MST_CountrySubDivision dist on pat.CountrySubDivisionId=dist.CountrySubDivisionId
    	INNER join MST_Department dept on vis.DepartmentId=dept.DepartmentId
    	INNER join EMP_Employee emp on emp.EmployeeId = vis.CreatedBy
    	WHERE 
    		vis.DepartmentId = v_deptid --taking only appointments of Immunzation Department
    		and pat.IsVaccinationPatient = 1 -- take only vaccination patients
    		and (vis.VisitDate)::date BETWEEN p_fromdate  AND  p_todate 
    		and vis.VisitType !='inpatient' --excluding inpatient visits (those can be seen from admission reports)
    		AND  vis.AppointmentType LIKE '%' || COALESCE(v_appttype, '') || '%'
    		AND vis.BillingStatus NOT  IN('cancel','returned')--exclude cancelled and returned visits.
    	order by cast((vis.visitdate)::date as timestamp) + cast(vis.visittime as timestamp) desc;
      
    end;
END;
$$ LANGUAGE plpgsql;