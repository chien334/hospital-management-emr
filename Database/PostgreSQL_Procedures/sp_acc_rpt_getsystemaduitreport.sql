CREATE OR REPLACE FUNCTION sp_acc_rpt_getsystemaduitreport(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_voucherreporttype VARCHAR DEFAULT NULL,
    p_sectionid INT DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
    ref3 refcursor := 'cursor3';
BEGIN
    /*
    filename: "sp_acc_rpt_getsystemaduitreport"
    createdby/date:
    description: 
    change history
    s.no.    updatedby/date              remarks
    1       vikas/24 june 2020           get report for system log records of edit voucher, reversal transaction, back date entry for accounting.
    2		nageshbb/ 19aug 2020	     added sectionid check for all records
    3       dev narayan 26'March'23      added isverified filter in acc_transactions table.
    */
    begin
    	if (p_fromdate is not null)
    		or (p_todate is not null)
    	then
    		if (p_voucherreporttype = 'EditVoucher')
    		then
    			-- start: edit voucher logs details
    			open ref1 for select fs.fiscalyearname
    				,lg.sectionid
    				,sc.sectionname
    				,lg.transactiondate
    				,lg.vouchernumber
    				,lg.reason
    				,lg.createdon
    				,lg.createdby
    				,lg.logid
    				,usr.fullname
    			from acc_log_editvoucher lg
    			left join acc_mst_fiscalyears fs on lg.fiscalyearid = fs.fiscalyearid
    			left join acc_mst_sectionlist sc on lg.sectionid = sc.sectionid
    			left join emp_employee usr on lg.createdby = usr.employeeid
    			where (lg.createdon)::date between (p_fromdate)::date
    					and (p_todate)::date
    				and lg.sectionid = p_sectionid;
        return next ref1;
    				-- end: edit voucher logs details
    		
    		elsif (p_voucherreporttype = 'VoucherReversal')
    		then
    			-- start: reversal voucher txn logs details
    			open ref2 for select accr.reversetransactionid
    				,fs.fiscalyearname
    				,sc.sectionname
    				,accr.transactiondate
    				,accr.reason
    				,accr.createdon
    				,accr.createdby
    				,usr.fullname
    			from acc_reversetransaction accr
    			left join acc_mst_fiscalyears fs on accr.fiscalyearid = fs.fiscalyearid
    			left join acc_mst_sectionlist sc on accr.section = sc.sectionid
    			left join emp_employee usr on accr.createdby = usr.employeeid
    			where (accr.createdon)::date between (p_fromdate)::date
    					and (p_todate)::date
    				and accr.section = p_sectionid;
        return next ref2;
    				-- end: reversal voucher txn logs details
    		
    		elsif (p_voucherreporttype = 'BackDateEntry')
    		then
    			-- start: back date entry txn logs details
    			open ref3 for select txn.transactionid
    				,txn.sectionid
    				,sc.sectionname
    				,txn.transactiondate
    				,txn.vouchernumber
    				,txn.createdon
    				,txn.createdby
    				,usr.fullname
    			from acc_transactions txn
    			left join acc_mst_sectionlist sc on txn.sectionid = sc.sectionid
    			left join emp_employee usr on txn.createdby = usr.employeeid
    			where (txn.createdon)::date between (p_fromdate)::date
    					and (p_todate)::date
    				and txn.sectionid = p_sectionid
    				and txn.isverified = 1;
        return next ref3;
    				-- end: back date entry txn logs details
    		end if;
    	end if;
    end;
END;
$$ LANGUAGE plpgsql;