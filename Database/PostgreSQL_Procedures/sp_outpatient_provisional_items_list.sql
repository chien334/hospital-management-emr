CREATE OR REPLACE FUNCTION sp_outpatient_provisional_items_list(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL
)
RETURNS TABLE (
    "ShortName" VARCHAR,
    "Age" VARCHAR,
    "Gender" VARCHAR,
    "DateOfBirth" TIMESTAMP,
    "PatientCode" VARCHAR,
    "IntegrationName" TIMESTAMP,
    "item.*" VARCHAR
) AS $$
BEGIN
    
    	RETURN QUERY SELECT pat.shortname,pat.age,pat.gender,pat.dateofbirth,pat.patientcode,srv.integrationname,
    	--dep.receiptno,
    	item.* from bil_txn_billingtransactionitems item
    	join pat_patient pat on pat.patientid=item.patientid
    	inner join bil_mst_servicedepartment srv on srv.servicedepartmentid=item.servicedepartmentid
    	 --join bil_txn_deposit dep on pat.patientid=dep.patientid
    	where (lower(item.visittype)='outpatient') and lower(billstatus)='provisional' and (item.createdon)::date between coalesce(p_fromdate, (current_timestamp)::date) and coalesce(p_todate, (current_timestamp)::date)
    	order by item.createdon desc;
END;
$$ LANGUAGE plpgsql;