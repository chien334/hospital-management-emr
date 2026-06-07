CREATE OR REPLACE FUNCTION sp_report_bil_dialysispatientdetail(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL
)
RETURNS TABLE (
    "Date" TIMESTAMP,
    "DialysisCode" VARCHAR,
    "HospitalNo" VARCHAR,
    "PatientName" VARCHAR,
    "Gender" VARCHAR,
    "Age" VARCHAR,
    "PrescriberName" VARCHAR
) AS $$
BEGIN
    /*  
    filename: "sp_report_bil_pat_neighbourhoodcarddetail"  
    createdby/date: rusha/05-31-2019  
    description: t oget details report of dialysis patient  
    remarks:      
    change history  
    s.no.    updatedby/date                        remarks  
    1.  rusha/06-03-2019        get details report of dialysis patient 
    2.	krishna/8thjun'22		RequestedBy changed to PrescriberName
    */  
      
    BEGIN  
      IF ((p_fromdate IS NOT NULL) and (p_todate IS NOT NULL))  
      THEN  
       RETURN QUERY SELECT (pat.CreatedOn)::date AS "Date",pat.DialysisCode, pat.PatientCode AS "HospitalNo",   
       CONCAT_WS(' ',pat.FirstName, pat.MiddleName,pat.LastName) AS "PatientName",  
       pat.age|| '/' || substring(pat.Gender, 1, 1) AS "Gender", pat.Age, CONCAT_WS(' ',emp.firstname,emp.middlename,emp.lastname) AS "PrescriberName"  
       from pat_patient as pat   
       join emp_employee as emp on emp.employeeid = pat.createdby    
       where pat.dialysiscode is not null and (pat.createdon)::date between coalesce(p_fromdate,current_timestamp)  and coalesce(p_todate,current_timestamp)+1;  
      end if;   
    end;
END;
$$ LANGUAGE plpgsql;