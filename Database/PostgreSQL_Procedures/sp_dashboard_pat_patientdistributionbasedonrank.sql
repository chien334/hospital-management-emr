CREATE OR REPLACE FUNCTION sp_dashboard_pat_patientdistributionbasedonrank(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_departmentid INT DEFAULT NULL
)
RETURNS TABLE (
    "Rank" VARCHAR,
    "Count" INT
) AS $$
BEGIN
    /*
     sp_dashboard_pat_patientdistributionbasedonrank '2022-1-05'
    filename: "sp_dashboard_pat_patientdistributionbasedonrank"
    createdby/date:nirmala/2022-1-09
    description: .
    remarks:    a
    change history
    s.no.    updatedby/date                        remarks
    1       nirmala/2022-1-05               created the script
    2.		nirmal/2023-01-09				rescripted the query
    */
    
    RETURN QUERY SELECT pat.rank
    	,count(pat.patientid) AS "Count"
    from pat_patient pat
    inner join pat_patientvisits visit on visit.patientid = pat.patientid
    where (
    		visit.departmentid = p_departmentid
    		or p_departmentid is null
    		)
    	and pat.rank is not null and (visit.visitdate)::date between (p_fromdate)::date
        and (p_todate)::date
    group by pat.rank;
END;
$$ LANGUAGE plpgsql;