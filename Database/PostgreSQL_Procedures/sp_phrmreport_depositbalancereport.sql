CREATE OR REPLACE FUNCTION sp_phrmreport_depositbalancereport(

)
RETURNS TABLE (
    "SN" VARCHAR,
    "*" VARCHAR
) AS $$
BEGIN
    /*
    filename: "sp_phrmreport_depositbalancereport"
    createdby/date: kushal/2019-07-08
    description: to get the deposit balance of the patient in pharmacy
    change history
    s.no.    updatedby/date                        remarks
    1       kushal/2019-07-08	                   created the script
    */
    
    RETURN QUERY SELECT (cast(row_number() over (order by  s.patientcode)  as int)) AS "SN",*
    from(
    select  distinct d.patientid, d.patientcode, d.patientname, d.depositbalance 
    	from 
    	(select
    		dep.patientid,
    		pat.patientcode,
    		pat.firstname || ' ' || coalesce(pat.middlename || ' ', '') || pat.lastname as "patientname",
    		last_value( dep.depositbalance) over (partition by dep.patientid order by dep.patientid) as "depositbalance" 
    		--dep.depositbalance
    	from phrm_deposit as dep
    	join pat_patient pat on dep.patientid = pat.patientid
    		) d
    where d.depositbalance > 0)
    s;
END;
$$ LANGUAGE plpgsql;