CREATE OR REPLACE FUNCTION sp_phrm_getsettlementsummaryreport(
    p_fromdate DATE,
    p_todate DATE,
    p_storeid INT DEFAULT NULL
)
RETURNS TABLE (
    "PatientId" INT,
    "PatientName" VARCHAR,
    "PatientCode" VARCHAR,
    "Gender" VARCHAR,
    "ContactNo" TIMESTAMP,
    "DateOfBirth" TIMESTAMP,
    "LatestSettlementDate" TIMESTAMP,
    "CollnFromReceivable" VARCHAR,
    "CashDiscountGiven" INT,
    "CashDiscReturn" VARCHAR
) AS $$
BEGIN
    /*
     filename: "sp_phrm_getsettlementsummaryreport" 
     created: 6dec'21/Rohit
     Description: To get all the settlement report data.
     Remarks: We need to use this procedure to get all the settlement report data.
     Change History
     S.No.    Date/User              Change          Remarks
     1.	     6Dec'21/rohit		                   created sp
    */
    
        RETURN QUERY SELECT
            sett.patientid,
            pat.shortname AS "PatientName",
            pat.patientcode,
            pat.gender,
            pat.phonenumber AS "ContactNo",
            pat.dateofbirth,
            max(sett.createdon) AS "LatestSettlementDate",
            round(sum(coalesce(collectionfromreceivable, 0)),3) AS "CollnFromReceivable",
            round(sum(coalesce(discountamount, 0)),3) AS "CashDiscountGiven",
            round(sum(coalesce(discountreturnamount, 0)),3) AS "CashDiscReturn"
        from
            phrm_txn_settlement sett
            inner join pat_patient pat on sett.patientid = pat.patientid
        where 
    		(sett.createdon)::date between p_fromdate and p_todate
            and (sett.storeid = p_storeid or p_storeid is null)
    	group by
    		sett.patientid,
            pat.shortname,
            pat.patientcode,
            pat.gender,
            pat.phonenumber,
            pat.dateofbirth
    	order by max(sett.settlementdate) desc;
END;
$$ LANGUAGE plpgsql;