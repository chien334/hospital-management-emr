CREATE OR REPLACE FUNCTION sp_report_adt_dischargedpatient(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL
)
RETURNS TABLE (
    "SN" VARCHAR,
    "PatientName" VARCHAR,
    "DischargedDate" TIMESTAMP,
    "AdmissionDate" TIMESTAMP,
    "AdmittingDoctor" VARCHAR,
    "VisitId" INT,
    "IpNumber" VARCHAR,
    "HospitalNumber" VARCHAR,
    "PatientId" INT
) AS $$
BEGIN
    /*
    filename: "sp_report_adt_dischargedpatient"
    createdby/date: nagesh/sud (upto 2018-08-21) 
    description: to get the count of total discharged patient between given date
    remarks:    removed totaladmittedcount for now, add it later if needed.
    change history
    s.no.    updatedby/date                        remarks
    1.     nagesh/sud (upto 2018-08-21)             revised
    2.     sud/8aug'21                              Handled Admitting Doctor non-mandatory case.
    */
    
    BEGIN
    If(p_fromdate IS NOT NULL OR p_todate IS NOT NULL)
    	THEN 
    			RETURN QUERY SELECT 
    			  (Cast(ROW_NUMBER() OVER (ORDER BY  DischargeDate desc)  as int)) AS "SN",
    			  	P.FirstName||COALESCE(' '||P.MiddleName,'')||' '|| P.LastName AS "PatientName",
    		      --(P.Firstname+''+P.LastName) 'patientname',
                  ((DischargeDate)::date)::VARCHAR AS "DischargedDate", 
                  ((AdmissionDate)::date)::VARCHAR AS "AdmissionDate",
    			  COALESCE(E.Salutation||' ','')|| E.FirstName||COALESCE(' '||E.MiddleName,'')||' '|| E.LastName AS "AdmittingDoctor",
                  --(E.FirstName+' '+E.LastName) 'admittingdoctor',
                  A.PatientVisitId AS "VisitId",
    			  V.VisitCode AS "IpNumber",
    			  P.PatientCode AS "HospitalNumber",
    			  A.PatientId
    		    from ADT_PatientAdmission A join PAT_PatientVisits V
                    on A.PatientVisitId = V.PatientVisitId
                   left join EMP_EMPLOYEE E on A.AdmittingDoctorId= E.EmployeeId 
                   Join PAT_Patient P on P.PatientId=V.PatientId
    		    where A.AdmissionStatus='discharged' and (DischargeDate)::date between p_fromdate and p_todate
    			Order By ((DischargeDate)::date)::VARCHAR desc;
       --         union all
       --         select  NULL,NULL,NULL,'','total discharged count ',Count('patientvisitid'),null
       --         from ADT_PatientAdmission 
    			--where AdmissionStatus='discharged' and convert(date,dischargedate) between p_fromdate and p_todate
    	
    	end if;	
    end;
END;
$$ LANGUAGE plpgsql;