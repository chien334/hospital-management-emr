CREATE OR REPLACE FUNCTION sp_report_appointment_dailyappointmentreport(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_doctor_name VARCHAR DEFAULT NULL,
    p_appointmenttype VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "Date" TIMESTAMP,
    "PatientCode" VARCHAR,
    "Patient_Name" VARCHAR,
    "PhoneNumber" TIMESTAMP,
    "Age" VARCHAR,
    "Gender" VARCHAR,
    "Ins_HasInsurance" VARCHAR,
    "DistrictName" VARCHAR,
    "DepartmentName" VARCHAR,
    "AppointmentType" VARCHAR,
    "VisitType" VARCHAR,
    "Doctor_Name" VARCHAR,
    "PerformerId" INT,
    "VisitStatus" VARCHAR
) AS $$
BEGIN
    /*  
    filename: "sp_report_appointment_dailyappointmentreport"  
    createdby/date: umed/2017-06-08  
    description: to get details such as patient name , appointment type, appointment status, along with doctor name between the given dates  
    remarks:      
    change history  
    s.no.    updatedby/date                        remarks  
    5  rusha/2019-18-06     updated of script according to provider name and appointment type  
    6       shankar/2020-19-02                  added middle name to the patients name  
    7.      sud/14jun'20                        PatientName taking from ShortName field of Pat_Patient Table  
    8.      Sud:21Sep'21                        adding departmentname, districtname in select result.  
                                                refactoring of where clause   
      
    9.      prem:26 april'22          Adding Ins_HasInsurance in Select Result. 
    10.		Krishna,3rdJun'22		  changed providerid to performerid
                                                  
    */  
      
        RETURN QUERY SELECT  
     ((vis.visitdate)::date)::timestamp + (visittime)::timestamp AS "Date",  
      pat.patientcode,  
      pat.shortname AS "Patient_Name",  
            pat.phonenumber,pat.age,  
      pat.gender,  
      pat.ins_hasinsurance,  
      dist.countrysubdivisionname AS "DistrictName",  
      coalesce(dept.departmentname,'Not Assigned') AS "DepartmentName",  
      vis.appointmenttype,vis.visittype,  
      emp.fullname AS "Doctor_Name",vis.performerid,  
      vis.visitstatus  
    from pat_patientvisits as vis  
     inner join pat_patient pat on vis.patientid = pat.patientid  
     inner join mst_countrysubdivision dist on pat.countrysubdivisionid=dist.countrysubdivisionid  
     left join mst_department dept on vis.departmentid=dept.departmentid  
     left join emp_employee emp on emp.employeeid=vis.performerid  
     where (vis.visitdate)::date between p_fromdate  and  p_todate   
     and vis.visittype !='inpatient' --excluding inpatient visits (those can be seen from admission reports)  
     and coalesce(emp.fullname,'') like '%' || coalesce(p_doctor_name, '') || '%' and  
       vis.appointmenttype like '%' || coalesce(p_appointmenttype, '') || '%'  
        and vis.billingstatus not  in('cancel','returned')--exclude cancelled and returned visits.  
     order by ((vis.visitdate)::date)::timestamp + (vis.visittime)::timestamp desc;
END;
$$ LANGUAGE plpgsql;