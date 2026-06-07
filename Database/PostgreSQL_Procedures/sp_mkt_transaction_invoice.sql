CREATE OR REPLACE FUNCTION sp_mkt_transaction_invoice(
    p_fromdate DATE,
    p_todate DATE
)
RETURNS TABLE (
    "BillingTransactionId" INT,
    "CreatedOn" TIMESTAMP,
    "InvoiceNo" VARCHAR,
    "PatientCode" VARCHAR,
    "PatientVisitId" INT,
    "PatientId" INT,
    "ShortName" VARCHAR,
    "FiscalYearId" INT,
    "InvoiceNoFormatted" VARCHAR,
    "Age" VARCHAR,
    "Gender" VARCHAR,
    "TotalAmount" DECIMAL,
    "ReturnCashAmount" DECIMAL,
    "NetAmount" DECIMAL,
    "ReferralCount" INT
) AS $$
BEGIN
    /* 
    exec "sp_mkt_transaction_invoice" '2023-04-07','2023-08-08'
    change history
    s.no.    updatedby/date                        remarks
    1        bibek/2023-08-08                   created initial script 
    */
    
    RETURN QUERY SELECT 
    		 bt.billingtransactionid
    		,bt.createdon
    		,bt.invoiceno
    		,pat.patientcode
    		,pv.patientvisitid
    		,pat.patientid
    		,pat.shortname
    		,bt.fiscalyearid
    		, concat( fy.fiscalyearformatted, '-', bt.invoicecode,bt.invoiceno) AS "InvoiceNoFormatted"
    		,concat (pat.age,'/',pat.gender) AS "Age"
    		,pat.gender
    		,bt.totalamount
    		,coalesce(bt.rettotalamount,0) AS "ReturnCashAmount"
    		,coalesce(bt.totalamount,0) - coalesce(bt.rettotalamount,0) AS "NetAmount"
    		,count(rc.billingtransactionid) AS "ReferralCount"
    	    from (select txn.billingtransactionid, txn.createdon, invoiceno, txn.totalamount, ret.rettotalamount, txn.patientid, txn.patientvisitid, txn.fiscalyearid, txn.invoicecode from (
    				select * from bil_txn_billingtransaction where (createdon)::date between p_fromdate and p_todate) txn
    				left join (select billingtransactionid, sum(coalesce(totalamount,0)) as "rettotalamount" from bil_txn_invoicereturn
    				group by billingtransactionid) ret on txn.billingtransactionid = ret.billingtransactionid) bt
        left join (select * from mkt_txn_referralcommission where isactive = 1) rc on rc.billingtransactionid = bt.billingtransactionid
    	inner join pat_patient pat on bt.patientid = pat.patientid
    	inner join pat_patientvisits pv on bt.patientvisitid = pv.patientvisitid
    	inner join bil_cfg_fiscalyears fy on bt.fiscalyearid= fy.fiscalyearid
    	
    	group by bt.billingtransactionid
    		,bt.createdon
    		,bt.invoiceno
    		,pat.patientcode
    		,pv.patientvisitid
    		,pat.patientid
    		,pat.shortname
    		,pat.age
    		,pat.gender,
    		bt.fiscalyearid
    		,bt.totalamount
    		,bt.rettotalamount,
    		bt.invoicecode,
    		fy.fiscalyearformatted,
    		invoicenoformatted
    	order by bt.createdon desc;
END;
$$ LANGUAGE plpgsql;