CREATE OR REPLACE FUNCTION sp_acc_bankreconcilationdetail(
    p_fromdate TIMESTAMP,
    p_todate TIMESTAMP,
    p_ledgerid INT,
    p_vouchertypeid INT,
    p_status INT
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
BEGIN
    /* 
      exec "sp_acc_bankreconcilationdetail" '2022-11-05','2022-11-15',180,3,1
      s.no.    updatedby/date                        remarks
      1.      dev narayan 14'Nov'22                   sp script created for bank reconcilation detail
      2.      dev narayan 26'March'23                 added isverified filter in acc_transactions table.
      3.      devn 4th may, 23                        get subledger information in brs..
      4.      devn 25th june,23                       exclude reversed vouchers in brs.
    */
    begin
    
    	--table 1: reconcilation data
    	open ref1 for select txn.vouchernumber
    		,txn.sectionid
    		,txn.transactiondate
    		,txn.fiscalyearid
    		,item.ledgerid as "partyledgerid"
    		,ledger.ledgername as "partyledgername"
    		,subledgertxn.subledgerid as "partysubledgerid"
    		,subledger.subledgername as "partysubledgername"
    		,voucher.vouchername
    		,txn.chequenumber
    		,txn.chequedate
    		,case 
    			when coalesce(item.drcr, 0) = 0
    				then item.amount
    			else 0
    			end as "ledgercr"
    		,case 
    			when coalesce(item.drcr, 0) = 0
    				then 0
    			else item.amount
    			end as "ledgerdr"
    		,item.drcr
    		,txn.voucherid as "vouchertypeid"
    		,reconsile.banktransactiondate
    		,item.amount as "bankbalance"
    		,case 
    			when reconsile.id is null
    				then 'open'
    			else 'close'
    			end as "status"
    		,txn.remarks as "remark"
    		,txn.transactionid
    		,txn.hospitalid
    		,reconsile.bankrefnumber
    		,reconsile.vouchertypeid
    		,p_ledgerid as ledgerid
    		,0 as isverified
    	from acc_transactionitems item
    	join acc_transactions txn on item.transactionid = txn.transactionid
    	join acc_txn_subledgerrecords subledgertxn on item.transactionitemid = subledgertxn.transactionitemid and item.ledgerid = subledgertxn.ledgerid
    	join acc_ledger ledger on item.ledgerid = ledger.ledgerid
    	join acc_mst_subledger subledger on subledgertxn.subledgerid = subledger.subledgerid
    	join acc_mst_vouchers voucher on txn.voucherid = voucher.voucherid
    	left join acc_txn_bank_reconciliation reconsile on txn.transactionid = reconsile.transactionid
    		and item.ledgerid = reconsile.partyledgerid
    	where (txn.transactiondate)::date between (p_fromdate)::date
    			and (p_todate)::date
    		and coalesce(txn.isvoucherreversed,0) = 0
    		and txn.transactionid in (
    			select transactionid
    			from acc_transactionitems
    			where ledgerid = p_ledgerid
    			)
    		and item.ledgerid <> p_ledgerid
    		and txn.isverified = 1
    		and (
    			txn.voucherid = p_vouchertypeid
    			or p_vouchertypeid = 0
    			)
    		and (
    			(
    				case 
    					when reconsile.banktransactiondate is null
    						then 1
    					else 2
    					end
    				) = p_status
    			or p_status = 0
    			);
        return next ref1;
    
    	--table 2: reconcilation opening balance
    	open ref2 for select coalesce(sum(case 
    					when drcr = 1
    						then bankbalance
    					else - bankbalance
    					end), 0) as reconcileopeningbalance
    	from acc_txn_bank_reconciliation
    	where ledgerid = p_ledgerid;
        return next ref2;
    end;
END;
$$ LANGUAGE plpgsql;