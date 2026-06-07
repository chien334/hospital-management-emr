CREATE OR REPLACE FUNCTION sp_report_appointment_phonebookappointmentreport(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_doctor_name VARCHAR DEFAULT NULL,
    p_appointmentstatus VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "Date" TIMESTAMP,
    "PatientId" INT,
    "PatientCode" VARCHAR,
    "PatientName" VARCHAR,
    "Age" VARCHAR,
    "Address" VARCHAR,
    "Gender" VARCHAR,
    "ContactNumber" TIMESTAMP,
    "PerformerId" INT,
    "AppointmentStatus" VARCHAR,
    "PerformerName" VARCHAR,
    "AppointmentDate" TIMESTAMP
) AS $$
BEGIN
    /*  
    filename: "sp_report_appointment_phonebookappointmentreport"  
    createdby/date: rusha/10-24-2019  
    description: to get details from phone book such as patient name , appointment type, appointment status,   
        along with doctor name between the given dates  
    example: exec sp_report_appointment_phonebookappointmentreport '2023-02-01', '2023-02-09', null, null
    remarks:      
    change history  
    s.no.    updatedby/date                        remarks  
     1.		 krishna,3rdjun'22			changed ProviderId to PerformerId, ProviderName to PerformerName
     2.		 Krishna, 8thFeb'23		    sp refactored to get correct data
    */
    
    	RETURN QUERY SELECT ((apt.appointmentdate)::date)::timestamp + (apt.appointmenttime)::timestamp AS "Date"
    		,pat.patientid
    		,pat.patientcode
    		,concat_ws(' ', apt.firstname, apt.middlename, apt.lastname) AS "PatientName"
    		,pat.age
    		,pat.address
    		,apt.gender
    		,apt.contactnumber
    		,apt.performerid
    		,apt.appointmentstatus
    		,apt.performername
    		,apt.appointmentdate
    	from pat_appointment apt
    	left join pat_patient pat on apt.patientid = pat.patientid
    	left join pat_patientvisits visit on apt.appointmentid = visit.appointmentid
    	where (apt.appointmentdate)::date between (p_fromdate)::date
    			and (p_todate)::date
    		and coalesce(apt.performername, '') like '%' || coalesce(p_doctor_name, '') || '%'
    		and coalesce(apt.appointmentstatus, '') like '%' || coalesce(p_appointmentstatus, '') || '%'
    	order by ((apt.appointmentdate)::date)::timestamp + (apt.appointmenttime)::timestamp desc;
END;
$$ LANGUAGE plpgsql;