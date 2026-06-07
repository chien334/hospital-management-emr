CREATE OR REPLACE FUNCTION sp_report_policecasepatient(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL
)
RETURNS TABLE (
    "SN" VARCHAR,
    "ShortName" VARCHAR,
    "DischargedDate" TIMESTAMP,
    "AdmissionDate" TIMESTAMP,
    "IpNumber" VARCHAR,
    "HospitalNumber" VARCHAR,
    "PatientId" INT,
    "AdmissionStatus" TIMESTAMP
) AS $$
BEGIN
    /*
    filename: "sp_report_policecasepatient"
    createdby/date: anjana (2020-09-30) 
    description: to get the count of total police case patient between given date
    
    change history
    s.no.    updatedby/date                        remarks
    1.     anjana (2020-09-30)					initial draft
    2.     dev narayan (2021-09-29)             change police case codition check in sp form database column 'isPoliceCase' to 'AdmissionCase'
    */
    
    begin
    if(p_fromdate is not null or p_todate is not null)
    	then 
    			RETURN QUERY SELECT 
    			  (cast(row_number() over (order by  dischargedate desc)  as int)) AS "SN",
    			  	p.shortname,
    		      --(p.firstname+''+p.lastname) 'PatientName',
                  ((dischargedate)::date)::varchar AS "DischargedDate", 
                  ((admissiondate)::date)::varchar AS "AdmissionDate",
    			  v.visitcode AS "IpNumber",
    			  p.patientcode AS "HospitalNumber",
    			  a.patientid,
    			  a.admissionstatus
    		    from adt_patientadmission a join pat_patientvisits v
                    on a.patientvisitid = v.patientvisitid
                   join pat_patient p on p.patientid=v.patientid
    		    where a.admissioncase like '%Police_Case%' and (admissiondate)::date between p_fromdate and p_todate
    			order by ((admissiondate)::date)::varchar desc;
    	
    	end if;	
    end;
END;
$$ LANGUAGE plpgsql;