CREATE OR REPLACE FUNCTION sp_get_settlement_details_by_settlementid(
    p_settlementid INT DEFAULT 0
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
    ref3 refcursor := 'cursor3';
    ref4 refcursor := 'cursor4';
    ref5 refcursor := 'cursor5';
    ref6 refcursor := 'cursor6';
    v_patientid INT := 0;
BEGIN
    /*
    filename: sp_get_settlement_details_by_settlementid 
    description: to get the settlement details by settlementid for duplicate prints and settlement receipt
    remarks: we're returning 6 tables from this StoredProc.
    1. patient info
    2. settlement info
    3. sales info against current settlement
    4. sales return info against current settlement
    5. cash discount return against current settlement
    6. Deposit info against current settlementChange History
    	
    Change History
    S.No.    UpdatedBy/Date                        Remarks
    1.      Krishna/25th,NOV'21                    created sp to get the settlement details for settlement receipt.   
    2.      dev narayan/18th,jan'22                Changed SP to get paidAmount in Table-2 : Settlement Info
    3.		Sanjeev/21st,Feb'23					   add countryname, countrysubdivisionname, municipalityname, wardnumber in
    											   table-1: 
    											   patient info
    4.		sanjeev/24th,feb'23					   Add memebrshipTypeName, SSFPolicyNo (PolicyNo of SSF Patient), PolicyNo
    											   (PolicyNo of
    											   ECHS Patient)in --table-1: patient info--
    											   Add CreditOrganizationName in --table-2: settlement info--
    5.      Krishna/21stApril'23				   remove unnecessary joins and selections, change deposit type to 
    											   transaction type and amount to inamount and outamount
    6.		krishna/25thapril'23				   Add Pharmacy sales and Returns selection query
    7.	    Krishna/15thMay'23					   remove inner join bil_cfg_scheme on the basis of membershiptypeid in pat_patient table
    	*/
    begin
    	
    
    	--setting value to v_patientid--
    	select patientid into v_patientid from  
    		bil_txn_settlements
    	where 
    		settlementid = p_settlementid;
    
    	--table-1: patient info--
    	open ref1 for select
    		pat.patientid,
    		pat.shortname as "patientname",
    		pat.patientcode as "hospitalno",
    		pat.phonenumber as "contactno",
    		pat.gender as "gender",
    		pat.dateofbirth as "dateofbirth",
    		pat.address as "address",
    		cnty.countryname as "countryname",
    		subdiv.countrysubdivisionname as "countrysubdivisionname",
    		munc.municipalityname as "municipalityname",
    		pat.wardnumber as "wardnumber"
    		
    	from 
    		pat_patient  pat  
    		--inner join bil_cfg_scheme scheme on pat.membershiptypeid = scheme.schemeid
    		inner join mst_countrysubdivision subdiv on pat.countrysubdivisionid = subdiv.countrysubdivisionid  
    		inner join mst_country cnty on subdiv.countryid = cnty.countryid
            left join mst_municipality munc on pat.municipalityid = munc.municipalityid
    	where 
    		pat.patientid = v_patientid;
        return next ref1;
    
    	--table-2: settlement info--
    	open ref2 for select
    		txn.settlementid,
    		txn.settlementreceiptno,
    		txn.settlementdate,
    		txn.paymentmode,
    		txn.createdby,
    		paidamount,
    		coalesce(discountamount,0) as "cashdiscountgiven", --> change this to 'CashDiscountGiven'
    		crorg.organizationname as "creditorganizationname"
    	from 
    		bil_txn_settlements txn 
    		left join bil_mst_credit_organization crorg   
    		on txn.organizationid = crorg.organizationid
    	where 
    		settlementid = p_settlementid;
        return next ref2;
    
    	
    --table-3: sales--
    	open ref3 for select
    		concat(txn.invoicecode || '-', txn.invoiceno) as "receiptno",
    		txn.createdon as "receiptdate",
    		txn.totalamount as "amount"
    	from 
    		bil_txn_billingtransaction txn 
    	where 
    		txn.settlementid = p_settlementid
    
    	union all
    
    	select
    		concat('PH' , txn.invoiceprintid) as "receiptno",
    		txn.createon as "receiptdate",
    		txn.totalamount as "amount"
    	from 
    		phrm_txn_invoice txn
    	where 
    		txn.settlementid = p_settlementid;
        return next ref3;
    	
    	--table-4: sales return--
    	open ref4 for select
    		billreturnid,
    		'CR-'||(creditnotenumber)::varchar as "receiptno",
    		(createdon)::date as "receiptdate",
    		totalamount as "amount"
    	from 
    		bil_txn_invoicereturn 
    	where 
    		coalesce(settlementid,0) = p_settlementid 
    
    	union all
    
    	select
    		invoicereturnid as "billreturnid",
    		'CR-PH'||(creditnoteid)::varchar as "receiptno",
    		(createdon)::date as "receiptdate",
    		totalamount as "amount"
    	from 
    		phrm_txn_invoicereturn 
    	where 
    		coalesce(settlementid,0) = p_settlementid;
        return next ref4; 
    
    	--table-5: cash discount return--
    	open ref5 for select
    		'CR-'|| (ret.creditnotenumber)::varchar as "receiptno",
    		ret.createdon as "receiptdate",
    		sett.discountreturnamount as "cashdiscountreceived" ---> change this to 'CashDiscountReceived'
    	from 
    		bil_txn_settlements sett 
    		left join bil_txn_invoicereturn ret  
    		     on sett.settlementid = ret.settlementid
    	where 
    		coalesce(sett.settlementid,0) = p_settlementid and 
    		coalesce(sett.discountreturnamount,0)!=0;
        return next ref5; 
    
    	--table-6: deposit info--
    	open ref6 for select
    		'DR-'||(receiptno)::varchar as "receiptno",
    		case 
    			when dep.transactiontype='depositdeduct' then 'Deposit Deducted'
    			when dep.transactiontype='ReturnDeposit' then 'Deposit Returned'
    			when dep.transactiontype='Deposit' then 'Deposit Received' 
    		end as transactiontype,
    		dep.inamount,
    		dep.outamount,
    		dep.createdon as "receiptdate"
    	from 
    		bil_txn_deposit dep
    	where 
    		dep.settlementid=p_settlementid
    		and lower(transactiontype) in ('depositdeduct','returndeposit')
    	order by dep.settlementid;
        return next ref6;
    end;
END;
$$ LANGUAGE plpgsql;