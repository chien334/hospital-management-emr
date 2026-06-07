CREATE OR REPLACE FUNCTION sp_inctv_bulkinsert_fractionitemsfrombilltxnitem_indaterange(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
BEGIN
    /*
     file: sp_inctv_bulkinsert_fractionitemsfrombilltxnitem_indaterange '2020-02-14','2020-02-14'
     description: 
     remarks:  
         * maindoctor=1 for assigned and is 0 for referral.
         * check for createdby and createdon value. 
    	 * we're excluding the fraction where RequestsedBy(ReferredBy) and AssignedToId are there in BillingTxnItem but those doctors don't have any configuration in incentive-profile
    
     revision needed on: 
        * we may need undo functionality of this feature.
     change history:
    s.no.    changedate/by						remarks
     1.      15feb'20/Sud						Initial Draft (Needs Revision)
     2.      15Mar'20/sud						added tdspercentage and tdsamount calculation in the query
    3.       4apr'20/Sud						Excluding Already Added BillingTransactionItem during Bill Sync.
    											earlier it was at BillingTransactionId level, now it's billingtransactionitemid
    4.       11june								tdspercentage from employee incentive info
    5.       17jul'20/Sud/Pratik				Updated for Group Distribution 
    6.       10Aug'20/sud						removed hardcoded date range from group distribution
    7.       17sept'20							Temporary solution to avoid Syncing Returned items
    											ToDate <= CURRENT_TIMESTAMP-5days or less.. if not then make that from here..
    8.       24Sept'20							returned items not excluded anymore, it will be handled by another 
    											storedprocedure as negative billing
    9.       2 july'2021  /pratik				Adding quantity to maintain partial return scenario from credit note
    10.		 2Jun'22 krishna					changed assignedtopercent to performerpercent, referredbypercent to 
    											prescriberpercent, providerid to performerid
    11.      23aug'22, DevN						> Added logic for incentive calculation after referral deduction. 
    											> Handled DivideByZero issue for TotalAmount = 0
    12.      17Oct'22, dev n					changed incentivereceiverid in referral section from prescriberid to referredbyid
    13.      14aug'22, Nirmala					Change BillItemPriceId to ServiceItemId
    14.		 22ndSept'23, krishna				add pricecategoryid as predicate to get pricecategory wise settings
    */
    begin
    	if (p_fromdate is not null and p_todate is not null)
    	then
    		insert into inctv_txn_incentivefractionitem (
    			invoicenoformatted
    			,transactiondate
    			,pricecategory
    			,billingtransactionid
    			,billingtransactionitemid
    			,patientid
    			,serviceitemid
    			,itemname
    			,totalbillamount
    			,incentivetype
    			,incentivereceiverid
    			,incentivereceivername
    			,finalincentivepercent
    			,incentiveamount
    			,initialincentivepercent
    			,ispaymentprocessed
    			,paymentinfoid
    			,createdby
    			,createdon
    			,modifiedby
    			,modifiedon
    			,isactive
    			,ismaindoctor
    			,tdspercentage
    			,tdsamount
    			,isreturntxn
    			,quantity
    			)
    		select
    			fyear.fiscalyearformatted || '-' || txn.invoicecode || cast(txn.invoiceno as varchar(20)) as "invoicenoformatted"
    			,txn.createdon as "transactiondate"
    			,sett.pricecategoryname as "pricecategory"
    			,txn.billingtransactionid
    			,txnitm.billingtransactionitemid
    			,txn.patientid
    			,sett.serviceitemid
    			,sett.itemname
    			,txnitm.totalamount as "totalbillamount"
    			,'prescriber' as incentivetype
    			,txnitm.prescriberid as "incentivereceiverid"
    			,sett.fullname as "incentivereceivername"
    			,sett.prescriberpercent as "finalincentivepercent"
    			,(
    				txnitm.totalamount - (txnitm.totalamount * coalesce((select  referrerpercent from inctv_map_employeebillitemsmap where serviceitemid =                                sett.serviceitemid and employeeid = txnitm.referredbyid limit 1), 0) / 100)) * coalesce(sett.prescriberpercent, 0) / 100 as "incentiveamount"
    			,case 
    				when txnitm.totalamount <> 0
    					then (((txnitm.totalamount -(txnitm.totalamount * coalesce((
    												select  referrerpercent
    												from inctv_map_employeebillitemsmap
    												where serviceitemid = sett.serviceitemid
    												and employeeid = txnitm.referredbyid limit 1), 0) / 100)) * coalesce(sett.prescriberpercent, 0) / 100) / txnitm.totalamount) * 100
    				else 0
    				end as "initialincentivepercent"
    			,0 as ispaymentprocessed
    			,null as paymentinfoid
    			,1 as createdby
    			,current_timestamp as createdon
    			,null as modifiedby
    			,null as modifiedon
    			,1 as isactive
    			,0 as ismaindoctor
    			,coalesce(sett.tdspercent, 0) as tdspercent
    			,(txnitm.totalamount * coalesce(sett.prescriberpercent, 0) / 100) * coalesce(sett.tdspercent, 0) / 100 as "tdsamount" -- tdsamount=incentiveamt*tdspercent/100
    			,0 as isreturntxn
    			,txnitm.quantity
    		-- ,txnitm.servicedepartmentid, txnitm.servicedepartmentname, txnitm.itemid, txnitm.subtotal, txnitm.discountamount,
    		-- pat.firstname+' '+pat.lastname 'PatientName'
    		from bil_txn_billingtransaction txn
    		inner join bil_txn_billingtransactionitems txnitm on txn.billingtransactionid = txnitm.billingtransactionid
    		inner join pat_patient pat on txn.patientid = pat.patientid
    		inner join bil_cfg_fiscalyears fyear on txn.fiscalyearid = fyear.fiscalyearid
    		inner join fn_inctv_getincentivesettings_normal() sett on txnitm.servicedepartmentid = sett.servicedepartmentid
    			and txnitm.serviceitemid = sett.serviceitemid
    			and txnitm.prescriberid = sett.employeeid
    			and txnitm.pricecategoryid = sett.pricecategoryid
    			and 1 = (
    				case 
    					when coalesce(sett.billingtypesapplicable, 'both') = 'both'
    						then 1
    					when sett.billingtypesapplicable = txnitm.billingtype
    						then 1
    					else 0
    					end
    				)
    		where (txn.createdon)::date between p_fromdate
    				and p_todate
    					--and coalesce(txnitm.returnstatus,0)= 0 -- not required anymore
    			and coalesce(sett.prescriberpercent, 0) != 0
    			and txnitm.billingtransactionitemid not in (
    				select distinct billingtransactionitemid
    				from inctv_txn_incentivefractionitem
    				where isreturntxn = 0
    				)
    		
    		union all
    		
    		select
    			fyear.fiscalyearformatted || '-' || txn.invoicecode || cast(txn.invoiceno as varchar(20)) as "invoicenoformatted"
    			,txn.createdon as "transactiondate"
    			,sett.pricecategoryname as "pricecategory"
    			,txn.billingtransactionid
    			,billingtransactionitemid
    			,txn.patientid
    			,sett.serviceitemid
    			,sett.itemname
    			,txnitm.totalamount as "totalbillamount"
    			,'performer' as incentivetype
    			,txnitm.performerid as "incentivereceiverid"
    			,sett.fullname as "incentivereceivername"
    			,sett.performerpercent as "finalincentivepercent"
    			,(
    				txnitm.totalamount - (txnitm.totalamount * coalesce((
    							select  referrerpercent
    							from inctv_map_employeebillitemsmap
    							where serviceitemid = sett.serviceitemid
    						    and employeeid = txnitm.referredbyid limit 1
    							), 0) / 100
    					)
    				) * coalesce(sett.performerpercent, 0) / 100 as "incentiveamount"
    			,case 
    				when txnitm.totalamount <> 0
    					then (((txnitm.totalamount - (txnitm.totalamount * coalesce((select  referrerpercent from inctv_map_employeebillitemsmap
    												 where serviceitemid = sett.serviceitemid and employeeid = txnitm.referredbyid limit 1 ), 0) / 100)) * coalesce(sett.performerpercent, 0) / 100) / txnitm.totalamount) * 100
    				else 0
    				end as "initialincentivepercent"
    			,0 as ispaymentprocessed
    			,null as paymentinfoid
    			,1 as createdby
    			,current_timestamp as createdon
    			,null as modifiedby
    			,null as modifiedon
    			,1 as isactive
    			,1 as ismaindoctor
    			,coalesce(sett.tdspercent, 0) as tdspercentage
    			,(txnitm.totalamount * coalesce(sett.performerpercent, 0) / 100) * coalesce(sett.tdspercent, 0) / 100 as "tdsamount" -- tdsamount=incentiveamt*tdspercent/100
    			,0 as isreturntxn
    			,txnitm.quantity
    		--, txnitm.servicedepartmentid, txnitm.servicedepartmentname, txnitm.itemid, txnitm.subtotal, txnitm.discountamount,
    		-- pat.firstname+' '+pat.lastname 'PatientName'
    		from bil_txn_billingtransaction txn
    		inner join bil_txn_billingtransactionitems txnitm on txn.billingtransactionid = txnitm.billingtransactionid
    		inner join pat_patient pat on txn.patientid = pat.patientid
    		inner join bil_cfg_fiscalyears fyear on txn.fiscalyearid = fyear.fiscalyearid
    		inner join fn_inctv_getincentivesettings_normal() sett on txnitm.servicedepartmentid = sett.servicedepartmentid
    			and txnitm.serviceitemid = sett.serviceitemid
    			and txnitm.performerid = sett.employeeid
    			and txnitm.pricecategoryid = sett.pricecategoryid
    			and 1 = (
    				case 
    					when coalesce(sett.billingtypesapplicable, 'both') = 'both'
    						then 1
    					when sett.billingtypesapplicable = txnitm.billingtype
    						then 1
    					else 0
    					end
    				)
    		where (txn.createdon)::date between p_fromdate
    				and p_todate
    			and coalesce(sett.performerpercent, 0) != 0
    			and txnitm.billingtransactionitemid not in (
    				select distinct billingtransactionitemid
    				from inctv_txn_incentivefractionitem
    				where isreturntxn = 0
    				) -- remove this condition once daily upload is enabled..
    		
    		union all
    		
    		select
    			fyear.fiscalyearformatted || '-' || txn.invoicecode || cast(txn.invoiceno as varchar(20)) as "invoicenoformatted"
    			,txn.createdon as "transactiondate"
    			,sett.pricecategoryname as "pricecategory"
    			,txn.billingtransactionid
    			,billingtransactionitemid
    			,txn.patientid
    			,sett.serviceitemid
    			,sett.itemname
    			,txnitm.totalamount as "totalbillamount"
    			,'referral' as incentivetype
    			,txnitm.referredbyid as "incentivereceiverid"
    			,sett.fullname as "incentivereceivername"
    			,sett.referrerpercent as "finalincentivepercent"
    			,txnitm.totalamount * coalesce(sett.referrerpercent, 0) / 100 as "incentiveamount"
    			,case 
    				when txnitm.totalamount <> 0
    					then ((txnitm.totalamount * coalesce(sett.referrerpercent, 0) / 100) / txnitm.totalamount) * 100
    				else 0
    				end as "initialincentivepercent"
    			,0 as ispaymentprocessed
    			,null as paymentinfoid
    			,1 as createdby
    			,current_timestamp as createdon
    			,null as modifiedby
    			,null as modifiedon
    			,1 as isactive
    			,1 as ismaindoctor
    			,coalesce(sett.tdspercent, 0) as tdspercentage
    			,(txnitm.totalamount * coalesce(sett.referrerpercent, 0) / 100) * coalesce(sett.tdspercent, 0) / 100 as "tdsamount" -- tdsamount=incentiveamt*tdspercent/100
    			,0 as isreturntxn
    			,txnitm.quantity
    		--, txnitm.servicedepartmentid, txnitm.servicedepartmentname, txnitm.itemid, txnitm.subtotal, txnitm.discountamount,
    		-- pat.firstname+' '+pat.lastname 'PatientName'
    		from bil_txn_billingtransaction txn
    		inner join bil_txn_billingtransactionitems txnitm on txn.billingtransactionid = txnitm.billingtransactionid
    		inner join pat_patient pat on txn.patientid = pat.patientid
    		inner join bil_cfg_fiscalyears fyear on txn.fiscalyearid = fyear.fiscalyearid
    		inner join fn_inctv_getincentivesettings_normal() sett on txnitm.servicedepartmentid = sett.servicedepartmentid
    			and txnitm.serviceitemid = sett.serviceitemid
    			and txnitm.referredbyid = sett.employeeid
    			and txnitm.pricecategoryid = sett.pricecategoryid
    			and 1 = (
    				case 
    					when coalesce(sett.billingtypesapplicable, 'both') = 'both'
    						then 1
    					when sett.billingtypesapplicable = txnitm.billingtype
    						then 1
    					else 0
    					end
    				)
    		where (txn.createdon)::date between p_fromdate
    				and p_todate
    			and coalesce(sett.referrerpercent, 0) != 0
    			and txnitm.billingtransactionitemid not in (
    				select distinct billingtransactionitemid
    				from inctv_txn_incentivefractionitem
    				where isreturntxn = 0
    				) -- remove this condition once daily upload is enabled..
    		
    		union all
    		
    		select
    			fyear.fiscalyearformatted || '-' || txn.invoicecode || cast(txn.invoiceno as varchar(20)) as "invoicenoformatted"
    			,txn.createdon as "transactiondate"
    			,sett.pricecategoryname as "pricecategory"
    			,txn.billingtransactionid
    			,billingtransactionitemid
    			,txn.patientid
    			,sett.serviceitemid
    			,sett.itemname
    			,txnitm.totalamount as "totalbillamount"
    			,'performer' as incentivetype
    			,
    			-- incentive goes to:  toemployeeid----
    			sett.toemployeeid as "incentivereceiverid"
    			,sett.toemployeename as "incentivereceivername"
    			,sett.distributionpercent as "finalincentivepercent"
    			,txnitm.totalamount * coalesce(sett.distributionpercent, 0) / 100 as "incentiveamount"
    			,case 
    				when txnitm.totalamount <> 0
    					then ((txnitm.totalamount * coalesce(sett.distributionpercent, 0) / 100) / txnitm.totalamount) * 100
    				else 0
    				end as "initialincentivepercent"
    			,0 as ispaymentprocessed
    			,null as paymentinfoid
    			,1 as createdby
    			,current_timestamp as createdon
    			,null as modifiedby
    			,null as modifiedon
    			,1 as isactive
    			,1 as ismaindoctor
    			,coalesce(sett.tdspercent, 0) as tdspercentage
    			,(txnitm.totalamount * coalesce(sett.distributionpercent, 0) / 100) * coalesce(sett.tdspercent, 0) / 100 as "tdsamount" -- tdsamount=incentiveamt*tdspercent/100
    			,0 as isreturntxn
    			,txnitm.quantity
    		from bil_txn_billingtransaction txn
    		inner join bil_txn_billingtransactionitems txnitm on txn.billingtransactionid = txnitm.billingtransactionid
    		inner join pat_patient pat on txn.patientid = pat.patientid
    		inner join bil_cfg_fiscalyears fyear on txn.fiscalyearid = fyear.fiscalyearid
    		inner join fn_inctv_getincentivesettings_groupdistribution() sett -- this gives us group distribution settings only.. 
    			--"fn_inctv_getincentivesettings" () sett
    			on txnitm.servicedepartmentid = sett.servicedepartmentid
    			and txnitm.serviceitemid = sett.serviceitemid
    			and txnitm.performerid = sett.fromemployeeid
    			and txnitm.pricecategoryid = sett.pricecategoryid
    			and 1 = (
    				case 
    					when coalesce(sett.billingtypesapplicable, 'both') = 'both'
    						then 1
    					when sett.billingtypesapplicable = txnitm.billingtype
    						then 1
    					else 0
    					end
    				)
    		where (txn.createdon)::date between p_fromdate
    				and p_todate -- sud:10aug'20-- this dates were hardcoded earlier.
    					-- AND COALESCE(txnItm.ReturnStatus,0)= 0 -- Not Required Anymore
    			AND COALESCE(sett.DistributionPercent, 0) != 0
    			AND txnItm.BillingTransactionItemId NOT IN (
    				SELECT DISTINCT BillingTransactionItemId
    				FROM INCTV_TXN_IncentiveFractionItem
    				WHERE IsReturnTxn = 0
    				); -- remove this condition once daily upload is enabled..
    	END IF; --end of IF.. 
    
    	--by default returning something so that we understand it has been executed..
    	OPEN ref1 FOR SELECT 'success' as "status";
        return next ref1;
    end; --end of sp--
END;
$$ LANGUAGE plpgsql;