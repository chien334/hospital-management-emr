/*
FileName: [sp_Report_TransferredPatient]
CreatedBy/date: Ramavtar/2018-06-06
Description: to get no of transferred patient's bed and its details
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Ramavtar/2018-06-06					changed the whole script .. for getting no of bedTransfer and its details(ward-wise count, total patient transfer and total transfer for single day)					
*/
CREATE OR REPLACE FUNCTION sp_report_transferredpatient(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL
)
RETURNS TABLE (
    "Date" TIMESTAMP,
    "TotalPatientTransfer" DECIMAL,
    "TotalNumberTransferred" DECIMAL,
    "OrthoSurgeryWardTransfer" VARCHAR,
    "MedicineGynoWardTransfer" VARCHAR,
    "OperationWardTransfer" TIMESTAMP,
    "OPWardTransfer" VARCHAR,
    "EmergencyWardTransfer" VARCHAR
) AS $$
BEGIN
    begin
    	if(p_fromdate is not null or p_todate is not null or len(p_fromdate)>0 or len(p_todate)>0)
    	then
    		RETURN QUERY SELECT
    			(startedon)::date AS "Date",
    			count(distinct (patientid)) AS "TotalPatientTransfer",
    			sum(1) AS "TotalNumberTransferred",
    			sum(case when wardid = 1 then 1 else 0 end) AS "OrthoSurgeryWardTransfer",
    			sum(case when wardid = 2 then 1 else 0 end) AS "MedicineGynoWardTransfer",
    			sum(case when wardid = 3 then 1 else 0 end) as "pre-operationwardtransfer",
    			sum(case when wardid = 4 then 1 else 0 end) as "icu&post-opwardtransfer",
    			sum(case when wardid = 5 then 1 else 0 end) AS "EmergencyWardTransfer"
    		from adt_txn_patientbedinfo
    		where action = 'transfer'
    		and (startedon)::date between p_fromdate and p_todate
    		group by (startedon)::date;
    	end if;	
    end;
END;
$$ LANGUAGE plpgsql;