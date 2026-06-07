CREATE OR REPLACE FUNCTION sp_bil_update_duplicate_invoice_if_exists(
    p_fiscalyearid INT,
    p_billingtransactionid INT,
    p_invoicenumber INT
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
    v_latestinvoicenumber INT;
BEGIN
    begin
     alter table bil_txn_billingtransaction disable trigger trg_billingtransaction_restrictbillalter;  
       
    --if  exists then this means duplication has occurred
    	if(exists(select * from bil_txn_billingtransaction where (billingtransactionid != p_billingtransactionid) and (invoiceno = p_invoicenumber) and (fiscalyearid = p_fiscalyearid))) 
    		then
    			
    			--get the latest invoice number of that fiscal year and update in the invoice number of that bill_transaction and deposit remarks
    			v_latestinvoicenumber := (select max(invoiceno)||1 from bil_txn_billingtransaction where fiscalyearid=p_fiscalyearid);
    			update bil_txn_billingtransaction set invoiceno=v_latestinvoicenumber where billingtransactionid = p_billingtransactionid;
    			update bil_txn_deposit set remarks=replace(remarks,p_invoicenumber,v_latestinvoicenumber) where billingtransactionid = p_billingtransactionid;
    			open ref1 for select v_latestinvoicenumber as latestinvoicenumber;
        return next ref1;
    		
    	else
    		 
    			open ref2 for select p_invoicenumber as latestinvoicenumber;
        return next ref2;
    		end if;
    
    alter table bil_txn_billingtransaction enable trigger trg_billingtransaction_restrictbillalter;
    end;
END;
$$ LANGUAGE plpgsql;