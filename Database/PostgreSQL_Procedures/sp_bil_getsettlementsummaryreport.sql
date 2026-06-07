CREATE OR REPLACE FUNCTION sp_bil_getsettlementsummaryreport(
    p_fromdate DATE,
    p_todate DATE
)
RETURNS TABLE (
    "PatientId" INT,
    "PatientName" VARCHAR,
    "HospitalNo" VARCHAR,
    "Gender" VARCHAR,
    "ContactNo" TIMESTAMP,
    "DateOfBirth" TIMESTAMP,
    "CollnFromReceivable" VARCHAR,
    "CashDiscountGiven" INT,
    "CashDiscReturn" VARCHAR
) AS $$
BEGIN
    /*
    filename: "sp_bil_getsettlementsummaryreport"
    createdby/date: krishna/2021-11-22
    description: to get the credit settlement summary.
    change history
    s.no.    updatedby/date                        remarks
    1.		krishna/2021-11-22						created sp to get the credit settlement summary
    */
    
    
    RETURN QUERY SELECT 
    	sett.patientid, 
    	pat.shortname AS "PatientName", 
    	pat.patientcode AS "HospitalNo",
    	pat.gender,
    	pat.phonenumber AS "ContactNo",
    	pat.dateofbirth,
    	sum(coalesce(collectionfromreceivable,0)) AS "CollnFromReceivable",
    	sum(coalesce(discountamount,0)) AS "CashDiscountGiven",
    	sum(coalesce(discountreturnamount,0)) AS "CashDiscReturn"
    from bil_txn_settlements sett inner join pat_patient pat
    	on sett.patientid = pat.patientid
    where (sett.createdon)::date between p_fromdate and p_todate
    	group by sett.patientid,pat.shortname, pat.patientcode,
    			pat.gender,pat.phonenumber, pat.dateofbirth;
END;
$$ LANGUAGE plpgsql;