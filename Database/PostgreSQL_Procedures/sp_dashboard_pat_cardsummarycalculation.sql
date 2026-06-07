CREATE OR REPLACE FUNCTION sp_dashboard_pat_cardsummarycalculation(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
    ref3 refcursor := 'cursor3';
    ref4 refcursor := 'cursor4';
    v_fromdayminusoneday DATE := DATEADD(DAY, - 1, p_fromdate);
    v_fromdayminustwoday DATE := DATEADD(DAY, - 2, p_fromdate);
    v_noofdaysingivenrange INT := DATEDIFF(DAY, p_fromdate, p_todate) + 1;
BEGIN
    /*
     sp_dashboard_pat_cardsummarycalculation '2022-1-05'
    filename: "sp_dashboard_pat_cardsummarycalculation"
    createdby/date: nirmala/rohit/2022-1-05
    description: .
    remarks:    a
    change history
    s.no.    updatedby/date                        remarks
    1      nirmala/rohit/2022-1-05                created the script
    */
    
    	
    	
    	
    
    	open ref1 for select 'TotalRegisteredPatient' as "label"
    		,count(parentvisitid) as "total"
    	from pat_patientvisits
    	where (visitdate)::date between p_fromdate
    			and p_todate
    	
    	union all
    	
    	select 'TodayRegisteredPatient' as "label"
    		,count(parentvisitid) as "total"
    	from pat_patientvisits
    	where (visitdate)::date = (p_fromdate)::date
    	
    	union all
    	
    	select 'YesterdayRegisteredPatient' as "label"
    		,count(parentvisitid) as "total"
    	from pat_patientvisits
    	where (visitdate)::date between (v_fromdayminusoneday)::date
    			and (v_fromdayminustwoday)::date
    	
    	union all
    	
    	select 'AverageRegisteredPatient' as "label"
    		,count(parentvisitid) / v_noofdaysingivenrange as "total"
    	from pat_patientvisits
    	where (visitdate)::date between p_fromdate
    			and p_todate;
        return next ref1;
    
    	open ref2 for select 'TotalDoctor' as "label"
    		,count(employeeid) as "total"
    	from emp_employee
    	where salutation = 'Dr'
    	
    	union all
    	
    	select 'TotalConsultant' as "label"
    		,count(employeeid) as "total"
    	from emp_employee
    	where salutation = 'Dr'
    		and coalesce(isappointmentapplicable, 0) = 1
    	
    	union all
    	
    	select 'Anaesthetists' as "label"
    		,count(emp.employeeid) as "total"
    	from emp_employee emp
    	inner join mst_department dep on emp.departmentid = dep.departmentid
    	where salutation = 'Dr'
    		and departmentname = 'Anesthesia'
    	
    	union all
    	
    	select 'Medical Officer' as "label"
    		,count(emp.employeeid) as "total"
    	from emp_employee emp
    	inner join mst_department dep on emp.departmentid = dep.departmentid
    	where salutation = 'Dr'
    		and departmentname = 'Medical Officer';
        return next ref2;
    
    	open ref3 for select 'TotalAppointments' as "label"
    		,count(appointmentid) as "total"
    	from pat_appointment
    	where (appointmentdate)::date between p_fromdate
    			and p_todate
    	
    	union all
    	
    	select 'TodayAppointments' as "label"
    		,count(appointmentid) as "total"
    	from pat_appointment
    	where (appointmentdate)::date between (v_fromdayminusoneday)::date
    			and (v_fromdayminustwoday)::date
    	
    	union all
    	
    	select 'AverageAppointment' as "label"
    		,count(appointmentid) / v_noofdaysingivenrange as "total"
    	from pat_appointment
    	where (appointmentdate)::date between p_fromdate
    			and p_todate
    	
    	union all
    	
    	select 'Medical Officer' as "label"
    		,count(app.appointmentid) as "total"
    	from pat_appointment app
    	inner join mst_department dep on app.departmentid = dep.departmentid
    	where departmentname = 'Medical Officer';
        return next ref3;
    
    	open ref4 for select 'TotalReAdmission' as "label"
    		,count(patientadmissionid) as "total"
    	from adt_patientadmission
    	where admissionstatus = 'admitted'
    		and (admissiondate)::date between p_fromdate
    			and p_todate
    	having count(patientid) > 1
    	
    	union all
    	
    	select 'TodayAdmission' as "label"
    		,count(patientadmissionid) as "total"
    	from adt_patientadmission
    	where admissionstatus = 'admitted'
    		and (admissiondate)::date = p_fromdate
    	
    	union all
    	
    	select 'YesterdayAdmission' as "label"
    		,count(patientadmissionid) as "total"
    	from adt_patientadmission
    	where admissionstatus = 'admitted'
    		and (
    			(admissiondate)::date between (v_fromdayminusoneday)::date
    				and (v_fromdayminustwoday)::date
    			)
    	
    	union all
    	
    	select 'AverageAdmission' as "label"
    		,count(patientadmissionid) / v_noofdaysingivenrange as "total"
    	from adt_patientadmission
    	where admissionstatus = 'admitted'
    		and (
    			(admissiondate)::date between (p_fromdate)::date
    				and (p_todate)::date
    			);
        return next ref4;
END;
$$ LANGUAGE plpgsql;