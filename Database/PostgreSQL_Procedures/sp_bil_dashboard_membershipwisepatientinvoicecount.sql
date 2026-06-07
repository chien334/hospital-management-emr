CREATE OR REPLACE FUNCTION sp_bil_dashboard_membershipwisepatientinvoicecount(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL
)
RETURNS TABLE (
    "MembershipTypeName" VARCHAR,
    "Total" DECIMAL
) AS $$
BEGIN
    
    	RETURN QUERY SELECT 
    		memb.membershiptypename,
    		count(billingtransactionid) AS "Total"
    	from pat_patient pat
    	inner join bil_txn_billingtransaction txn
    	on txn.patientid = pat.patientid
    	inner join pat_patientvisits visit
    	on visit.patientvisitid = txn.patientvisitid
    	inner join pat_cfg_membershiptype memb
    	on memb.membershiptypeid = pat.membershiptypeid
    	where (txn.createdon)::date between p_fromdate and p_todate
    	group by memb.membershiptypename;
END;
$$ LANGUAGE plpgsql;