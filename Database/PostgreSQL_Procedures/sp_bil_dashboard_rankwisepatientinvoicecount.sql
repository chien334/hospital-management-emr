CREATE OR REPLACE FUNCTION sp_bil_dashboard_rankwisepatientinvoicecount(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL
)
RETURNS TABLE (
    "Rank" VARCHAR,
    "Total" DECIMAL
) AS $$
BEGIN
    
    	RETURN QUERY SELECT 
    		rank,
    		count(billingtransactionid) AS "Total"
    	from pat_patient pat
    	inner join bil_txn_billingtransaction txn
    	on txn.patientid = pat.patientid
    	inner join pat_patientvisits visit
    	on visit.patientvisitid = txn.patientvisitid
    	where rank is not null and rank != ''
    	and (txn.createdon)::date between p_fromdate and p_todate
    	group by rank;
END;
$$ LANGUAGE plpgsql;