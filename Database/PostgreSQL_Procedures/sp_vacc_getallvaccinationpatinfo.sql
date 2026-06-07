CREATE OR REPLACE FUNCTION sp_vacc_getallvaccinationpatinfo(

)
RETURNS TABLE (
    "PatientId" INT,
    "PatientName" VARCHAR,
    "PatientCode" VARCHAR,
    "DateOfBirth" TIMESTAMP,
    "Gender" VARCHAR,
    "Address" VARCHAR,
    "MotherName" VARCHAR,
    "VaccinationRegNo" TIMESTAMP,
    "DepartmentName" VARCHAR,
    "PatientVisitId" INT,
    "VisitDate" TIMESTAMP,
    "VisitTime" TIMESTAMP,
    "VisitDateTime" TIMESTAMP,
    "EthnicGroup" VARCHAR,
    "FatherName" VARCHAR,
    "UserName" VARCHAR,
    "VaccinationFiscalYearId" INT,
    "CountrySubDivisionId" INT,
    "CountryId" INT
) AS $$
DECLARE
    v_vaccdepartmentname VARCHAR := (Select  ParameterValue from CORE_CFG_Parameters where ParameterName='immunizationdeptname' 
                                             and ParameterGroupName='Common' LIMIT 1);
    v_deptid INT := (Select  DepartmentId from MST_Department where DepartmentName=v_vaccdepartmentname LIMIT 1);
BEGIN
    /*
     filename: "sp_vacc_getallvaccinationpatinfo" 
     created: 2-oct'21/Sud 
     Description: To Get Only the vaccination patients with VisitInformation
     Remarks: 
     Change History
     S.No.    Date/User                       Remarks
     1.       2-Oct'21/sud                    inital draft
               
    */
    
    
    
    
    
    
    RETURN QUERY SELECT pat.patientid, 
          pat.shortname AS "PatientName",
    	  pat.patientcode,
    	  pat.dateofbirth,
    	  pat.gender,
    	  pat.address,
    	  pat.mothername,
    	  pat.vaccinationregno,
    	  '' AS "DepartmentName",
    	  vaccvisits.patientvisitid,
    	  vaccvisits.visitdate,
    	  vaccvisits.visittime,
    	  cast((vaccvisits.visitdate)::date as timestamp) + cast(vaccvisits.visittime as timestamp) AS "VisitDateTime",
    	  pat.ethnicgroup,
    	  pat.fathername,
    	  vaccvisits.username,
    	  pat.vaccinationfiscalyearid,
    	  pat.countrysubdivisionid,
    	  pat.countryid
    
    from pat_patient pat
      left join 
      (
         --gets only visit of immunization department for each patient---
        select patientid, patientvisitid, visitcode, visitdate, visittime, row_num, username
          from 
          (
          select 
             row_number() over (
    			partition by patientid
    			order by patientvisitid desc
             ) as "row_num",
             patientid, patientvisitid,visitcode, visitdate, visittime, emp.fullname AS "UserName"
    
          from 
             pat_patientvisits vis inner join emp_employee emp
    		      on vis.createdby = emp.employeeid
    		 where vis.departmentid=v_deptid --this value comes from parameter+department table .
          ) a
    	where row_num=1 --gets only the latest visit of each patient
    
      ) vaccvisits
      on pat.patientid = vaccvisits.patientid
    
    
    
      where isvaccinationpatient=1 and vaccvisits.patientvisitid is not null
      order by visitdatetime desc;
END;
$$ LANGUAGE plpgsql;