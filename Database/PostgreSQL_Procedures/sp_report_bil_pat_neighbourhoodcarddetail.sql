CREATE OR REPLACE FUNCTION sp_report_bil_pat_neighbourhoodcarddetail(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL
)
RETURNS TABLE (
    "IssuedDate" TIMESTAMP,
    "PatientId" INT,
    "HospitalNo" VARCHAR,
    "PatientName" VARCHAR,
    "Gender" VARCHAR,
    "DateOfBirth" TIMESTAMP,
    "PrescriberName" VARCHAR
) AS $$
BEGIN
    /*  
    filename: "sp_report_bil_pat_neighbourhoodcarddetail"  
    createdby/date: rusha/05-31-2019  
    description: to get the details of breakage items from different ward   
    remarks:      
    change history  
    s.no.    updatedby/date                        remarks  
    1.  rusha/05-31-2019        get details of patient for neighbourhood card report 
    2.	krishna/9thjun'22		changed RequestedBy to PrescriberName
    */  
      
    BEGIN  
      IF ((p_fromdate IS NOT NULL) and (p_todate IS NOT NULL))  
      THEN  
       RETURN QUERY SELECT (ncd.CreatedOn)::date AS "IssuedDate",ncd.PatientId, ncd.PatientCode AS "HospitalNo",   
       CONCAT_WS(' ',pat.FirstName, pat.MiddleName,pat.LastName) AS "PatientName",  
       pat.Gender, pat.DateOfBirth,CONCAT_WS(' ',emp.firstname,emp.middlename,emp.lastname) AS "PrescriberName"  
       from pat_neighbourhoodcarddetail as ncd  
       join pat_patient as pat on pat.patientid = ncd.patientid  
       join emp_employee as emp on emp.employeeid = ncd.createdby  
       where (ncd.createdon)::date between coalesce(p_fromdate,current_timestamp)  and coalesce(p_todate,current_timestamp)+1;  
      end if;   
    end;
END;
$$ LANGUAGE plpgsql;