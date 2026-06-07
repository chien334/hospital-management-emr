CREATE OR REPLACE FUNCTION sp_dsb_home_dashboardstatistics(

)
RETURNS TABLE (
    "TotalPatient" DECIMAL
) AS $$
BEGIN
    /*
    filename: "sp_dsb_home_dashboardstatistisc"
    createdby/date: sudarshan/2017-07-09
    description: to get dashboard statistics of the home dashboards. these are used to fill labels.
    remarks:  
    note:  
    change history
    s.no.    updatedby/date                        remarks
    1       sudarshan/2017-07-09	               created
    2       sudarshan/2017-07-14	               update
    3.      sudarshan/2017-08-16                   update: added types inside appointmentcount.
    4.      sud/17jan'19                           removed returned count from TOtal, Added Transfer count to New 
    5.      Sud/4Feb'19                            segregation of doctors count for consultant, mo, anaesthetists <need revision for totaldoctors count>
    */
    
    	--rules:-- 
    	/*
    	 1. search criteria is only 'today's outpatient visits': VisitType='outpatient'  AND CONVERT(DATE,VisitDate)=CONVERT(DATE,CURRENT_TIMESTAMP)
    	 2. Total: today's all opd counts
    	 3. new: appointmenttype='new'  or appointmenttype='Transfer'
    	 4. referral: appointmenttype='referral'
    	 5. followup = appointmenttype='followup' 
    	 6.cancelled: (appointmenttype='new' and billingstatus='cancel')   (other than 'new') can't be cancelled since they're not seen in billing.
    	 7.returned : (appointmenttype='new' and billingstatus='return') similar as canceled 
    	*/
      RETURN QUERY SELECT * from 
        ( select count(*) AS "TotalPatient" from pat_patient ) pat,
    	( select count(*) as "todaypatient" from pat_patient where cast(createdon as date) = cast(current_timestamp as date) ) today_pat,
    	( select count(*) as "yestardaypatient" from pat_patient where cast(createdon as date) = dateadd(day,-1, cast(current_timestamp as date) )) yestarday_pat,
    
    
    	( 
    	    --  select count(*) 'TotalDoctors' from emp_employee e,
    		--mst_department d where e.departmentid=d.departmentid
    		--and d.isappointmentapplicable=1
    
    		--we're adding EmployeeRoles ('doctor','m.o.','anaesthetist'  in TotalDoctorsCount -- needs revision. sud:4Feb'19
    
    		select  sum(case when erole.employeerolename='Doctor' then 1 else 0 end ) as "consultantscount",
    		  sum(case when erole.employeerolename='M.O.' then 1 else 0 end ) as "medicalofficerscount",
              sum(case when erole.employeerolename='Anaesthetist' then 1 else 0 end ) as "anaesthetistscount",
    		  sum(case when erole.employeerolename='Doctor' or erole.employeerolename='M.O.' or erole.employeerolename='Anaesthetist' then 1 else 0 end ) as "totaldoctorscount"
    		 from emp_employee emp
    		left join emp_employeerole erole
    		on emp.employeeroleid=erole.employeeroleid
    
    
    	 ) docs,
        (select 
    		sum(1) as "totalappts",
    		sum( case when (appointmenttype='new' or appointmenttype='Transfer') then 1 else 0 end ) as "newappts",
    		sum( case when appointmenttype='referral' then 1 else 0 end ) as "referralappts",
    		sum( case when appointmenttype='followup' then 1 else 0 end ) as "followupappts",
    		sum( case when appointmenttype='new' and billingstatus='cancel' then 1 else 0 end ) as "cancelappts"
    		--sum( case when appointmenttype='new' and billingstatus='returned' then 1 else 0 end ) as "returnappts"--sud:17jan'19--removed returned from this query, added in separate query below.
    		from PAT_PatientVisits where VisitType='outpatient' AND (VisitDate)::DATE=(CURRENT_TIMESTAMP)::DATE
    		and BillingStatus !='returned' -- exclude returned visits..
    	) appt,
    
    	 (Select 
    		Count(*) AS "ReturnAppts"
    		FROM PAT_PatientVisits 
    		where VisitType='outpatient' AND (VisitDate)::DATE=(CURRENT_TIMESTAMP)::DATE
    		and BillingStatus='returned'
    	) retappts;
END;
$$ LANGUAGE plpgsql;