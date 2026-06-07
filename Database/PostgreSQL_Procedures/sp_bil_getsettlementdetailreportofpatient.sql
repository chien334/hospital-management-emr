CREATE OR REPLACE FUNCTION sp_bil_getsettlementdetailreportofpatient(
    p_fromdate DATE,
    p_todate DATE,
    p_patientid INT DEFAULT 0
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
    ref3 refcursor := 'cursor3';
    ref4 refcursor := 'cursor4';
BEGIN
    /*
    filename: "sp_bil_getsettlementdetailreportofpatient"
    createdby/date: krishna/2021-11-23
    description: to get the credit settlement detail view.
    change history
    s.no.    updatedby/date                        remarks
    1.		krishna/2021-11-23						created sp to get the credit settlement view detail
    */
    
    --patient information--
    open ref1 for select patientid,
    		shortname as "patientname",
    		patientcode as "hospitalno",
    		gender,
    		dateofbirth
    from pat_patient 
    where patientid = p_patientid;
        return next ref1;
    
    --collection from receivable--
    open ref2 for select 
    	sett.patientid, 
    	(sett.settlementdate)::date as "settlementdate",
    	sett.settlementreceiptno,
    	txn.invoiceno,
    	txn.invoicecode,
    	(txn.createdon)::date as "invoicedate",
    	coalesce(txn.totalamount,0) as "salesamount",
    	coalesce(ret.rettotalamount,0) as "returntotalamount",
    	coalesce(txn.totalamount,0) - coalesce(ret.rettotalamount,0) as "receivable",
    	coalesce(sett.discountamount,0) as "cashdiscount"
    
    from bil_txn_settlements sett inner join pat_patient pat
    	on sett.patientid = pat.patientid
    	left join bil_txn_billingtransaction txn on sett.settlementid = txn.settlementid
    	left join 
    			(select settlementid, billingtransactionid, 
    			sum(coalesce(totalamount,0)) as "rettotalamount"
    			from bil_txn_invoicereturn 
    			where settlementid is not null
    			--where patientid = p_patientid
    			group by settlementid , billingtransactionid) ret
    			on sett.settlementid = ret.settlementid and txn.billingtransactionid = ret.billingtransactionid
    where (sett.createdon)::date between p_fromdate and p_todate and sett.patientid = p_patientid
    		and coalesce(sett.collectionfromreceivable,0) != 0;
        return next ref2; -- need only settlement
    
    --return to receivable--
    open ref3 for select 
    	sett.settlementreceiptno, 
    	(sett.createdon)::date as "settlementdate",
    	ret.creditnotenumber,
    	(ret.createdon)::date as "returndate",
    	coalesce(ret.totalamount,0) as "returntotalamount",
    	ret.refinvoicenum,
    	ret.invoicecode,
    	sett.discountreturnamount
    from bil_txn_settlements sett inner join
    bil_txn_invoicereturn ret on sett.settlementid = ret.settlementid
    where (sett.createdon)::date between p_fromdate and p_todate and sett.patientid = p_patientid
    	and lower(ret.billstatus) = 'paid';
        return next ref3; -- need only returns done after settlement
    
    --get cash discount--
    open ref4 for select sum(coalesce(discountamount,0)) as "cashdiscount" from bil_txn_settlements 
    where (createdon)::date between p_fromdate and p_todate and patientid = p_patientid
    		and coalesce(collectionfromreceivable,0) != 0;
        return next ref4;
END;
$$ LANGUAGE plpgsql;