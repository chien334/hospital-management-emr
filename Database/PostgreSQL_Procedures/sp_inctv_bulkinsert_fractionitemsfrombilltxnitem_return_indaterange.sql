CREATE OR REPLACE FUNCTION sp_inctv_bulkinsert_fractionitemsfrombilltxnitem_return_indaterange(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
BEGIN
    /*  
     file: sp_inctv_bulkinsert_fractionitemsfrombilltxnitem_return_indaterange '2020-02-14','2020-02-14'  
     description: to insert into negative amount for invoice return cases.  
               -- negative amount for:  totalbillamount, incentiveamount and tds  
         -- incentivepercent will remain same  
     remarks:    
         * maindoctor=1 for assigned and is 0 for referral.  
         * check for createdby and createdon value.   
      * we're excluding the fraction where RequestsedBy(ReferredBy) and AssignedToId are there in BillingTxnItem but those doctors don't have any configuration in incentive-profile  
      
     revision needed on:   
        * we may need undo functionality of this feature.  
     change history:  
     s.no.    changedate/by				remarks  
    1.        24sept'20					This handles only Returned Items.  
    2.        2 July'2021/pratik		adding quantity to maintain partial return scenario from credit note  
    3.        sud/krishna:23feb'22		Insert/check data from BillReturnItemId column of fraction 
    									table to handle multiple return of same invoice item(Wecare issue)  
    4.        2Jun'22, krishna   
    5.	      5thjul'22,Krishna			Changed assigned to performer, referral to prescriber and added referral 
    6.        23Aug'22, devn			> added logic to insert into referrerdistribution and calculation as well. 
    									> added value in quantity field 
    									> handled dividebyzero issue for totalamount = 0
    7.        14aug'23,Nirmala			Change BillItemPriceId To ServiceItemId
    8.		  22ndSept'23, krishna		add pricecategory as predicate to fetch pricecategory wise settings
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
    			,quantity
    			,isreturntxn
    			,billreturnitemid
    			)
    		--section: 1-- start: for referral incentive (group distribnution not required for referral)----------
    		select
    			fyear.fiscalyearformatted || '-' || rettxn.invoicecode || cast(rettxn.refinvoicenum as varchar(20)) as "invoicenoformatted"
    			,rettxn.createdon as "transactiondate"
    			,sett.pricecategoryname as "pricecategory"
    			,rettxn.billingtransactionid
    			,retitm.billingtransactionitemid
    			,rettxn.patientid
    			,sett.serviceitemid
    			,sett.itemname
    			,- retitm.rettotalamount as "totalbillamount"
    			,'prescriber' as incentivetype
    			,retitm.prescriberid as "incentivereceiverid"
    			,sett.fullname as "incentivereceivername"
    			,sett.prescriberpercent as "incentivepercent"
    			,- (
    				retitm.rettotalamount - (
    					retitm.rettotalamount * coalesce((
    							select  referrerpercent
    							from inctv_map_employeebillitemsmap
    							where serviceitemid = sett.serviceitemid
    								and employeeid = txnitem.referredbyid limit 1
    							), 0) / 100
    					)
    				) * coalesce(sett.prescriberpercent, 0) / 100 as "incentiveamount"
    			,case 
    				when retitm.rettotalamount <> 0
    					then (((retitm.rettotalamount - (retitm.rettotalamount * coalesce((select  referrerpercent from inctv_map_employeebillitemsmap where                                         serviceitemid = sett.serviceitemid and employeeid = txnitem.referredbyid limit 1), 0) / 100)) * coalesce(sett.prescriberpercent, 0) / 100) / retitm.rettotalamount) * 100
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
    			,- (retitm.rettotalamount * coalesce(sett.prescriberpercent, 0) / 100) * coalesce(sett.tdspercent, 0) / 100 as "tdsamount" -- tdsamount=incentiveamt*tdspercent/100
    			,retitm.retquantity
    			,1 as isreturntxn
    			,retitm.billreturnitemid
    		from bil_txn_invoicereturn rettxn
    		inner join bil_txn_invoicereturnitems retitm
    			--on rettxn.billingtransactionid=retitm.billingtransactionid
    			--sud/krishna:23feb'22: BugFix (When more than one item returned from same bill then it's giving one item multiple times)
    			on rettxn.billreturnid = retitm.billreturnid
    		inner join bil_txn_billingtransactionitems txnitem on retitm.billingtransactionitemid = txnitem.billingtransactionitemid
    		inner join pat_patient pat on rettxn.patientid = pat.patientid
    		inner join bil_cfg_fiscalyears fyear on rettxn.fiscalyearid = fyear.fiscalyearid
    		inner join fn_inctv_getincentivesettings_normal() sett on retitm.servicedepartmentid = sett.servicedepartmentid
    			and retitm.serviceitemid = sett.serviceitemid
    			and retitm.prescriberid = sett.employeeid
    			and retitm.pricecategoryid = sett.pricecategoryid
    			and 1 = (
    				case 
    					when coalesce(sett.billingtypesapplicable, 'both') = 'both'
    						then 1
    					when sett.billingtypesapplicable = retitm.billingtype
    						then 1
    					else 0
    					end
    				)
    		where (rettxn.createdon)::date between p_fromdate
    				and p_todate
    			and coalesce(sett.prescriberpercent, 0) != 0
    			--and retitm.billingtransactionitemid  not in 
    			--  (select distinct billingtransactionitemid  from inctv_txn_incentivefractionitem  where isreturntxn=1) 
    			and retitm.billreturnitemid not in (
    				select distinct billreturnitemid
    				from inctv_txn_incentivefractionitem
    				where billreturnitemid is not null
    					and isreturntxn = 1
    				)
    		--section: 1-- end: for referral incentive (group distribnution not required for referral)----------
    		
    		union all
    		
    		select
    			fyear.fiscalyearformatted || '-' || rettxn.invoicecode || cast(rettxn.refinvoicenum as varchar(20)) as "invoicenoformatted"
    			,rettxn.createdon as "transactiondate"
    			,sett.pricecategoryname as "pricecategory"
    			,rettxn.billingtransactionid
    			,retitm.billingtransactionitemid
    			,rettxn.patientid
    			,sett.serviceitemid
    			,sett.itemname
    			,- retitm.rettotalamount as "totalbillamount"
    			,'performer' as incentivetype
    			,retitm.performerid as "incentivereceiverid"
    			,sett.fullname as "incentivereceivername"
    			,sett.performerpercent as "incentivepercent"
    			,-(retitm.rettotalamount -(retitm.rettotalamount * coalesce((select  referrerpercent from inctv_map_employeebillitemsmap 
    				                      where serviceitemid = sett.serviceitemid and employeeid = txnitem.referredbyid limit 1), 0) / 100)) * coalesce(sett.performerpercent,0) /100 as "incentiveamount"
    			,case 
    				when retitm.rettotalamount <> 0
    					then (((retitm.rettotalamount -(retitm.rettotalamount * coalesce((select  referrerpercent from inctv_map_employeebillitemsmap
    												   where serviceitemid = sett.serviceitemid and employeeid = txnitem.referredbyid limit 1), 0) / 100)) * coalesce(sett.performerpercent, 0) / 100) / retitm.rettotalamount) * 100
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
    			,- (retitm.rettotalamount * coalesce(sett.performerpercent, 0) / 100) * coalesce(sett.tdspercent, 0) / 100 as "tdsamount" -- tdsamount=incentiveamt*tdspercent/100
    			,retitm.retquantity
    			,1 as isreturntxn
    			,retitm.billreturnitemid
    		from bil_txn_invoicereturn rettxn
    		inner join bil_txn_invoicereturnitems retitm on rettxn.billreturnid = retitm.billreturnid
    		--on rettxn.billingtransactionid=retitm.billingtransactionid
    		--sud/krishna:23feb'22: BugFix (When more than one item returned from same bill then it's giving one item multiple times)
    		inner join bil_txn_billingtransactionitems txnitem on retitm.billingtransactionitemid = txnitem.billingtransactionitemid
    		inner join pat_patient pat on rettxn.patientid = pat.patientid
    		inner join bil_cfg_fiscalyears fyear on rettxn.fiscalyearid = fyear.fiscalyearid
    		inner join fn_inctv_getincentivesettings_normal() sett on retitm.servicedepartmentid = sett.servicedepartmentid
    			and retitm.serviceitemid = sett.serviceitemid
    			and retitm.performerid = sett.employeeid
    			and retitm.pricecategoryid = sett.pricecategoryid
    			and 1 = (
    				case 
    					when coalesce(sett.billingtypesapplicable, 'both') = 'both'
    						then 1
    					when sett.billingtypesapplicable = retitm.billingtype
    						then 1
    					else 0
    					end
    				)
    		where (rettxn.createdon)::date between p_fromdate
    				and p_todate
    			and coalesce(sett.performerpercent, 0) != 0
    			--and retitm.billingtransactionitemid not in 
    			--    (select distinct billingtransactionitemid from inctv_txn_incentivefractionitem  where isreturntxn=1) 
    			and retitm.billreturnitemid not in (
    				select distinct billreturnitemid
    				from inctv_txn_incentivefractionitem
    				where billreturnitemid is not null
    					and isreturntxn = 1
    				)
    		
    		union all
    		
    		--section: 3-- start: for referral incentive----------
    		select
    			fyear.fiscalyearformatted || '-' || rettxn.invoicecode || cast(rettxn.refinvoicenum as varchar(20)) as "invoicenoformatted"
    			,rettxn.createdon as "transactiondate"
    			,sett.pricecategoryname as "pricecategory"
    			,rettxn.billingtransactionid
    			,retitm.billingtransactionitemid
    			,rettxn.patientid
    			,sett.serviceitemid
    			,sett.itemname
    			,- retitm.rettotalamount as "totalbillamount"
    			,'referral' as incentivetype
    			,txnitem.referredbyid as "incentivereceiverid"
    			,sett.fullname as "incentivereceivername"
    			,sett.referrerpercent as "incentivepercent"
    			,- (retitm.rettotalamount * coalesce(sett.referrerpercent, 0) / 100) as "incentiveamount"
    			,case 
    				when retitm.rettotalamount <> 0
    					then (((retitm.rettotalamount * coalesce(sett.referrerpercent, 0) / 100) / retitm.rettotalamount) * 100)
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
    			,- (retitm.rettotalamount * coalesce(sett.referrerpercent, 0) / 100) * coalesce(sett.tdspercent, 0) / 100 as "tdsamount" -- tdsamount=incentiveamt*tdspercent/100
    			,retitm.retquantity
    			,1 as isreturntxn
    			,retitm.billreturnitemid
    		from bil_txn_invoicereturn rettxn
    		inner join bil_txn_invoicereturnitems retitm
    			--on rettxn.billingtransactionid=retitm.billingtransactionid
    			--sud/krishna:23feb'22: BugFix (When more than one item returned from same bill then it's giving one item multiple times)
    			on rettxn.billreturnid = retitm.billreturnid
    		inner join bil_txn_billingtransactionitems txnitem on retitm.billingtransactionitemid = txnitem.billingtransactionitemid
    		inner join pat_patient pat on rettxn.patientid = pat.patientid
    		inner join bil_cfg_fiscalyears fyear on rettxn.fiscalyearid = fyear.fiscalyearid
    		inner join fn_inctv_getincentivesettings_normal() sett on retitm.servicedepartmentid = sett.servicedepartmentid
    			and retitm.serviceitemid = sett.serviceitemid
    			and txnitem.referredbyid = sett.employeeid
    			and retitm.pricecategoryid = sett.pricecategoryid
    			and 1 = (
    				case 
    					when coalesce(sett.billingtypesapplicable, 'both') = 'both'
    						then 1
    					when sett.billingtypesapplicable = retitm.billingtype
    						then 1
    					else 0
    					end
    				)
    		where (rettxn.createdon)::date between p_fromdate
    				and p_todate
    			and coalesce(sett.referrerpercent, 0) != 0
    			--and retitm.billingtransactionitemid  not in 
    			--  (select distinct billingtransactionitemid  from inctv_txn_incentivefractionitem  where isreturntxn=1) 
    			and retitm.billreturnitemid not in (
    				select distinct billreturnitemid
    				from inctv_txn_incentivefractionitem
    				where billreturnitemid is not null
    					and isreturntxn = 1
    				)
    		--section: 1-- end: for referral incentive (group distribnution not required for referral)----------
    		
    		union all
    		
    		select
    			fyear.fiscalyearformatted || '-' || rettxn.invoicecode || cast(rettxn.refinvoicenum as varchar(20)) as "invoicenoformatted"
    			,rettxn.createdon as "transactiondate"
    			,sett.pricecategoryname as "pricecategory"
    			,rettxn.billingtransactionid
    			,billingtransactionitemid
    			,rettxn.patientid
    			,sett.serviceitemid
    			,sett.itemname
    			,- retitm.rettotalamount as "totalbillamount"
    			,'performer' as incentivetype
    			,
    			-- incentive goes to:  toemployeeid----
    			sett.toemployeeid as "incentivereceiverid"
    			,sett.toemployeename as "incentivereceivername"
    			,sett.distributionpercent as "incentivepercent"
    			,- retitm.rettotalamount * coalesce(sett.distributionpercent, 0) / 100 as "incentiveamount"
    			,((retitm.rettotalamount * coalesce(sett.distributionpercent, 0) / 100) / retitm.rettotalamount) * 100 as "initialincentivepercent"
    			,0 as ispaymentprocessed
    			,null as paymentinfoid
    			,1 as createdby
    			,current_timestamp as createdon
    			,null as modifiedby
    			,null as modifiedon
    			,1 as isactive
    			,1 as ismaindoctor
    			,coalesce(sett.tdspercent, 0) as tdspercentage
    			,- (retitm.rettotalamount * coalesce(sett.distributionpercent, 0) / 100) * coalesce(sett.tdspercent, 0) / 100 as "tdsamount" -- tdsamount=incentiveamt*tdspercent/100
    			,retitm.retquantity
    			,1 as isreturntxn
    			,retitm.billreturnitemid
    		from bil_txn_invoicereturn rettxn
    		inner join bil_txn_invoicereturnitems retitm on rettxn.billreturnid = retitm.billreturnid
    		--on rettxn.billingtransactionid=retitm.billingtransactionid
    		--sud/krishna:23feb'22: BugFix (When more than one item returned from same bill then it's giving one item multiple times)
    		inner join pat_patient pat on rettxn.patientid = pat.patientid
    		inner join bil_cfg_fiscalyears fyear on rettxn.fiscalyearid = fyear.fiscalyearid
    		inner join fn_inctv_getincentivesettings_groupdistribution() sett -- this gives us group distribution settings only.. 
    			--"fn_inctv_getincentivesettings" () sett
    			on retitm.servicedepartmentid = sett.servicedepartmentid
    			and retitm.serviceitemid = sett.serviceitemid
    			and retitm.performerid = sett.fromemployeeid
    			and retitm.pricecategoryid = sett.pricecategoryid
    			and 1 = (
    				case 
    					when coalesce(sett.billingtypesapplicable, 'both') = 'both'
    						then 1
    					when sett.billingtypesapplicable = retitm.billingtype
    						then 1
    					else 0
    					end
    				)
    		where (rettxn.createdon)::date between p_fromdate
    				and p_todate
    			and coalesce(sett.distributionpercent, 0) != 0
    			--and retitm.billingtransactionitemid not in 
    			--    (select distinct billingtransactionitemid from inctv_txn_incentivefractionitem  where isreturntxn=1) 
    			and retitm.billreturnitemid not in (
    				select distinct billreturnitemid
    				from inctv_txn_incentivefractionitem
    				where billreturnitemid is not null
    					and isreturntxn = 1
    				);
    	end if; --end of if.. 
    			--by default returning something so that we understand it has been executed..
    
    	open ref1 for select 'success' as "status";
        return next ref1;
    end; --end of sp--
END;
$$ LANGUAGE plpgsql;