CREATE OR REPLACE FUNCTION sp_report_handoversummaryreport(
    p_fiscalyrid INT
)
RETURNS TABLE (
    "EmployeeId" INT,
    "FullName" VARCHAR,
    "PreviousDueAmount" DECIMAL,
    "CollectionTillDate" TIMESTAMP,
    "HandoverTillDate" TIMESTAMP,
    "DueAmount" DECIMAL,
    "ReceivePendingAmount" DECIMAL,
    "TotalDueAmount" DECIMAL
) AS $$
DECLARE
    v_fystartdate DATE;
    v_fyenddate DATE;
BEGIN
    /* =============================================
    -- author:		<pratik mani lamichhane>
    -- create date: <10 aug 2021>
    -- description:	<handover summary report>
    -- change history:
    1. sud/27-oct'21   Added FiscalYearId param to get previous Date's due amount and 
                       changed the calculation accordingly
    
    2. krishna/13th jan'22  Added ReceivePendingAmount and TotalDueAmount(EMR:4763)
    
    -- ============================================= */
    BEGIN
    IF(COALESCE(p_fiscalyrid,0)=0)
    THEN
      p_fiscalyrid := (Select FiscalYearId from BIL_CFG_FiscalYears where CURRENT_TIMESTAMP>StartYear AND CURRENT_TIMESTAMP< EndYear);
    END IF;
    
    
    
    SELECT (StartYear)::Date, (EndYear)::Date INTO v_fystartdate, v_fyenddate FROM BIL_CFG_FiscalYears
    Where FiscalYearId = p_fiscalyrid;
    
    RETURN QUERY SELECT empMst.EmployeeId, emp1.FullName,
        COALESCE(prevFy.Prev_DueAmt,0) AS "PreviousDueAmount",
        COALESCE(colln.CollectionAmount,0) AS "CollectionTillDate", 
        COALESCE(deps.HandoverAmount,0) AS "HandoverTillDate",
        COALESCE(prevFy.Prev_DueAmt,0) + COALESCE(colln.CollectionAmount,0)-COALESCE(deps.HandoverAmount,0) AS "DueAmount" ,
    	COALESCE(hTxn.ReceivePendingAmount,0) AS "ReceivePendingAmount",
    	(COALESCE(prevFy.Prev_DueAmt,0) + COALESCE(colln.CollectionAmount,0)-COALESCE(deps.HandoverAmount,0)) + COALESCE(hTxn.ReceivePendingAmount,0) AS "TotalDueAmount"
    	
    
    from 
    ( Select Distinct EmployeeId from TXN_EmpCashTransaction ) empMst 
    
    LEFT JOIN EMP_Employee emp1  ON empMst.EmployeeId = emp1.EmployeeId 
    
    Left join 
    (
    	Select EmployeeId,
    	Sum(COALESCE(InAmount,0))- Sum(COALESCE(OutAmount,0)) AS "Prev_DueAmt"
    	from TXN_EmpCashTransaction
    	Where (TransactionDate)::Date < (v_fystartdate)::Date
    	Group by EmployeeId
    )prevFy
    
    ON empMst.EmployeeId=prevFy.EmployeeId
    
    
    LEFT JOIN
    (
        SELECT EmployeeId,
        Sum(COALESCE(InAmount,0)) - Sum(COALESCE(OutAmount,0)) AS "CollectionAmount"
        FROM TXN_EmpCashTransaction  
        Where  TransactionType !='handovergiven'
    	    and (TransactionDate)::Date Between v_fystartdate and v_fyenddate
    	    
        Group by EmployeeId
    ) colln
     ON empMst.EmployeeId = colln.EmployeeId
    
     LEFT JOIN
    (
        SELECT EmployeeId,
        Sum(COALESCE(OutAmount,0)) AS "HandoverAmount"
        FROM TXN_EmpCashTransaction  
        Where TransactionType ='handovergiven'
    	and (transactiondate)::date between v_fystartdate and v_fyenddate
        group by employeeid
    ) deps
     on empmst.employeeid = deps.employeeid
    
     left join 
     (
    	select handoverbyempid,
    	sum(coalesce(handoveramount,0)) AS "ReceivePendingAmount"
    	from bil_txn_cashhandover
    	where receivedbyid is null 
    	and (createdon)::date between v_fystartdate and v_fyenddate
    	group by handoverbyempid
     )htxn
     on empmst.employeeid = htxn.handoverbyempid
    
     order by emp1.fullname;
     end;
END;
$$ LANGUAGE plpgsql;