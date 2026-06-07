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
    v_fromdate TIMESTAMP := (select  StartDate from ACC_MST_FiscalYears where FiscalYearId=p_fiscalyearidforopeningbal LIMIT 1);
    v_todate TIMESTAMP := (select CURRENT_TIMESTAMP);
BEGIN
    begin
    --if p_getclosingbal = true then we will calculate closing balance from txn table and return with every ledger
    --else closing balance will be 0 
     
    	if(p_getclosingbal = true)
    	then
    	
    	
    		
    	
    		--ledger with ledgergroup and all other details
    		open ref1 for select 
    		led.hospitalid,		led.ledgerid,		led.ledgergroupid,		ledgroup.primarygroup,		ledgroup.coa,		ledgroup.ledgergroupname,
    		led.ledgername,		led.ledgerreferenceid,		led.sectionid,		led.description,		isactive = led.isactive,		led.openingbalance,
    		led.drcr,		led.createdby,		led.createdon,		led.name,		led.code,		led.ledgertype,		led.panno,		led.mobileno,
    		led.address,		led.tdspercent,		led.creditperiod,		led.landlineno,			closebaltbl.dramount-closebaltbl.cramount as closingbalance 
    		from acc_ledger led join acc_mst_ledgergroup  ledgroup on led.ledgergroupid=ledgroup.ledgergroupid		
    		join  (
    		select  t.ledgerid, sum(openingdramount) + sum(txndramount) as dramount,sum(openingcramount)+sum(txncramount) as cramount
    		from (
    		--get ledger opening balance from ledger balance history table
    	    select 
    		led.ledgerid,
    		case when coalesce(lbh.openingdrcr, 1)=1 then coalesce(lbh.openingbalance,0) else 0 end as openingdramount,
    		case when lbh.openingdrcr=0 then coalesce(lbh.openingbalance,0) else 0 end as openingcramount,		
    		0 as txndramount,0 as txncramount
    	    from acc_ledger led join acc_ledgerbalancehistory lbh on led.ledgerid=lbh.ledgerid and led.hospitalid=lbh.hospitalid
    		where lbh.hospitalid=p_hospitalid and lbh.fiscalyearid=p_fiscalyearidforopeningbal and
    		led.isactive=1  
    
    		union
    
    	 -- get transaction calculation amount with ledger
    		 select ledgerid ,0 as openingdramount , 0 as openingcramount, sum(txndr)  as txndramount, sum(txncr) as txncramount
    		from (
    		select 
    		ti.ledgerid, --0 as openingdramount, 0 as openingcramount, 
    		case when ti.drcr=1 then coalesce(ti.amount,0) else 0 end as txndr,
    		case when ti.drcr=0 then coalesce(ti.amount,0) else 0 end as txncr
    	    from acc_transactions t join acc_transactionitems ti on t.transactionid=ti.transactionid
    		where t.hospitalid=p_hospitalid and ((t.transactiondate)::date between (v_fromdate)::date and (v_todate)::date)
    		)as p
    		group by ledgerid
    		) as t  group by t.ledgerid
    		) as closebaltbl  on closebaltbl.ledgerid=led.ledgerid
    		where led.hospitalid=p_hospitalid and ledgroup.hospitalid=p_hospitalid 
    		and led.isactive=1 and ledgroup.isactive=1  
    		order by led.ledgerid;
        return next ref1;
    	
    	else
    	
    	--mainly for accounting ledger setting page where isactive false and true both ledger r there
    		open ref2 for select 
    		led.hospitalid,		led.ledgerid,		led.ledgergroupid,		ledgroup.primarygroup,		ledgroup.coa,		ledgroup.ledgergroupname,
    		led.ledgername,		led.ledgerreferenceid,		led.sectionid,		led.description,		isactive = led.isactive,		led.openingbalance,
    		led.drcr,		led.createdby,		led.createdon,		led.name,		led.code,		led.ledgertype,		led.panno,		led.mobileno,
    		led.address,		led.tdspercent,		led.creditperiod,		led.landlineno,			0 as closingbalance 
    		from acc_ledger led join acc_mst_ledgergroup  ledgroup on led.ledgergroupid=ledgroup.ledgergroupid
    		where led.hospitalid=p_hospitalid and ledgroup.hospitalid=p_hospitalid
    		order by led.ledgerid;
        return next ref2;
    	end if;
    end;
END;
$$ LANGUAGE plpgsql;