CREATE OR REPLACE FUNCTION sp_acc_bill_getpaymentmodeamountdatewise(
    p_transactiondate DATE,
    p_hospitalid INT
)
RETURNS TABLE (
    "PaymentSubCategoryName" VARCHAR,
    "TransactionType" TIMESTAMP,
    "TotalAmount" DECIMAL,
    "LedgerId" INT,
    "OrganizationId" INT
) AS $$
DECLARE
    v_billtxnidscsv VARCHAR;
		
    v_depositidscsv VARCHAR;
		
    v_depositdeductidscsv VARCHAR;
		
    v_depositreturnidscsv VARCHAR;
		
    v_settlementidscsv VARCHAR;
		
    v_salesreturnidscsv VARCHAR;
		
    v_cashdiscountreturnsettlementidscsv VARCHAR;
BEGIN
    /**************************************************
    		stored procedure name:sp_acc_bill_getpaymentmodeamountdatewise	
    		execution:
    		exec "sp_acc_bill_getpaymentmodeamountdatewise" '2022-06-04',1
    		details:
    		-this stored procedure will get payment mode data and amounts for transfer to accounting by date
    		-we are getting billing records, deposit records, etc
    		
    
    			change history:
    			s.no.   author					date				 remarks
    			1.      krishna					9thmarch'22			Stored procedure created
    			2.		Bikash/Krishna			10thMarch'22		transaction type change according to accounting rules
    			3.		bikash					11thmarch'22		LedgerId added - according to Ledger Mapping with different Payment Modes 
    			4.      Dev Narayan             24thMay'22          added credit organization id for crdit bill paid (i.e. settlement)
    			5.      devn					19th may 23         modulename filter added for billing deposits.
    		**********************************************/
    	
    	
    
    	v_billtxnidscsv := (
    			select string_agg(cast(billingtransactionid as text), ',')
    			from bil_txn_billingtransaction
    			where billingtransactionid in (
    					select distinct billingtransactionid
    					from bil_txn_billingtransactionitems
    					where coalesce(iscashbillsync, 0) = 0
    						and (paiddate)::date = (p_transactiondate)::date
    					)
    			);
    	--setting depositids into v_depositidscsv 
    	v_depositidscsv := (
    			select string_agg(cast(depositid as text), ',')
    			from bil_txn_deposit
    			where depositid in (
    					select distinct depositid
    					from bil_txn_deposit
    					where transactiontype = 'Deposit'
    						and coalesce(isdepositsync, 0) = 0
    						and (createdon)::date = (p_transactiondate)::date
    						and modulename = 'Billing'
    					)
    			);
    	--setting depositdeductids into v_depositdeductidscsv 
    	v_depositdeductidscsv := (
    			select string_agg(cast(depositid as text), ',')
    			from bil_txn_deposit
    			where depositid in (
    					select distinct depositid
    					from bil_txn_deposit
    					where transactiontype = 'depositdeduct'
    						and coalesce(isdepositsync, 0) = 0
    						and (createdon)::date = (p_transactiondate)::date
    						and modulename = 'Billing'
    					)
    			);
    	--setting depositreturnids into v_depositreturnidscsv 
    	v_depositreturnidscsv := (
    			select string_agg(cast(depositid as text), ',')
    			from bil_txn_deposit
    			where depositid in (
    					select distinct depositid
    					from bil_txn_deposit
    					where transactiontype = 'ReturnDeposit'
    						and coalesce(isdepositsync, 0) = 0
    						and (createdon)::date = (p_transactiondate)::date
    						and modulename = 'Billing'
    					)
    			);
    	--setting settlementids into v_settlementidscsv 
    	v_settlementidscsv := (
    			select string_agg(cast(settlementid as text), ',')
    			from bil_txn_settlements
    			where settlementid in (
    					select distinct settlementid
    					from bil_txn_settlements
    					where coalesce(issynctoacc, 0) = 0
    						and coalesce(collectionfromreceivable,0)>0
    						and coalesce(discountreturnamount,0)=0
    						and (createdon)::date = (p_transactiondate)::date
    					)
    			);
    
    
    --setting settlementids for  into v_cashdiscountreturnsettlementidscsv
    	v_cashdiscountreturnsettlementidscsv := (
    			select string_agg(cast(settlementid as text), ',')
    			from bil_txn_settlements
    			where settlementid in (
    					select distinct settlementid
    					from bil_txn_settlements
    					where coalesce(issynctoacc, 0) = 0
    						and coalesce(collectionfromreceivable,0)=0
    						and coalesce(discountreturnamount,0)>0
    						and (createdon)::date = (p_transactiondate)::date
    					)
    			);
    
    	--setting invoicereturnids into v_salesreturnidscsv
    	v_salesreturnidscsv := (
    			select string_agg(cast(billreturnid as text), ',')
    			from bil_txn_invoicereturnitems
    			where billreturnid in (
    					select distinct billreturnid
    					from bil_txn_invoicereturnitems
    					where coalesce(iscashbillsynctoacc, 0) = 0
    						and (createdon)::date = (p_transactiondate)::date
    					)
    			);
    
    	RETURN QUERY SELECT modes.paymentsubcategoryname
    		,'CashBill' AS "TransactionType"
    		,coalesce(sum(inamount),0) AS "TotalAmount"
    		,ledgerid
    		,null AS "OrganizationId"
    	from txn_empcashtransaction cash
    	inner join mst_paymentmodes modes on cash.paymentmodesubcategoryid = modes.paymentsubcategoryid
    	left join acc_ledger_mapping lm on modes.paymentsubcategoryid = lm.referenceid and lm.ledgertype ='paymentmodes' and lm.hospitalid =p_hospitalid
    	where transactiontype = 'CashSales'
    		and referenceno in (
    			select value
    			from string_split(v_billtxnidscsv, ',')
    			)
    		
    	group by modes.paymentsubcategoryname, lm.ledgerid
    
    	
    	union all
    	
    	select modes.paymentsubcategoryname
    		,'DepositAdd' AS "TransactionType"
    		,coalesce(sum(inamount),0)  AS "TotalAmount"
    		,ledgerid
    		,null AS "OrganizationId"
    	from txn_empcashtransaction cash
    	inner join mst_paymentmodes modes on cash.paymentmodesubcategoryid = modes.paymentsubcategoryid
    	left join acc_ledger_mapping lm on modes.paymentsubcategoryid = lm.referenceid and lm.ledgertype ='paymentmodes' and lm.hospitalid =p_hospitalid
    	where transactiontype = 'Deposit'
    		and referenceno in (
    			select value
    			from string_split(v_depositidscsv, ',')
    			)
    	group by modes.paymentsubcategoryname,lm.ledgerid
    	
    	union all
    	
    	select modes.paymentsubcategoryname
    		,'DepositDeduct' AS "TransactionType"
    		,coalesce(sum(outamount),0)  AS "TotalAmount"
    		, ledgerid
    		,null AS "OrganizationId"
    	from txn_empcashtransaction cash
    	inner join mst_paymentmodes modes on cash.paymentmodesubcategoryid = modes.paymentsubcategoryid
    	left join acc_ledger_mapping lm on modes.paymentsubcategoryid = lm.referenceid and lm.ledgertype ='paymentmodes' and lm.hospitalid =p_hospitalid
    	where transactiontype = 'depositdeduct'
    		and referenceno in (
    			select value
    			from string_split(v_depositdeductidscsv, ',')
    			)
    	group by modes.paymentsubcategoryname, lm.ledgerid
    	
    	union all
    	
    	select modes.paymentsubcategoryname
    		,'DepositReturn' AS "TransactionType"
    		,coalesce(sum(outamount),0)  AS "TotalAmount"
    		,ledgerid
    		,null AS "OrganizationId"
    	from txn_empcashtransaction cash
    	inner join mst_paymentmodes modes on cash.paymentmodesubcategoryid = modes.paymentsubcategoryid
    	left join acc_ledger_mapping lm on modes.paymentsubcategoryid = lm.referenceid and lm.ledgertype ='paymentmodes' and lm.hospitalid =p_hospitalid
    	where transactiontype = 'ReturnDeposit'
    		and referenceno in (
    			select value
    			from string_split(v_depositreturnidscsv, ',')
    			)
    	group by modes.paymentsubcategoryname, lm.ledgerid
    	
    	union all
    	
    	
    	
    	select modes.paymentsubcategoryname
    		,'CreditBillPaid' AS "TransactionType"
    		,coalesce(sum(inamount),0) - coalesce(sum(outamount),0) AS "TotalAmount"
    		,lm.ledgerid
    		,settl.organizationid
    	from bil_txn_settlements settl
    	join txn_empcashtransaction cash on settl.settlementid = cash.referenceno
    	inner join mst_paymentmodes modes on cash.paymentmodesubcategoryid = modes.paymentsubcategoryid
    	left join acc_ledger_mapping lm on modes.paymentsubcategoryid = lm.referenceid and lm.ledgertype ='paymentmodes' and lm.hospitalid =p_hospitalid
    	where transactiontype in  ('CollectionFromReceivable','CashDiscountGiven')
    		and referenceno in (
    			select value
    			from string_split(v_settlementidscsv, ',') -- settlementid ref
    			)
    	group by modes.paymentsubcategoryname, lm.ledgerid,settl.organizationid
    	
    	union all
    	
    	select modes.paymentsubcategoryname
    		,'CashBillReturn' AS "TransactionType"
    		,coalesce(sum(outamount),0)  AS "TotalAmount"
    		,ledgerid
    		,null AS "OrganizationId"
    	from txn_empcashtransaction cash
    	inner join mst_paymentmodes modes on cash.paymentmodesubcategoryid = modes.paymentsubcategoryid
    	left join acc_ledger_mapping lm on modes.paymentsubcategoryid = lm.referenceid and lm.ledgertype ='paymentmodes' and lm.hospitalid =p_hospitalid
    	where transactiontype = 'SalesReturn'
    		and referenceno in (
    			select value
    			from string_split(v_salesreturnidscsv, ',')
    			)
    	group by modes.paymentsubcategoryname, lm.ledgerid
    	union all
    	
    	select modes.paymentsubcategoryname
    		,'DiscountReturn' AS "TransactionType"
    		,coalesce(sum(inamount),0)  AS "TotalAmount"
    		, 0 AS "LedgerId"
    		,null AS "OrganizationId"
    	from txn_empcashtransaction cash
    	inner join mst_paymentmodes modes on cash.paymentmodesubcategoryid = modes.paymentsubcategoryid
    	where transactiontype = 'CashDiscountReceived'
    		and referenceno in (
    			select value
    			from string_split(v_cashdiscountreturnsettlementidscsv, ',') -- settlementid ref
    			)
    	group by modes.paymentsubcategoryname;
END;
$$ LANGUAGE plpgsql;