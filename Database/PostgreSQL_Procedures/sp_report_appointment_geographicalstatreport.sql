CREATE OR REPLACE FUNCTION sp_report_appointment_geographicalstatreport(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_countrysubdivisionname VARCHAR DEFAULT NULL,
    p_municipalityname VARCHAR DEFAULT NULL,
    p_geostattype VARCHAR DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
BEGIN
    /*
    filename:  exec "sp_report_appointment_geographicalstatreport"
    createdby/date: 
    description: to get district/municipality wise total appointments(new,followup) on a given date range
    remarks:    
    change history
    s.no.    updatedby/date            remarks
    1      bibek:27sep'23               Initial script
    2.	   Bibek:10thJuly'23					count the number of visit according to each municipality
    */
    begin
        if p_geostattype = 'District'
        then
            open ref1 for select countrysubdivisionid as "districtid",
                countrysubdivisionname as "districtname",
                coalesce("new", 0) as "newappointment",
                coalesce("followup", 0) as "followup",
                coalesce("referral", 0) as "referral",
                coalesce("new", 0) + coalesce("followup", 0) as "totalappointments"
            from (
            select
                "countrysubdivisionid",
                "countrysubdivisionname",
                coalesce(sum(case when "appointmenttype" = 'New' then "appointmentcount" else 0 end), 0) as "new",
                coalesce(sum(case when "appointmenttype" = 'followup' then "appointmentcount" else 0 end), 0) as "followup",
                coalesce(sum(case when "appointmenttype" = 'Referral' then "appointmentcount" else 0 end), 0) as "referral"
            from (
                
                select dist.countrysubdivisionid,
                    dist.countrysubdivisionname,
                    vis.appointmenttype,
                    count(*) as "appointmentcount"
                from pat_patientvisits vis
                inner join pat_patient pat on vis.patientid = pat.patientid
                inner join mst_countrysubdivision dist on pat.countrysubdivisionid = dist.countrysubdivisionid
                where (vis.visitdate)::date between p_fromdate and p_todate
                    and countrysubdivisionname like '%' || coalesce(p_countrysubdivisionname, '') || '%'
                    and vis.billingstatus not in ('returned', 'cancel')
                    and vis.visittype != 'inpatient'
                group by dist.countrysubdivisionid,
                    dist.countrysubdivisionname,
                    vis.appointmenttype
                
            ) tbl
            group by "countrysubdivisionid", "countrysubdivisionname"
        ) pvtdata
            order by countrysubdivisionname;
        return next ref1;
        end if;
    
        if p_geostattype = 'Municipality'
        then
            open ref2 for select municipalityname,
                coalesce("new", 0) as "newappointment",
                coalesce("followup", 0) as "followup",
                coalesce("new", 0) + coalesce("followup", 0) as "totalappointments"
            from (
            select
                "municipalityname",
                coalesce(sum(case when "appointmenttype" = 'New' then "appointmentcount" else 0 end), 0) as "new",
                coalesce(sum(case when "appointmenttype" = 'followup' then "appointmentcount" else 0 end), 0) as "followup"
            from (
                
                select mun.municipalityname,
                    vis.appointmenttype,
                    count(*) as "appointmentcount"
                from pat_patientvisits vis
                inner join pat_patient pat on vis.patientid = pat.patientid
                inner join mst_municipality mun on pat.municipalityid = mun.municipalityid
                inner join mst_countrysubdivision dist on mun.countrysubdivisionid = dist.countrysubdivisionid
                where (vis.visitdate)::date between p_fromdate and p_todate
                    and countrysubdivisionname like '%' || coalesce(p_countrysubdivisionname, '') || '%'
    				and municipalityname like '%' || coalesce(p_municipalityname, '') || '%'
                    and vis.billingstatus not in ('returned', 'cancel')
                    and vis.visittype != 'inpatient'
                group by mun.municipalityname,
                    vis.appointmenttype
                
            ) tbl
            group by "municipalityname"
        ) pvtdata
            order by municipalityname;
        return next ref2;
        end if;
    end;
END;
$$ LANGUAGE plpgsql;