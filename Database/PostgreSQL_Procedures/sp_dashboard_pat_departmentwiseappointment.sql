CREATE OR REPLACE FUNCTION sp_dashboard_pat_departmentwiseappointment(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL
)
RETURNS TABLE (
    "DepartmentName" VARCHAR,
    "AppointmentCount" INT
) AS $$
BEGIN
    /*
     sp_dashboard_pat_departmentwiseappointment '2022-1-05'
    filename: "sp_dashboard_pat_departmentwiseappointment"
    createdby/date:nirmala/2022-1-05
    description: .
    remarks:    a
    change history
    s.no.    updatedby/date                        remarks
    1       nirmala/2022-1-05                created the script
    */
    
    	RETURN QUERY SELECT dep.departmentname
    		,count(app.appointmentid) AS "AppointmentCount"
    	from pat_patientvisits visit
    	join pat_patient pat on pat.patientid = visit.patientid
    	inner join mst_department dep on dep.departmentid = visit.departmentid
    	left join pat_appointment app on app.appointmentid = app.appointmentid
    	where (app.appointmentdate)::date between (p_fromdate)::date
    			and (p_todate)::date
    	group by dep.departmentname;
END;
$$ LANGUAGE plpgsql;