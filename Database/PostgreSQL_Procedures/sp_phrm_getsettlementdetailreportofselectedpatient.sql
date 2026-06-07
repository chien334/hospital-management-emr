CREATE OR REPLACE FUNCTION sp_phrm_getsettlementdetailreportofselectedpatient(
    p_fromdate DATE,
    p_todate DATE,
    p_patientid INT DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
    ref3 refcursor := 'cursor3';
    ref4 refcursor := 'cursor4';
BEGIN
    /*
     filename: "sp_phrm_getsettlementdetailreportofselectedpatient" '2021-12-01', '2021-12-07', 31445
     created: 6dec'21/Rohit
     Description: To get all the settlement details of a patient.
     Remarks: We need to use this procedure to get all the settlement details of the patient.
     Change History
     S.No.    Date/User              Change          Remarks
     1.	     6Dec'21/rohit		                   created sp
    */
    
    
        --table 1: patient information--
        open ref1 for select
            patientid,
            shortname as "patientname",
            patientcode,
            gender,
            dateofbirth
        from
            pat_patient
        where
    	patientid = p_patientid;
        return next ref1;
    
        --table 2: collection from receivable--
        open ref2 for select
            sett.patientid,
            (sett.settlementdate)::date as "settlementdate",
            sett.settlementreceiptno,
            mststore.name as crdtsettledstorename,
            s.name as crdtstorename,
            txn.invoiceid,
            txn.invoiceprintid,
            (txn.createon)::date as "invoicedate",
            coalesce(txn.totalamount, 0) as "salesamount",
            coalesce(ret.rettotalamount, 0) as "returntotalamount",
            coalesce(txn.totalamount, 0) - coalesce(ret.rettotalamount, 0) as "receivable",
            coalesce(sett.discountamount, 0) as "cashdiscount"
        from
            phrm_txn_settlement sett
            inner join pat_patient pat on sett.patientid = pat.patientid
            inner join phrm_mst_store mststore on sett.storeid= mststore.storeid
            left join phrm_txn_invoice txn on sett.settlementid = txn.settlementid
            left join phrm_mst_store s on txn.storeid=s.storeid
            left join (
    	select
                settlementid,
                invoiceid,
                sum(coalesce(totalamount, 0)) as "rettotalamount"
            from
                phrm_txn_invoicereturn
            where
    	settlementid is not null
            group by
    	settlementid,
    	invoiceid
    	            ) ret on sett.settlementid = ret.settlementid
                and txn.invoiceid = ret.invoiceid
        where
    	(sett.createdon)::date between p_fromdate and p_todate
            and sett.patientid = p_patientid
            and coalesce(sett.collectionfromreceivable, 0) !=0;
        return next ref2;
        -- need only settlement
    
    
        --table 3: return to receivable--
        open ref3 for select
            sett.settlementreceiptno,
            (sett.createdon)::date as "settlementdate",
            ret.creditnoteid,
            (ret.createdon)::date as "returndate",
            coalesce(ret.totalamount, 0) as "returntotalamount",
            ret.referenceinvoiceno,
            ret.invoiceid,
            coalesce(sett.discountreturnamount,0) as "discountreturnamount"
        from
            phrm_txn_settlement sett
            inner join phrm_txn_invoicereturn ret on sett.settlementid = ret.settlementid
            --inner join phrm_txn_invoice inv on ret.settlementid = inv.settlementid
            --  and ret.invoiceid = inv.invoiceid
        where
    	(sett.createdon)::date between p_fromdate
    	and p_todate
            and sett.patientid = p_patientid and sett.collectionfromreceivable is null and sett.refundableamount is null;
        return next ref3;
           -- and lower(inv.bilstatus) = 'paid'
        -- need only returns done after settlement
    
        --table 4: get cash discount--
        open ref4 for select
            sum(coalesce(discountamount, 0)) as "cashdiscount"
        from
            phrm_txn_settlement
        where
    	(createdon)::date between p_fromdate and p_todate
            and patientid = p_patientid
            and coalesce(collectionfromreceivable, 0) != 0;
        return next ref4;
END;
$$ LANGUAGE plpgsql;