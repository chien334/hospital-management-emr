CREATE OR REPLACE FUNCTION sp_acc_accountheaddetailreport(

)
RETURNS TABLE (
    "PrimaryGroupId" INT,
    "PrimaryGroupName" VARCHAR,
    "ChartOfAccountId" INT,
    "ChartOfAccountName" INT,
    "COACode" VARCHAR,
    "LedgerGroupId" INT,
    "LedgerGroupName" VARCHAR,
    "LedgerGroupCode" VARCHAR,
    "LedgerId" INT,
    "LedgerName" VARCHAR,
    "LedgerCode" VARCHAR,
    "SubLedgerId" INT,
    "SubLedgerName" VARCHAR,
    "SubLedgerCode" VARCHAR
) AS $$
BEGIN
    /*
     filename: "sp_acc_accountheaddetailreport"
     createdby/date: 18thoct'23
     Description: To get Account Head Detail Report
     Remarks: 
    
     Change History
     S.No.    Date/User                    Change          Remarks
     1.       30thOct'23/santosh           created         initial draft.      
    */
    
    	
    RETURN QUERY SELECT 
    pg.primarygroupid,
    pg.primarygroupname,
    coa.chartofaccountid,
    coa.chartofaccountname,
    coa.coacode,
    lg.ledgergroupid,
    lg.ledgergroupname,
    lg.code AS "LedgerGroupCode",
    l.ledgerid,
    l.ledgername,
    l.code AS "LedgerCode",
    sl.subledgerid,
    sl.subledgername,
    sl.subledgercode
    from acc_mst_primarygroup pg
    join acc_mst_chartofaccounts coa on pg.primarygroupid = coa.primarygroupid
    join acc_mst_ledgergroup lg on coa.chartofaccountid = lg.coaid
    join acc_ledger l on lg.ledgergroupid = l.ledgergroupid
    join acc_mst_subledger sl on l.ledgerid = sl.ledgerid;
END;
$$ LANGUAGE plpgsql;