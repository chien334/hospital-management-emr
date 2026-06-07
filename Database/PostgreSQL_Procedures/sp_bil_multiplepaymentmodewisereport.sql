CREATE OR REPLACE FUNCTION sp_bil_multiplepaymentmodewisereport(
    p_fromdate DATE,
    p_todate DATE,
    p_paymentmode VARCHAR DEFAULT NULL,
    p_type VARCHAR DEFAULT NULL,
    p_user INT DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
BEGIN
    begin
    		if p_paymentmode = 'all'
    			then
    			p_paymentmode := null;
    		end if;
    
    		if p_type = 'all'
    			then
    			p_type := null;
    		end if;
    	    open ref1 for select *
    		from (
    			(select emptxn.transactiondate::date as "date"
    					,case 
    						when emptxn.transactiontype = 'CashSales' then 'Cash Sales'
    					 end as "type"
    					,pmodes.paymentsubcategoryname as "paymentmode"
    					,case 
    						when emptxn.transactiontype = 'CashSales' then concat (txn.invoicecode,'-',txn.invoiceno)
    					 end as "receiptno"
    					,pat.patientcode as "hospitalno"
    					,pat.shortname as "patientname"
    					,coalesce(emptxn.inamount, 0) as "nettotal"
    					--,coalesce(emptxn.outamount, 0) as "outamount"
    					--,coalesce(emptxn.inamount, 0) - coalesce(emptxn.outamount,0) as "nettotal"
    					,emp.fullname as "user"
    					,emp.employeeid
    					,cntr.countername as "counter"
    					,emptxn.remarks
    				from txn_empcashtransaction as "emptxn"
    						inner join bil_txn_billingtransaction txn on txn.billingtransactionid = emptxn.referenceno
    						inner join pat_patient pat on pat.patientid = txn.patientid
    						inner join emp_employee emp on emp.employeeid = emptxn.employeeid
    						inner join mst_paymentmodes pmodes on pmodes.paymentsubcategoryid = emptxn.paymentmodesubcategoryid
    						inner join bil_cfg_counter cntr on cntr.counterid = emptxn.counterid
    						where emptxn.transactiontype = 'CashSales'
    							and pmodes.paymentsubcategoryname != 'Deposit'
    							and emptxn.transactiondate::date between p_fromdate and p_todate
    				)
    	
    			union
    			(select emptxn.transactiondate::date as "date"
    					,case 
    						when emptxn.transactiontype = 'Deposit' then 'Deposit Received'
    					 end as "type"
    					,pmodes.paymentsubcategoryname as "paymentmode"
    					,case 
    						when emptxn.transactiontype = 'Deposit' then (dep.receiptno)::varchar(50)
    					 end as "receiptno"
    					,pat.patientcode as "hospitalno"
    					,pat.shortname as "patientname"
    					,coalesce(emptxn.inamount, 0) as "nettotal"
    					--,coalesce(emptxn.outamount, 0) as "outamount"
    					--,coalesce(emptxn.inamount, 0) - coalesce(emptxn.outamount,0) as "nettotal"
    					,emp.fullname as "user"
    					,emp.employeeid
    					,cntr.countername as "counter"
    					,emptxn.remarks
    				from txn_empcashtransaction as "emptxn"
    						inner join bil_txn_deposit dep on dep.depositid = emptxn.referenceno
    						inner join pat_patient pat on pat.patientid = dep.patientid
    						inner join emp_employee emp on emp.employeeid = emptxn.employeeid
    						inner join mst_paymentmodes pmodes on pmodes.paymentsubcategoryid = emptxn.paymentmodesubcategoryid
    						inner join bil_cfg_counter cntr on cntr.counterid = emptxn.counterid
    						where emptxn.transactiontype = 'Deposit'
    							and pmodes.paymentsubcategoryname != 'Deposit'
    							and emptxn.transactiondate::date between p_fromdate and p_todate
    				)
    	
    			union
    			(select emptxn.transactiondate::date as "date"
    					,case 
    						when emptxn.transactiontype = 'CollectionFromReceivable' then 'Credit Settlement'
    					 end as "type"
    					,pmodes.paymentsubcategoryname as "paymentmode"
    					,case 
    						when emptxn.transactiontype = 'CollectionFromReceivable' then concat ('SR','-',sett.settlementreceiptno)
    					 end as "receiptno"
    					,pat.patientcode as "hospitalno"
    					,pat.shortname as "patientname"
    					,coalesce(emptxn.inamount, 0) as "nettotal"
    					--,coalesce(emptxn.outamount, 0) as "outamount"
    					--,coalesce(emptxn.inamount, 0) - coalesce(emptxn.outamount,0) as "nettotal"
    					,emp.fullname as "user"
    					,emp.employeeid
    					,cntr.countername as "counter"
    					,emptxn.remarks
    				from txn_empcashtransaction as "emptxn"
    						inner join bil_txn_settlements sett on sett.settlementid = emptxn.referenceno
    						inner join pat_patient pat on pat.patientid = sett.patientid
    						inner join emp_employee emp on emp.employeeid = emptxn.employeeid
    						inner join mst_paymentmodes pmodes on pmodes.paymentsubcategoryid = emptxn.paymentmodesubcategoryid
    						inner join bil_cfg_counter cntr on cntr.counterid = emptxn.counterid
    						where emptxn.transactiontype = 'CollectionFromReceivable'
    							and pmodes.paymentsubcategoryname != 'Deposit'
    							and emptxn.transactiondate::date between p_fromdate and p_todate
    				)
    
    				union
    			(select emptxn.transactiondate::date as "date"
    					,case 
    						when emptxn.transactiontype = 'SalesReturn' then 'Cash Sales Return'
    					 end as "type"
    					,pmodes.paymentsubcategoryname as "paymentmode"
    					,case 
    						when emptxn.transactiontype = 'SalesReturn' then concat ('CR','-',ret.billreturnid)
    					 end as "receiptno"
    					,pat.patientcode as "hospitalno"
    					,pat.shortname as "patientname"
    					--,coalesce(emptxn.inamount, 0) as "inamount"
    					,coalesce(emptxn.outamount, 0) as "nettotal"
    					--,coalesce(emptxn.inamount, 0) - coalesce(emptxn.outamount,0) as "nettotal"
    					,emp.fullname as "user"
    					,emp.employeeid
    					,cntr.countername as "counter"
    					,emptxn.remarks
    				from txn_empcashtransaction as "emptxn"
    						inner join bil_txn_invoicereturn ret on ret.billreturnid = emptxn.referenceno
    						inner join pat_patient pat on pat.patientid = ret.patientid
    						inner join emp_employee emp on emp.employeeid = emptxn.employeeid
    						inner join mst_paymentmodes pmodes on pmodes.paymentsubcategoryid = emptxn.paymentmodesubcategoryid
    						inner join bil_cfg_counter cntr on cntr.counterid = emptxn.counterid
    						where emptxn.transactiontype = 'SalesReturn'
    							and pmodes.paymentsubcategoryname != 'Deposit'
    							and emptxn.transactiondate::date between p_fromdate and p_todate
    				)
    				union
    				(select emptxn.transactiondate::date as "date"
    					,case 
    						when emptxn.transactiontype = 'ReturnDeposit' then 'Deposit Refund'
    					 end as "type"
    					,pmodes.paymentsubcategoryname as "paymentmode"
    					,case 
    						when emptxn.transactiontype = 'ReturnDeposit' then (dep.receiptno)::varchar(50)
    					 end as "receiptno"
    					,pat.patientcode as "hospitalno"
    					,pat.shortname as "patientname"
    					,coalesce(emptxn.outamount, 0) as "nettotal"
    					,emp.fullname as "user"
    					,emp.employeeid
    					,cntr.countername as "counter"
    					,emptxn.remarks
    				from txn_empcashtransaction as "emptxn"
    						inner join bil_txn_deposit dep on dep.depositid = emptxn.referenceno
    						inner join pat_patient pat on pat.patientid = dep.patientid
    						inner join emp_employee emp on emp.employeeid = emptxn.employeeid
    						inner join mst_paymentmodes pmodes on pmodes.paymentsubcategoryid = emptxn.paymentmodesubcategoryid
    						inner join bil_cfg_counter cntr on cntr.counterid = emptxn.counterid
    						where emptxn.transactiontype = 'ReturnDeposit'
    							and pmodes.paymentsubcategoryname != 'Deposit'
    							and emptxn.transactiondate::date between p_fromdate and p_todate
    				)
    			union
    			(select emptxn.transactiondate::date as "date"
    					,case 
    						when emptxn.transactiontype = 'CashDiscountGiven' then 'Cash Discount Given'
    					 end as "type"
    					,pmodes.paymentsubcategoryname as "paymentmode"
    					,case 
    						when emptxn.transactiontype = 'CashDiscountGiven' then concat ('SR','-',sett.settlementreceiptno)
    					 end as "receiptno"
    					,pat.patientcode as "hospitalno"
    					,pat.shortname as "patientname"
    					,coalesce(emptxn.outamount, 0) as "nettotal"
    					,emp.fullname as "user"
    					,emp.employeeid
    					,cntr.countername as "counter"
    					,emptxn.remarks
    				from txn_empcashtransaction as "emptxn"
    						inner join bil_txn_settlements sett on sett.settlementid = emptxn.referenceno
    						inner join pat_patient pat on pat.patientid = sett.patientid
    						inner join emp_employee emp on emp.employeeid = emptxn.employeeid
    						inner join mst_paymentmodes pmodes on pmodes.paymentsubcategoryid = emptxn.paymentmodesubcategoryid
    						inner join bil_cfg_counter cntr on cntr.counterid = emptxn.counterid
    						where emptxn.transactiontype = 'CashDiscountGiven'
    							and pmodes.paymentsubcategoryname != 'Deposit'
    							and emptxn.transactiondate::date between p_fromdate and p_todate
    				)
    				union
    			(select emptxn.transactiondate::date as "date"
    					,case 
    						when emptxn.transactiontype = 'CashDiscountReceived' then 'Cash Discount Received'
    					 end as "type"
    					,pmodes.paymentsubcategoryname as "paymentmode"
    					,case 
    						when emptxn.transactiontype = 'CashDiscountReceived' then concat ('SR','-',sett.settlementreceiptno)
    					 end as "receiptno"
    					,pat.patientcode as "hospitalno"
    					,pat.shortname as "patientname"
    					,coalesce(emptxn.inamount, 0) as "nettotal"
    					,emp.fullname as "user"
    					,emp.employeeid
    					,cntr.countername as "counter"
    					,emptxn.remarks
    				from txn_empcashtransaction as "emptxn"
    						inner join bil_txn_settlements sett on sett.settlementid = emptxn.referenceno
    						inner join pat_patient pat on pat.patientid = sett.patientid
    						inner join emp_employee emp on emp.employeeid = emptxn.employeeid
    						inner join mst_paymentmodes pmodes on pmodes.paymentsubcategoryid = emptxn.paymentmodesubcategoryid
    						inner join bil_cfg_counter cntr on cntr.counterid = emptxn.counterid
    						where emptxn.transactiontype = 'CashDiscountReceived'
    							and pmodes.paymentsubcategoryname != 'Deposit'
    							and emptxn.transactiondate::date between p_fromdate and p_todate
    				)
    				union
    			(select emptxn.transactiondate::date as "date"
    					,case 
    						when emptxn.transactiontype = 'MaternityAllowance' then 'Maternity Allowance'
    					 end as "type"
    					,pmodes.paymentsubcategoryname as "paymentmode"
    					,case 
    						when emptxn.transactiontype = 'MaternityAllowance' then (mat.patientpaymentid)::varchar(50)
    					 end as "receiptno"
    					,pat.patientcode as "hospitalno"
    					,pat.shortname as "patientname"
    					,coalesce(emptxn.outamount, 0) as "nettotal"
    					,emp.fullname as "user"
    					,emp.employeeid
    					,cntr.countername as "counter"
    					,emptxn.remarks
    				from txn_empcashtransaction as "emptxn"
    						inner join mat_txn_patientpayments mat on mat.patientpaymentid = emptxn.referenceno
    						inner join pat_patient pat on pat.patientid = mat.patientid
    						inner join emp_employee emp on emp.employeeid = emptxn.employeeid
    						inner join mst_paymentmodes pmodes on pmodes.paymentsubcategoryid = emptxn.paymentmodesubcategoryid
    						inner join bil_cfg_counter cntr on cntr.counterid = emptxn.counterid
    						where emptxn.transactiontype = 'MaternityAllowance'
    							and pmodes.paymentsubcategoryname != 'Deposit'
    							and emptxn.transactiondate::date between p_fromdate and p_todate
    				)
    				union
    			(select emptxn.transactiondate::date as "date"
    					,case 
    						when emptxn.transactiontype = 'MaternityAllowanceReturn' then 'Maternity Allowance Return'
    					 end as "type"
    					,pmodes.paymentsubcategoryname as "paymentmode"
    					,case 
    						when emptxn.transactiontype = 'MaternityAllowanceReturn' then (mat.patientpaymentid)::varchar(50)
    					 end as "receiptno"
    					,pat.patientcode as "hospitalno"
    					,pat.shortname as "patientname"
    					,coalesce(emptxn.inamount, 0) as "nettotal"
    					,emp.fullname as "user"
    					,emp.employeeid
    					,cntr.countername as "counter"
    					,emptxn.remarks
    				from txn_empcashtransaction as "emptxn"
    						inner join mat_txn_patientpayments mat on mat.patientpaymentid = emptxn.referenceno
    						inner join pat_patient pat on pat.patientid = mat.patientid
    						inner join emp_employee emp on emp.employeeid = emptxn.employeeid
    						inner join mst_paymentmodes pmodes on pmodes.paymentsubcategoryid = emptxn.paymentmodesubcategoryid
    						inner join bil_cfg_counter cntr on cntr.counterid = emptxn.counterid
    						where emptxn.transactiontype = 'MaternityAllowanceReturn'
    							and pmodes.paymentsubcategoryname != 'Deposit'
    							and emptxn.transactiondate::date between p_fromdate and p_todate
    				)
    			) as "tbl"
    		where 
    			(p_paymentmode is null or p_paymentmode = 'null' or tbl.paymentmode = p_paymentmode)
    			and (p_type is null or p_type = 'null' or tbl.type = p_type)
    			and (p_user is null or p_user = 0 or tbl.employeeid = p_user)
    		order by tbl.date desc;
        return next ref1;
    
    		open ref2 for select
    			paymentmodes,
    			coalesce(sum(case when transactiontype = 'CashSales' then nettotal end), 0.0) as "cashsales",
    			coalesce(sum(case when transactiontype = 'SalesReturn' then nettotal end), 0.0) as "returncashsales",
    			coalesce(sum(case when transactiontype = 'Deposit' then nettotal end), 0.0) as "depositreceived",
    			coalesce(sum(case when transactiontype = 'ReturnDeposit' then nettotal end), 0.0) as "depositrefund",
    			(coalesce(sum(case when transactiontype = 'CashDiscountGiven' then nettotal end), 0.0) - coalesce(sum(case when transactiontype = 'CashDiscountReceived' then nettotal end), 0.0)) as "settlementdiscount",
    			(coalesce(sum(case when transactiontype = 'MaternityAllowance' then nettotal end), 0.0) - coalesce(sum(case when transactiontype = 'MaternityAllowanceReturn' then nettotal end), 0.0)) as "otherpaymentsgiven",
    			coalesce(sum(case when transactiontype = 'CollectionFromReceivable' then nettotal end), 0.0) as "collectionfromreceivable",
    
    			--calculation for cash collection--
    			coalesce(sum(case when transactiontype = 'CashSales' then nettotal end), 0.0) - coalesce(sum(case when transactiontype = 'SalesReturn' then nettotal end), 0.0)
    			+ coalesce(sum(case when transactiontype = 'Deposit' then nettotal end), 0.0) - coalesce(sum(case when transactiontype = 'ReturnDeposit' then nettotal end), 0.0)
    			+ coalesce(sum(case when transactiontype = 'CollectionFromReceivable' then nettotal end), 0.0)
    			- (coalesce(sum(case when transactiontype = 'CashDiscountGiven' then nettotal end), 0.0) - coalesce(sum(case when transactiontype = 'CashDiscountReceived' then nettotal end), 0.0))
    			- (coalesce(sum(case when transactiontype = 'MaternityAllowance' then nettotal end), 0.0) - coalesce(sum(case when transactiontype = 'MaternityAllowanceReturn' then nettotal end), 0.0))
    			as "cashcollection"
    		from   
    			(select 
    					emptxn.transactiontype,
    					pmodes.paymentsubcategoryname as "paymentmodes",
    					case 
    						when emptxn.transactiontype in ('CashSales', 'Deposit', 'CollectionFromReceivable', 'MaternityAllowanceReturn', 'CashDiscountReceived')
    							then coalesce(sum(coalesce(emptxn.inamount,0)) - coalesce(sum(coalesce(emptxn.outamount,0)),0),0)
    						when emptxn.transactiontype in ('SalesReturn', 'CashDiscountGiven', 'MaternityAllowance','ReturnDeposit')
    							then sum(coalesce(emptxn.outamount,0))
    					end as "nettotal"					
    					from txn_empcashtransaction as "emptxn"
    					inner join mst_paymentmodes as "pmodes"
    					on pmodes.paymentsubcategoryid = emptxn.paymentmodesubcategoryid
    					inner join emp_employee as "emp"
    					on emp.employeeid = emptxn.employeeid
    					where emptxn.transactiontype != 'HandoverGiven'
    					and emptxn.transactiondate::date between p_fromdate and p_todate
    					and pmodes.paymentsubcategoryname != 'Deposit'
    					and (p_user is null or p_user = 0 or emp.employeeid = p_user)
    					group by emptxn.transactiontype, pmodes.paymentsubcategoryname
    			) as "txn"
    		group by paymentmodes;
        return next ref2;
    	end;
END;
$$ LANGUAGE plpgsql;