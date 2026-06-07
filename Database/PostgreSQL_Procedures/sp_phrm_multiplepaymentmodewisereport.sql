CREATE OR REPLACE FUNCTION sp_phrm_multiplepaymentmodewisereport(
    p_fromdate DATE,
    p_todate DATE,
    p_paymentmode VARCHAR DEFAULT NULL,
    p_type VARCHAR DEFAULT NULL,
    p_user INT DEFAULT NULL,
    p_storeid INT DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
BEGIN
    begin
    	if p_paymentmode = 'All'
    			then
    			p_paymentmode := null;
    		end if;
    
    		if p_type = 'All'
    			then
    			p_type := null;
    		end if;
    	open ref1 for select *
    		from (
    			(select (emptxn.transactiondate)::date as "date"
    					,case 
    						when emptxn.transactiontype = 'CashSales' then 'Cash Sales'
    					 end as "type"
    					,pmodes.paymentsubcategoryname as "paymentmode"
    					,case 
    						when emptxn.transactiontype = 'CashSales' then concat ('PH','-',txn.invoiceprintid)
    					 end as "receiptno"
    					,pat.patientcode as "hospitalno"
    					,pat.shortname as "patientname"
    					,coalesce(emptxn.inamount, 0) as "nettotal"
    					--,coalesce(emptxn.outamount, 0) 'OutAmount'
    					--,coalesce(emptxn.inamount, 0) - coalesce(emptxn.outamount,0) 'NetTotal'
    					,emp.fullname as "user"
    					,emp.employeeid
    					,cntr.countername as "counter"
    					,emptxn.remarks
    					,txn.storeid
    				from phrm_employeecashtransaction emptxn
    						inner join phrm_txn_invoice txn on txn.invoiceid = emptxn.referenceno
    						inner join pat_patient pat on pat.patientid = txn.patientid
    						inner join emp_employee emp on emp.employeeid = emptxn.employeeid
    						inner join mst_paymentmodes pmodes on pmodes.paymentsubcategoryid = emptxn.paymentmodesubcategoryid
    						inner join phrm_mst_counter cntr on cntr.counterid = emptxn.counterid
    						where emptxn.transactiontype = 'CashSales'
    							and pmodes.paymentsubcategoryname != 'Deposit'
    							and (emptxn.transactiondate)::date between p_fromdate and p_todate
    				)
    	
    			union
    			(select (emptxn.transactiondate)::date as "date"
    					,case 
    						when emptxn.transactiontype = 'DepositAdd' then 'Deposit Received'
    					 end as "type"
    					,pmodes.paymentsubcategoryname as "paymentmode"
    					,case 
    						when emptxn.transactiontype = 'DepositAdd' then (dep.receiptno)::varchar
    					 end as "receiptno"
    					,pat.patientcode as "hospitalno"
    					,pat.shortname as "patientname"
    					,coalesce(emptxn.inamount, 0) as "nettotal"
    					--,coalesce(emptxn.outamount, 0) 'OutAmount'
    					--,coalesce(emptxn.inamount, 0) - coalesce(emptxn.outamount,0) 'NetTotal'
    					,emp.fullname as "user"
    					,emp.employeeid
    					,cntr.countername as "counter"
    					,emptxn.remarks
    					,dep.storeid
    				from phrm_employeecashtransaction emptxn
    						inner join phrm_deposit dep on dep.depositid = emptxn.referenceno
    						inner join pat_patient pat on pat.patientid = dep.patientid
    						inner join emp_employee emp on emp.employeeid = emptxn.employeeid
    						inner join mst_paymentmodes pmodes on pmodes.paymentsubcategoryid = emptxn.paymentmodesubcategoryid
    						inner join phrm_mst_counter cntr on cntr.counterid = emptxn.counterid
    						where emptxn.transactiontype = 'DepositAdd'
    							and pmodes.paymentsubcategoryname != 'Deposit'
    							and (emptxn.transactiondate)::date between p_fromdate and p_todate
    				)
    	
    			union
    			(select (emptxn.transactiondate)::date as "date"
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
    					--,coalesce(emptxn.outamount, 0) 'OutAmount'
    					--,coalesce(emptxn.inamount, 0) - coalesce(emptxn.outamount,0) 'NetTotal'
    					,emp.fullname as "user"
    					,emp.employeeid
    					,cntr.countername as "counter"
    					,emptxn.remarks
    					,sett.storeid
    				from phrm_employeecashtransaction emptxn
    						inner join phrm_txn_settlement sett on sett.settlementid = emptxn.referenceno
    						inner join pat_patient pat on pat.patientid = sett.patientid
    						inner join emp_employee emp on emp.employeeid = emptxn.employeeid
    						inner join mst_paymentmodes pmodes on pmodes.paymentsubcategoryid = emptxn.paymentmodesubcategoryid
    						inner join phrm_mst_counter cntr on cntr.counterid = emptxn.counterid
    						where emptxn.transactiontype = 'CollectionFromReceivable'
    							and pmodes.paymentsubcategoryname != 'Deposit'
    							and (emptxn.transactiondate)::date between p_fromdate and p_todate
    				)
    
    				union
    			(select (emptxn.transactiondate)::date as "date"
    					,case 
    						when emptxn.transactiontype = 'SalesReturn' then 'Cash Sales Return'
    					 end as "type"
    					,pmodes.paymentsubcategoryname as "paymentmode"
    					,case 
    						when emptxn.transactiontype = 'SalesReturn' then concat ('CR','-',ret.invoicereturnid)
    					 end as "receiptno"
    					,pat.patientcode as "hospitalno"
    					,pat.shortname as "patientname"
    					--,coalesce(emptxn.inamount, 0) 'InAmount'
    					,coalesce(emptxn.outamount, 0) as "nettotal"
    					--,coalesce(emptxn.inamount, 0) - coalesce(emptxn.outamount,0) 'NetTotal'
    					,emp.fullname as "user"
    					,emp.employeeid
    					,cntr.countername as "counter"
    					,emptxn.remarks
    					,ret.storeid
    				from phrm_employeecashtransaction emptxn
    						inner join phrm_txn_invoicereturn ret on ret.invoicereturnid = emptxn.referenceno
    						inner join pat_patient pat on pat.patientid = ret.patientid
    						inner join emp_employee emp on emp.employeeid = emptxn.employeeid
    						inner join mst_paymentmodes pmodes on pmodes.paymentsubcategoryid = emptxn.paymentmodesubcategoryid
    						inner join phrm_mst_counter cntr on cntr.counterid = emptxn.counterid
    						where emptxn.transactiontype = 'SalesReturn'
    							and pmodes.paymentsubcategoryname != 'Deposit'
    							and (emptxn.transactiondate)::date between p_fromdate and p_todate
    				)
    				union
    				(select (emptxn.transactiondate)::date as "date"
    					,case 
    						when emptxn.transactiontype = 'ReturnDeposit' then 'Deposit Refund'
    					 end as "type"
    					,pmodes.paymentsubcategoryname as "paymentmode"
    					,case 
    						when emptxn.transactiontype = 'ReturnDeposit' then (dep.receiptno)::varchar
    					 end as "receiptno"
    					,pat.patientcode as "hospitalno"
    					,pat.shortname as "patientname"
    					,coalesce(emptxn.outamount, 0) as "nettotal"
    					,emp.fullname as "user"
    					,emp.employeeid
    					,cntr.countername as "counter"
    					,emptxn.remarks
    					,dep.storeid
    				from phrm_employeecashtransaction emptxn
    						inner join phrm_deposit dep on dep.depositid = emptxn.referenceno
    						inner join pat_patient pat on pat.patientid = dep.patientid
    						inner join emp_employee emp on emp.employeeid = emptxn.employeeid
    						inner join mst_paymentmodes pmodes on pmodes.paymentsubcategoryid = emptxn.paymentmodesubcategoryid
    						inner join phrm_mst_counter cntr on cntr.counterid = emptxn.counterid
    						where emptxn.transactiontype = 'ReturnDeposit'
    							and pmodes.paymentsubcategoryname != 'Deposit'
    							and (emptxn.transactiondate)::date between p_fromdate and p_todate
    				)
    			union
    			(select (emptxn.transactiondate)::date as "date"
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
    					,sett.storeid
    				from phrm_employeecashtransaction emptxn
    						inner join phrm_txn_settlement sett on sett.settlementid = emptxn.referenceno
    						inner join pat_patient pat on pat.patientid = sett.patientid
    						inner join emp_employee emp on emp.employeeid = emptxn.employeeid
    						inner join mst_paymentmodes pmodes on pmodes.paymentsubcategoryid = emptxn.paymentmodesubcategoryid
    						inner join phrm_mst_counter cntr on cntr.counterid = emptxn.counterid
    						where emptxn.transactiontype = 'CashDiscountGiven'
    							and pmodes.paymentsubcategoryname != 'Deposit'
    							and (emptxn.transactiondate)::date between p_fromdate and p_todate
    				)
    				union
    			(select (emptxn.transactiondate)::date as "date"
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
    					,sett.storeid
    				from phrm_employeecashtransaction emptxn
    						inner join phrm_txn_settlement sett on sett.settlementid = emptxn.referenceno
    						inner join pat_patient pat on pat.patientid = sett.patientid
    						inner join emp_employee emp on emp.employeeid = emptxn.employeeid
    						inner join mst_paymentmodes pmodes on pmodes.paymentsubcategoryid = emptxn.paymentmodesubcategoryid
    						inner join phrm_mst_counter cntr on cntr.counterid = emptxn.counterid
    						where emptxn.transactiontype = 'CashDiscountReceived'
    							and pmodes.paymentsubcategoryname != 'Deposit'
    							and (emptxn.transactiondate)::date between p_fromdate and p_todate
    				)
    			) tbl
    		where 
    			(tbl.paymentmode = p_paymentmode or p_paymentmode is null)
    			and (tbl.type = p_type or p_type is null)
    			and (tbl.employeeid = p_user or p_user is null)
    			and (tbl.storeid=p_storeid or p_storeid is null)
    		order by tbl.date desc;
        return next ref1;
    
    		open ref2 for select
    			paymentmodes,
    			coalesce(cashsales,0) as "cashsales",
    			coalesce(salesreturn,0) as "returncashsales",
    			coalesce(depositadd,0) as "depositreceived",
    			coalesce(returndeposit,0) as "depositrefund",
    			(coalesce(cashdiscountgiven,0) - coalesce(cashdiscountreceived,0)) as "settlementdiscount",
    			
    			coalesce(collectionfromreceivable,0) as "collectionfromreceivable",
    
    			--calculation for cash collection--
    			coalesce(cashsales,0) - coalesce(salesreturn,0)
    			+ coalesce(depositadd,0) - coalesce(returndeposit,0)
    			+ coalesce(collectionfromreceivable,0)
    			- (coalesce(cashdiscountgiven,0) - coalesce(cashdiscountreceived,0))
    			as "cashcollection"
    		from   
    			(
            select
                "paymentmodes",
                coalesce(sum(case when "transactiontype" = 'CashSales' then "nettotal" else 0 end), 0) as "cashsales",
                coalesce(sum(case when "transactiontype" = 'SalesReturn' then "nettotal" else 0 end), 0) as "salesreturn",
                coalesce(sum(case when "transactiontype" = 'DepositAdd' then "nettotal" else 0 end), 0) as "depositadd",
                coalesce(sum(case when "transactiontype" = 'ReturnDeposit' then "nettotal" else 0 end), 0) as "returndeposit",
                coalesce(sum(case when "transactiontype" = 'CashDiscountGiven' then "nettotal" else 0 end), 0) as "cashdiscountgiven",
                coalesce(sum(case when "transactiontype" = 'CashDiscountReceived' then "nettotal" else 0 end), 0) as "cashdiscountreceived",
                coalesce(sum(case when "transactiontype" = 'CollectionFromReceivable' then "nettotal" else 0 end), 0) as "collectionfromreceivable"
            from (
                select 
    					emptxn.transactiontype,
    					pmodes.paymentsubcategoryname as "paymentmodes",
    					case 
    						when emptxn.transactiontype in ('CashSales', 'DepositAdd', 'CollectionFromReceivable', 'CashDiscountReceived')
    							then coalesce(sum(coalesce(emptxn.inamount,0)) - coalesce(sum(coalesce(emptxn.outamount,0)),0),0)
    						when emptxn.transactiontype in ('SalesReturn', 'CashDiscountGiven','ReturnDeposit')
    							then sum(coalesce(emptxn.outamount,0))
    					end as "nettotal"					
    					from phrm_employeecashtransaction emptxn
    					inner join mst_paymentmodes pmodes
    					on pmodes.paymentsubcategoryid = emptxn.paymentmodesubcategoryid
    					inner join emp_employee emp
    					on emp.employeeid = emptxn.employeeid
    					inner join phrm_txn_invoice inv on emptxn.referenceno=inv.invoiceid
    					where (emptxn.transactiondate)::date between p_fromdate and p_todate
    					and pmodes.paymentsubcategoryname != 'Deposit'
    					and (emp.employeeid = p_user or p_user is null)
    					and (inv.storeid=p_storeid or p_storeid is null)
    					group by emptxn.transactiontype, pmodes.paymentsubcategoryname
    			
            ) txn
            group by "paymentmodes"
        ) paymentmodereportsummary;
        return next ref2;
    	end;
END;
$$ LANGUAGE plpgsql;