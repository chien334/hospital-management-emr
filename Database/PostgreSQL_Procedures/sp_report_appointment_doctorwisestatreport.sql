CREATE OR REPLACE FUNCTION sp_report_appointment_doctorwisestatreport(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_employeeid INT DEFAULT NULL,
    p_gender VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "*" VARCHAR,
    "Total" DECIMAL
) AS $$
DECLARE
    v_minageindaysforchild INT := (SELECT MinAgeInDays FROM CORE_MST_AgeClassification WHERE AgeName = 'Child');
    v_maxageindaysforchild INT := (SELECT MaxAgeInDays FROM CORE_MST_AgeClassification WHERE AgeName = 'Child');
    v_minageindaysforadult INT := (SELECT MinAgeInDays FROM CORE_MST_AgeClassification WHERE AgeName = 'Adult');
    v_maxageindaysforadult INT := (SELECT MaxAgeInDays FROM CORE_MST_AgeClassification WHERE AgeName = 'Adult');
BEGIN
    /*
    exec sp_report_appointment_doctorwisestatreport '2023-09-19', '2023-09-19'
    filename: "sp_report_appointment_doctorwisestatreport"
    createdby/date: 
    description: to get doctorwise total stat (new,followup) on a given date range
    remarks:    
    change history
    s.no.    updatedby/date            remarks
    1     bibek:10sept'23               Initial Script
    2.    Bibek:19thSept'23              edited the sp to display proper name of doctor
    */
    
        
        
    
        
        
    
        RETURN QUERY SELECT *, "newmalechild" + "newfemalechild" + "newmaleadult" + "newfemaleadult" + "oldmalechild" + "oldfemalechild" + "oldmaleadult" + "oldfemaleadult" AS "Total"
        from (
            select
                "fullname",
                count(case when "agecategory" = 'NewMaleChild' then 1 end) as "newmalechild",
                count(case when "agecategory" = 'NewFemaleChild' then 1 end) as "newfemalechild",
                count(case when "agecategory" = 'NewMaleAdult' then 1 end) as "newmaleadult",
                count(case when "agecategory" = 'NewFemaleAdult' then 1 end) as "newfemaleadult",
                count(case when "agecategory" = 'OldMaleChild' then 1 end) as "oldmalechild",
                count(case when "agecategory" = 'OldFemaleChild' then 1 end) as "oldfemalechild",
                count(case when "agecategory" = 'OldMaleAdult' then 1 end) as "oldmaleadult",
                count(case when "agecategory" = 'OldFemaleAdult' then 1 end) as "oldfemaleadult"
            from (
                
            select
                fullname,
                case
                    when agedays >= v_minageindaysforchild and agedays <= v_maxageindaysforchild and gender = 'Male' and appointmenttype = 'New' then 'NewMaleChild'
                    when agedays >= v_minageindaysforchild and agedays <= v_maxageindaysforchild and gender = 'Female' and appointmenttype = 'New' then 'NewFemaleChild'
                    when agedays >= v_minageindaysforadult and agedays <= v_maxageindaysforadult and gender = 'Male' and appointmenttype = 'New' then 'NewMaleAdult'
                    when agedays >= v_minageindaysforadult and agedays <= v_maxageindaysforadult and gender = 'Female' and appointmenttype = 'New' then 'NewFemaleAdult'
                    when agedays >= v_minageindaysforchild and agedays <= v_maxageindaysforchild and gender = 'Male' and appointmenttype = 'Followup' then 'OldMaleChild'
                    when agedays >= v_minageindaysforchild and agedays <= v_maxageindaysforchild and gender = 'Female' and appointmenttype = 'Followup' then 'OldFemaleChild'
                    when agedays >= v_minageindaysforadult and agedays <= v_maxageindaysforadult and gender = 'Male' and appointmenttype = 'Followup' then 'OldMaleAdult'
                    when agedays >= v_minageindaysforadult and agedays <= v_maxageindaysforadult and gender = 'Female' and appointmenttype = 'Followup' then 'OldFemaleAdult'
                end as agecategory
            from (
                select
                    emp.fullname,
                    datediff(day, pat.dateofbirth, vis.visitdate) as agedays,
                    vis.appointmenttype,
                    pat.gender
                from
                    pat_patient pat
                    inner join pat_patientvisits vis on pat.patientid = vis.patientid 
                    inner join emp_employee emp on vis.performerid = emp.employeeid
                where
    				isappointmentapplicable=1
    				and vis.visittype != 'inpatient' 
                    and (vis.visitdate)::date between p_fromdate and p_todate 
                    and (pat.gender = p_gender or p_gender is null or p_gender = 'All' ) 
                    and (emp.employeeid = p_employeeid or p_employeeid is null)
    				and vis.appointmenttype in ('New','followup') 
    				and vis.billingstatus != 'returned'
            ) tbl
        
            ) src
            group by "fullname"
        ) piv;
END;
$$ LANGUAGE plpgsql;