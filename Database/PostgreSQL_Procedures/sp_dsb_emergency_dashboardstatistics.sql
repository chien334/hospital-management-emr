CREATE OR REPLACE FUNCTION sp_dsb_emergency_dashboardstatistics(

)
RETURNS TABLE (
    "TotalRegisteredPatients" DECIMAL
) AS $$
BEGIN
    /*
    =============================================================================================
    filename: "sp_dsb_emergency_dashboardstatistics"
    createdby/date: ramavtar/2019-03-03
    =============================================================================================
    */
    
    
    --table1
    	RETURN QUERY SELECT * from 
    		(select count(*) AS "TotalRegisteredPatients" from er_patient where (createdon)::date = (current_timestamp)::date) totalregistered,
    		(select count(*) as "totaltriagedpatients" from er_patient where (triagedon)::date = (current_timestamp)::date) totaltriaged,
    		(select count(*) as "mildpatients" from er_patient where (triagedon)::date = (current_timestamp)::date and triagecode = 'mild') mild,
    		(select count(*) as "moderatepatients" from er_patient where (triagedon)::date = (current_timestamp)::date and triagecode = 'moderate') moderate,
    		(select count(*) as "criticalpatients" from er_patient where (triagedon)::date = (current_timestamp)::date and triagecode = 'critical') critical,
    		(select count(*) as "totalfinalizedpatients" from er_patient where (finalizedon)::date = (current_timestamp)::date) totalfinalized,
    		(select count(*) as "lamapatients" from er_patient where (finalizedon)::date = (current_timestamp)::date and finalizedstatus='lama') lama,
    		(select count(*) as "admittedpatients" from er_patient where (finalizedon)::date = (current_timestamp)::date and finalizedstatus='admitted') admitted,
    		(select count(*) as "dischargedpatients" from er_patient where (finalizedon)::date = (current_timestamp)::date and finalizedstatus='discharged') discharged,
    		(select count(*) as "transferredpatients" from er_patient where (finalizedon)::date = (current_timestamp)::date and finalizedstatus='transferred') transferred,
    		(select count(*) as "deathpatients" from er_patient where (finalizedon)::date = (current_timestamp)::date and finalizedstatus='death') death;
END;
$$ LANGUAGE plpgsql;