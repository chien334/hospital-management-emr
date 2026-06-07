CREATE OR REPLACE FUNCTION sp_acc_gettransactiondates(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_hospitalid INT DEFAULT NULL,
    p_sectionid INT DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
    ref3 refcursor := 'cursor3';
    ref4 refcursor := 'cursor4';
    ref5 refcursor := 'cursor5';
BEGIN
    DROP TABLE IF EXISTS v_rules;
    CREATE TEMP TABLE v_rules (
        GroupMappingId INT
		,Description VARCHAR(200)
		,TransferRuleId INT
    );
    /************************************************************************
    	sp_acc_gettransactiondates '2023-06-16', '2023-07-1',1,1
    	s.no.    updatedby/date                        remarks
    	1.      vikas:25th sep 2020				changed table for consumptions transactions from ward_inv_consumption to ward_inv_transaction
    	2.      vikas:30 sep 2020				transaction dates mismatched and some other bugs correction from all tables.
    	3.      nagesh:01 oct 2020              stockmanag out record date logic changed . stock manageout only once in year on fiscal year end date and whole year data will show fiscal year enddate as transaction date
    	4.		nagesh:25 dec 2020				credit bill date gets wrong. because here we taken createdon from item table but correct from transaction table
    	5.		nageshbb/sanjit sir: 13july2021 updated after pharmacy, billing, inventory changes done in accounting 
    	6.		bikash : 31stjan2022			added transcation date of credit settlement (creditbillpaid)
    	7.		bikash : 8thfeb2022				added transcation date of discount return when bill (either cash or credit) is returned. (discountreturn)
    	8.		bikash : 10thfeb2022			in "credit bill return" condition logic changed to  bill status = "unpaid" and "paid" on "cash bill return"
    	9.      dev narayan 24th may 2022       added settlement table in pharmacy section
    	10.     dev narayan 27th may 2022       added phrm stock adjustment table in pharamcy section
    	11.     dev narayan 3 june 2022         changed sp for inv fixed assets.
    	12.     devn/19th may 23                deposittype column of billing deposit table is changed to transactiontype.
    	13.     devn/25th june 23               removed transactiontype filter for transactiondate as we are using different set of transactiontypes now.
    	14.     devn/ 4th july 23               added transactiondate for schmerefund
    	15.     devn/7th, aug 23'               Added transfer rule filter to get transactiondate for only active rules.
    	16.     DevN/15th, Oct 23'              separate inventory consumption and dispatch in separate rules.
    
    	*************************************************************************/
    begin
    	-- check rules are mapped or not with transaction types
    	
    
    	insert into v_rules (
    		groupmappingid
    		,description
    		,transferruleid
    		)
    	select "groupmappingid"
    		,"description"
    		,"transferruleid"
    	from (
    		select gm.groupmappingid
    			,gm.description
    			,transferruleid
    		from acc_mst_groupmapping gm
    		--join acc_mst_mappingdetail mp on gm.groupmappingid = mp.groupmappingid
    		join acc_mst_hospital_transferrules_mapping r on gm.groupmappingid = r.transferruleid
    		where r.isactive = 1
    		group by gm.groupmappingid
    			,gm.description
    			,transferruleid
    		) x;
    
    	if (
    			p_fromdate is not null
    			and p_todate is not null
    			and p_hospitalid is not null
    			and p_sectionid is not null
    			) --and p_fromdate > '2022-01-14' and p_todate > '2022-01-14') 
    	then
    		if (p_sectionid = 1) -- inventory section 
    		then
    			--table1: goodreceipt
    			open ref1 for select (gr.goodsreceiptdate)::date as "transactiondate"
    			from inv_txn_goodsreceipt gr
    			where (
    					coalesce(gr.istransferredtoacc,0) = 0
    					)
    				and (
    					(gr.goodsreceiptdate)::date between (p_fromdate)::date
    						and (p_todate)::date
    					)
    				and gr.iscancel != 1 --excluded cancel gr	
    				and (
    					(
    						select count("description")
    						from v_rules
    						where "description" = 'INV_Purchase'
    						) > 0
    					)
    				
    			union
    			
    			--table2: writeoffitems
    			select (wr.createdon)::date as "transactiondate"
    			from inv_txn_writeoffitems wr
    			where (
    					coalesce(istransferredtoacc,0) = 0
    					)
    				and (
    					(createdon)::date between (p_fromdate)::date
    						and (p_todate)::date
    					)
    				and (
    					(
    						select count("description")
    						from v_rules
    						where "description" = 'INV_WriteOff'
    						) > 0
    					)
    			union
    			
    			--table3: returntovendor
    			select (rv.createdon)::date as "transactiondate"
    			from inv_txn_returntovendor rv
    			where (
    					coalesce(rv.istransferredtoacc,0) = 0
    					)
    				and (
    					(rv.returndate)::date between (p_fromdate)::date
    						and (p_todate)::date
    					)
    				and (
    					(
    						select count("description")
    						from v_rules
    						where "description" = 'INV_PurchaseReturn'
    						) > 0
    					)
    			
    			union
    			
    			--table4: dispatchtodept			 
    			select (stktxn.transactiondate)::date as "transactiondate"
    			from inv_txn_stocktransaction stktxn
    			join inv_mst_item itm on stktxn.itemid = itm.itemid
    			where (
    					coalesce(stktxn.istransferredtoacc,0) = 0
    					)
    				and stktxn.transactiontype in (
    					'dispatched-item-from'
    					,'returned-item-from'
    					)
    				and coalesce(itm.isfixedassets,0) = 0
    				and (
    					(stktxn.transactiondate)::date between (p_fromdate)::date
    						and (p_todate)::date
    					)
    				and (
    					(
    						select count("description")
    						from v_rules
    						where "description" = 'INV_ConsumableDispatch'
    						or "description" = 'INV_ConsumableDispatchReturn'
    						) > 0
    					)
    			union
    			
    			-- table 5 :invdeptconsumedgoods
    			select (stktxn.transactiondate)::date as "transactiondate"
    			from inv_txn_stocktransaction stktxn
    			join inv_mst_item itm on stktxn.itemid = itm.itemid
    			where (
    					coalesce(stktxn.istransferredtoacc,0) = 0
    					)
    				and stktxn.transactiontype = 'consumption-items'
    				and itm.itemtype = 'consumables'
    				and (
    					(stktxn.transactiondate)::date between (p_fromdate)::date
    						and (p_todate)::date
    					)
    				and (
    					(
    						select count("description")
    						from v_rules
    						where "description" = 'INV_Consumption'
    						) > 0
    					)
    			
    			union
    			
    			-- table 6 :invstockmanageout	
    			select x.transactiondate
    			from (
    				select (stktxn.transactiondate)::date as "transactiondate"
    				from inv_txn_stocktransaction stktxn
    				join inv_mst_item itm on stktxn.itemid = itm.itemid
    				join inv_mst_itemsubcategory sb on itm.subcategoryid = sb.subcategoryid
    				where (
    						coalesce(stktxn.istransferredtoacc,0) = 0
    						)
    					and stktxn.transactiontype in (
    						'fy-managed-item'
    						,'stock-managed-item'
    						)
    					and (
    						stktxn.outqty > 0
    						or stktxn.inqty > 0
    						)
    					and ((stktxn.transactiondate)::date between (p_fromdate)::date
    						and (p_todate)::date)
    					--and itm.itemtype='consumables'
    				and (
    					(
    						select count("description")
    						from v_rules
    						where "description" = 'INV_StockManageIn'
    						or "description" = 'INV_StockManageOut'
    						) > 0
    					)
    				) as x;
        return next ref1;
    
    		end if;
    
    		if (p_sectionid = 2) -- billing section
    		then
    			if (
    					(
    						select  (parametervalue)::boolean
    						from core_cfg_parameters
    						where parametergroupname = 'accounting'
    							and parametername = 'GetBillingFromSyncTable' limit 1
    						) = 1
    					)
    			then
    				open ref2 for select (transactiondate)::date as "transactiondate"
    				from bil_sync_billingaccounting
    				where coalesce(istransferedtoacc,0) = 0
    					and (transactiondate)::date between (p_fromdate)::date
    						and (p_todate)::date;
        return next ref2;
    			
    			else
    			
    				--cash bill--
    				open ref3 for select (txn.createdon)::date as "transactiondate"
    				from bil_txn_billingtransactionitems itm
    					,bil_txn_billingtransaction txn
    				where txn.billingtransactionid = itm.billingtransactionid
    					and (txn.createdon)::date between (p_fromdate)::date
    						and (p_todate)::date
    					and itm.billingtransactionid is not null
    					and (
    						txn.paymentmode = 'cash'
    						or txn.paymentmode = 'card'
    						or txn.paymentmode = 'cheque'
    						)
    					and coalesce(itm.iscashbillsync, 0) = 0
    					and (
    						(
    							select count("description")
    							from v_rules
    							where "description" = 'BIL_Income_Voucher'
    							) > 0
    						)
    
    				
    				union
    				
    				--credit bill--
    				select (txn.createdon)::date as "transactiondate"
    				from bil_txn_billingtransactionitems itm
    					,bil_txn_billingtransaction txn
    				where txn.billingtransactionid = itm.billingtransactionid
    					and (txn.createdon)::date between (p_fromdate)::date
    						and (p_todate)::date
    					and itm.billingtransactionid is not null
    					and txn.paymentmode = 'credit'
    					and coalesce(itm.iscreditbillsync, 0) = 0
    					and (
    						(
    							select count("description")
    							from v_rules
    							where "description" = 'BIL_Income_Voucher'
    							) > 0
    						)
    				
    				union
    				
    				--cash bill return--
    				select (txn.createdon)::date as "transactiondate"
    				from bil_txn_invoicereturnitems itm
    					,bil_txn_invoicereturn txn
    				where txn.billreturnid = itm.billreturnid
    					and (txn.createdon)::date between (p_fromdate)::date
    						and (p_todate)::date
    							--and  ( txn.paymentmode='cash' or txn.paymentmode='card' or txn.paymentmode='cheque') 
    					and coalesce(itm.iscashbillsynctoacc, 0) = 0
    					and txn.billstatus = 'paid'
    					and (
    						(
    							select count("description")
    							from v_rules
    							where "description" = 'BIL_Income_Voucher'
    							) > 0
    						)
    				
    				union
    				
    				--creditbillreturn--
    				select (txn.createdon)::date as "transactiondate"
    				from bil_txn_invoicereturnitems itm
    					,bil_txn_invoicereturn txn
    				where txn.billreturnid = itm.billreturnid
    					and (txn.createdon)::date between (p_fromdate)::date
    						and (p_todate)::date
    					and txn.billstatus = 'unpaid'
    					and coalesce(itm.iscreditbillsynctoacc, 0) = 0 -- include only not-synced data for credit return case--
    					and (
    						(
    							select count("description")
    							from v_rules
    							where "description" = 'BIL_Income_Voucher'
    							) > 0
    						)
    				
    				union
    				
    				--deposit add--
    				select (createdon)::date as "transactiondate"
    				from bil_txn_deposit
    				where (createdon)::date between (p_fromdate)::date
    						and (p_todate)::date
    					and transactiontype = 'Deposit'
    					and coalesce(isdepositsync, 0) = 0
    					and modulename = 'Billing'
    					and (
    						(
    							select count("description")
    							from v_rules
    							where "description" = 'BIL_Income_Voucher'
    							) > 0
    						)
    				
    				union
    				
    				--deposit return/deduct--
    				select (createdon)::date as "transactiondate"
    				from bil_txn_deposit
    				where (createdon)::date between (p_fromdate)::date
    						and (p_todate)::date
    					and transactiontype in (
    						'ReturnDeposit'
    						,'depositdeduct'
    						)
    					and coalesce(isdepositsync, 0) = 0
    					and modulename = 'Billing'
    					and (
    						(
    							select count("description")
    							from v_rules
    							where "description" = 'BIL_Income_Voucher'
    							) > 0
    						)
    				
    				union
    				
    				select (settl.createdon)::date as "transactiondate"
    				from bil_txn_settlements settl
    				where (settl.createdon)::date between (p_fromdate)::date
    						and (p_todate)::date
    					and coalesce(settl.issynctoacc, 0) = 0
    					and coalesce(settl.discountreturnamount, 0) = 0 -- not including discount return case
    				    and modulename = 'Billing'
    					and (
    						(
    							select count("description")
    							from v_rules
    							where "description" = 'BIL_Income_Voucher'
    							) > 0
    						)
    
    				union
    				
    				select (settl.createdon)::date as "transactiondate"
    				from bil_txn_settlements settl
    				where (settl.createdon)::date between (p_fromdate)::date
    						and (p_todate)::date
    					and coalesce(settl.issynctoacc, 0) = 0
    					and coalesce(settl.discountreturnamount, 0) != 0 -- only taking discount return case
    					and modulename = 'Billing'
    					and (
    						(
    							select count("description")
    							from v_rules
    							where "description" = 'BIL_Income_Voucher'
    							) > 0
    						)
    				union
    
    				--scheme refund
    				select (refund.createdon)::date as "transactiondate"
    				from bil_txn_schemerefund refund
    				where (refund.createdon)::date between (p_fromdate)::date
    				and (p_todate)::date
    				and coalesce(refund.istransferredtoacc,0) = 0
    					and (
    						(
    							select count("description")
    							from v_rules
    							where "description" = 'BIL_Income_Voucher'
    							) > 0
    						);
        return next ref3;
    			end if;
    		end if;
    
    		if (p_sectionid = 3) -- pharmacy section			
    		then
    			--table1: cashinvoice
    			open ref4 for select (inv.createon)::date as "transactiondate"
    			from phrm_txn_invoice inv
    			where coalesce(inv.istransferredtoacc,0) = 0
    				and (inv.createon)::date between (p_fromdate)::date
    					and (p_todate)::date	
    					and (
    					(
    						select count("description")
    						from v_rules
    						where "description" = 'PHRM_Income_Voucher'
    						) > 0
    					)
    
    			
    			union
    			
    			--table3: cashinvoicereturn
    			select (createdon)::date as "transactiondate"
    			from phrm_txn_invoicereturn invret
    			where coalesce(invret.istransferredtoacc,0) = 0
    				and (createdon)::date between (p_fromdate)::date
    					and (p_todate)::date
    					and (
    					(
    						select count("description")
    						from v_rules
    						where "description" = 'PHRM_Income_Voucher'
    						) > 0
    					)
    
    			
    			union
    			
    			--table4: goodsreceipt
    			select (createdon)::date as "transactiondate"
    			from phrm_goodsreceipt gr
    			where coalesce(gr.istransferredtoacc,0) = 0
    				and gr.iscancel = 0
    				and (createdon)::date between (p_fromdate)::date
    					and (p_todate)::date
    					and (
    					(
    						select count("description")
    						from v_rules
    						where "description" = 'PHRM_Purchase'
    						) > 0
    					)
    			
    			union
    			
    			--table5: writeoff
    			select (createdon)::date as "transactiondate"
    			from phrm_writeoff wroff
    			where coalesce(wroff.istransferredtoacc,0) = 0
    				and (createdon)::date between (p_fromdate)::date
    					and (p_todate)::date
    					and (
    					(
    						select count("description")
    						from v_rules
    						where "description" = 'PHRM_WriteOff'
    						) > 0
    					)
    
    			union
    			--table6: dispatchtodept && dispatchtodeptret
    			select (stocktxn.transactiondate)::date as "transactiondate" 
    			from phrm_txn_stocktransaction stocktxn 
    			where coalesce(stocktxn.istransferedtoacc,0) = 0 
    			and  (stocktxn.transactiondate)::date between (p_fromdate)::date and (p_todate)::date 
    			and stocktxn.transactiontype in (
    					'dispensary-dispatched-item'
    					,'transfer-item','dispatched-item'
    			)
    			and (
    			(
    				select count("description")
    				from v_rules
    				where "description" = 'PHRM_ConsumableDispatch'
    				or "description" = 'PHRM_ConsumableDispatchReturn'
    				) > 0
    			)
    			
    			union
    			
    			--table7 : settlement 
    			select (settlementdate)::date as "transactiondate"
    			from bil_txn_settlements sett
    			where coalesce(sett.issynctoacc, 0) = 0
    				and (settlementdate)::date between (p_fromdate)::date
    					and (p_todate)::date
    					and modulename = 'Dispensary'
    					and (
    					(
    						select count("description")
    						from v_rules
    						where "description" = 'PHRM_Income_Voucher'
    						) > 0
    					)
    			
    			union
    			
    			--table7 : return to supplier 
    			select (returndate)::date as "transactiondate"
    			from phrm_returntosupplier ret
    			where coalesce(ret.istransferredtoacc, 0) = 0
    				and (returndate)::date between (p_fromdate)::date
    					and (p_todate)::date
    					and (
    					(
    						select count("description")
    						from v_rules
    						where "description" = 'PHRM_PurchaseReturn'
    						) > 0
    					)
    			
    			union
    			
    			--table8 : phrm stock adjustment
    			select (transactiondate)::date as "transactiondate"
    			from phrm_txn_stocktransaction
    			where transactiontype = 'stock-managed-item'
    				and coalesce(istransferedtoacc, 0) = 0
    				and (transactiondate)::date between (p_fromdate)::date
    					and (p_todate)::date
    					and (
    					(
    						select count("description")
    						from v_rules
    						where "description" = 'PHRM_StockManageIn'
    						or "description" = 'PHRM_StockManageOut'
    						) > 0
    					)
    			
    			union
    			
    			--deposit add--
    			select (createdon)::date as "transactiondate"
    			from bil_txn_deposit
    			where (createdon)::date between (p_fromdate)::date
    					and (p_todate)::date
    				and transactiontype in (
    					'Deposit'
    					,'ReturnDeposit'
    					)
    				and coalesce(isdepositsync, 0) = 0
    				and modulename = 'Pharmacy'
    					and (
    					(
    						select count("description")
    						from v_rules
    						where "description" = 'PHRM_Income_Voucher'
    						) > 0
    					);
        return next ref4;
    		end if;
    
    		if (p_sectionid = 5) -- incetives section
    		then
    			open ref5 for select (transactiondate)::date as "transactiondate"
    			from inctv_txn_incentivefractionitem outertbl
    			where (outertbl.transactiondate)::date between (p_fromdate)::date
    					and (p_todate)::date
    				and coalesce(istransfertoacc, 0) = 0
    				and coalesce(outertbl.isactive, 0) = 1
    				and (
    					(
    						select count("description")
    						from v_rules
    						where "description" = 'ConsultantIncentive'
    						) > 0
    					)
    			group by (transactiondate)::date;
        return next ref5;
    		end if;
    	end if;
    end;
END;
$$ LANGUAGE plpgsql;