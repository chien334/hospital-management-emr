/* ***********************************************************************
FileName: [SP_ACC_GetLedgerList]  
CreatedBy/date: NageshBB/22 Dec 2020
Description: Get Ledger list with correct closing balance of every ledger
Change History
S.No.    UpdatedBy/Date                        Remarks
1.      Nagesh:20Jun'20                   created sp for get ledger list with closing balance or opening balance as per need
************************************************************************ */
CREATE OR REPLACE FUNCTION sp_acc_getledgerlist(
    p_hospitalid INT,
    p_fiscalyearidforopeningbal INT DEFAULT NULL,
    p_getclosingbal BOOLEAN DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
    v_fromdate TIMESTAMP := (select "StartDate" from "ACC_MST_FiscalYears" where "FiscalYearId"=p_fiscalyearidforopeningbal LIMIT 1);
    v_todate TIMESTAMP := (select CURRENT_TIMESTAMP);
BEGIN
    begin
    --if p_getclosingbal = true then we will calculate closing balance from txn table and return with every ledger
    --else closing balance will be 0 
     
    	if(p_getclosingbal = true)
    	then
    	
    	
    		
    	
    		--ledger with ledgergroup and all other details
    		open ref1 for select 
    		led."HospitalId",		led."LedgerId",		led."LedgerGroupId",		ledgroup."PrimaryGroup",		ledgroup."COA",		ledgroup."LedgerGroupName",
    		led."LedgerName",		led."LedgerReferenceId",		led."SectionId",		led."Description",		led."IsActive" AS "IsActive",		led."OpeningBalance",
    		led."DrCr",		led."CreatedBy",		led."CreatedOn",		led."Name",		led."Code",		led."LedgerType",		led."PANNo",		led."MobileNo",
    		led."Address",		led."TDSPercent",		led."CreditPeriod",		led."LandlineNo",			closebaltbl.dramount-closebaltbl.cramount as "ClosingBalance" 
    		from "ACC_Ledger" led join "ACC_MST_LedgerGroup"  ledgroup on led."LedgerGroupId"=ledgroup."LedgerGroupId"		
    		join  (
    		select  t.ledgerid, sum(openingdramount) + sum(txndramount) as dramount,sum(openingcramount)+sum(txncramount) as cramount
    		from (
    		--get ledger opening balance from ledger balance history table
    	    select 
    		led."LedgerId" as ledgerid,
    		case when coalesce(lbh."OpeningDrCr", true)=true then coalesce(lbh."OpeningBalance",0) else 0 end as openingdramount,
    		case when lbh."OpeningDrCr"=false then coalesce(lbh."OpeningBalance",0) else 0 end as openingcramount,		
    		0 as txndramount,0 as txncramount
    	    from "ACC_Ledger" led join "ACC_LedgerBalanceHistory" lbh on led."LedgerId"=lbh."LedgerId" and led."HospitalId"=lbh."HospitalId"
    		where lbh."HospitalId"=p_hospitalid and lbh."FiscalYearId"=p_fiscalyearidforopeningbal and
    		led."IsActive"=true  
    
    		union
    
    	 -- get transaction calculation amount with ledger
    		 select ledgerid ,0 as openingdramount , 0 as openingcramount, sum(txndramount)  as txndramount, sum(txncramount) as txncramount
    		from (
    		select 
    		ti."LedgerId" as ledgerid, --0 as openingdramount, 0 as openingcramount, 
    		case when ti."DrCr"=true then coalesce(ti."Amount",0) else 0 end as txndramount,
    		case when ti."DrCr"=false then coalesce(ti."Amount",0) else 0 end as txncramount
    	    from "ACC_Transactions" t join "ACC_TransactionItems" ti on t."TransactionId"=ti."TransactionId"
    		where t."HospitalId"=p_hospitalid and t."IsActive"=true and ((t."TransactionDate")::date between (v_fromdate)::date and (v_todate)::date)
    		)as p
    		group by ledgerid
    		) as t  group by t.ledgerid
    		) as closebaltbl  on closebaltbl.ledgerid=led."LedgerId"
    		where led."HospitalId"=p_hospitalid and ledgroup."HospitalId"=p_hospitalid 
    		and led."IsActive"=true and ledgroup."IsActive"=true  
    		order by led."LedgerId";
        return next ref1;
    	
    	else
    	
    	--mainly for accounting ledger setting page where isactive false and true both ledger r there
    		open ref2 for select 
    		led."HospitalId",		led."LedgerId",		led."LedgerGroupId",		ledgroup."PrimaryGroup",		ledgroup."COA",		ledgroup."LedgerGroupName",
    		led."LedgerName",		led."LedgerReferenceId",		led."SectionId",		led."Description",		led."IsActive" AS "IsActive",		led."OpeningBalance",
    		led."DrCr",		led."CreatedBy",		led."CreatedOn",		led."Name",		led."Code",		led."LedgerType",		led."PANNo",		led."MobileNo",
    		led."Address",		led."TDSPercent",		led."CreditPeriod",		led."LandlineNo",			0 as "ClosingBalance" 
    		from "ACC_Ledger" led join "ACC_MST_LedgerGroup"  ledgroup on led."LedgerGroupId"=ledgroup."LedgerGroupId"
    		where led."HospitalId"=p_hospitalid and ledgroup."HospitalId"=p_hospitalid
    		order by led."LedgerId";
        return next ref2;
    	end if;
    end;
END;
$$ LANGUAGE plpgsql;