CREATE OR REPLACE FUNCTION sp_acc_dailytransactionreportdetails(
    p_vouchernumber VARCHAR,
    p_hospitalid INT
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
    ref3 refcursor := 'cursor3';
    v_transactiontype VARCHAR;
    v_referenceids VARCHAR;
BEGIN
    /************************************************************************
    filename: "sp_acc_dailytransactionreportdetails"
    author  : nageshbb
    created date: 12july2021
    description:			
    change history
    s.no.    updatedby/date                        remarks
    1       nageshbb /12july2021		  updated script for return bill changes
    2		aniket /21sep2021			  updated script for bill return changes 
    
    *************************************************************************************/
    
    begin
     
     v_transactiontype := (select string_agg(transactiontype, ',') as "trasactiontype" 
    						 from acc_transactions 
    						 where hospitalid= p_hospitalid and	 vouchernumber = p_vouchernumber );
     
     v_referenceids := (select string_agg(referenceid, ',') as "trasactiontype" 
    					 from acc_transactions txn 
    					 join acc_txn_link txnlink on txn.transactionid= txnlink.transactionid
    					 where  txn.hospitalid= p_hospitalid and txn.vouchernumber =p_vouchernumber ); 
    
    
    
     if(('DepositAdd') in(select * from string_split(v_transactiontype, ','))
       or ('DepositReturn') in(select * from string_split(v_transactiontype, ',')) )
    		then open ref1 for select 
    			pat.firstname || ' ' || coalesce(pat.middlename,'') || ' ' || pat.lastname  as "patientname",
    			dep.receiptno as "receiptno",
    			sum(dep.amount) as "totalamount",
    			dep.paymentmode as "paymentmode"
    		from bil_txn_deposit dep 	
    		join pat_patient pat on dep.patientid = pat.patientid
    		where dep.depositid in (select * from string_split(v_referenceids, ',')) 
    
    		group by
    			pat.firstname,pat.middlename,pat.lastname,
    			dep.receiptno ,
    			dep.paymentmode;
        return next ref1; end if;  
    
     --if( ('CashBill') in(select * from string_split(v_transactiontype, ','))
    	--or ('CreditBill') in(select * from string_split(v_transactiontype, ','))
    	--or ('CashBillReturn') in(select * from string_split(v_transactiontype, ','))
    	--or ('CreditBillReturn') in(select * from string_split(v_transactiontype, ','))
     --  )
    	--	select 
    	--			txn.invoicecode + cast(txn.invoiceno as varchar) as invoiceno,
    	--			pat.firstname + ' ' + coalesce(pat.middlename,'') + ' ' + pat.lastname  as "patientname",
    	--			itm.*
    	--	from bil_txn_billingtransactionitems itm 
    	--			join bil_txn_billingtransaction txn on itm.billingtransactionid= txn.billingtransactionid
    	--			join pat_patient pat on itm.patientid = pat.patientid 
    	--	where itm.billingtransactionitemid in (select * from string_split(v_referenceids, ','))
    
     if( ('CashBill') in(select * from string_split(v_transactiontype, ','))
    	or ('CreditBill') in(select * from string_split(v_transactiontype, ','))
       )
    		then open ref2 for select 
    				txn.invoicecode || cast(txn.invoiceno as varchar) as invoiceno,
    				pat.firstname || ' ' || coalesce(pat.middlename,'') || ' ' || pat.lastname  as "patientname",
    				itm.*
    		from bil_txn_billingtransactionitems itm 
    				join bil_txn_billingtransaction txn on itm.billingtransactionid= txn.billingtransactionid
    				join pat_patient pat on itm.patientid = pat.patientid 
    		where itm.billingtransactionitemid in (select * from string_split(v_referenceids, ','));
        return next ref2; end if; 
    
    if(('CashBillReturn') in(select * from string_split(v_transactiontype, ','))
    	or ('CreditBillReturn') in(select * from string_split(v_transactiontype, ','))
       )
    		then open ref3 for select 
    				rettxn.invoicecode || cast(rettxn.creditnotenumber as varchar) as invoiceno,
    				pat.firstname || ' ' || coalesce(pat.middlename,'') || ' ' || pat.lastname  as "patientname",
    				retitm.*
    		from bil_txn_invoicereturnitems retitm 
    				join bil_txn_invoicereturn rettxn on retitm.billreturnid= rettxn.billreturnid
    				join pat_patient pat on retitm.patientid = pat.patientid 
    		where retitm.billreturnitemid  in (select * from string_split(v_referenceids, ','));
        return next ref3; end if; 
    end;
END;
$$ LANGUAGE plpgsql;