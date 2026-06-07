CREATE OR REPLACE FUNCTION sp_dashboard_pat_visitbymembership(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL
)
RETURNS TABLE (
    "Count" INT,
    "MembershipTypeName" VARCHAR
) AS $$
BEGIN
    /*
     sp_dashboard_pat_visitbymembership '2022-1-05'
    filename: "sp_dashboard_pat_visitbymembership"
    createdby/date:nirmala/2022-1-05
    description: .
    remarks:    a
    change history
    s.no.    updatedby/date                        remarks
    1       nirmala/2022-1-05                created the script
    */
    
    	RETURN QUERY SELECT count(visit.patientid) AS "Count"
    		,type.membershiptypename
    	from pat_patient pat
    	inner join pat_patientvisits visit on pat.patientid = visit.patientid
    	inner join pat_cfg_membershiptype type on pat.membershiptypeid = type.membershiptypeid
    	where (visit.visitdate)::date between (p_fromdate)::date
    			and (p_todate)::date
    	group by type.membershiptypename;
END;
$$ LANGUAGE plpgsql;