CREATE PROCEDURE [dbo].[SP_ACC_AccountHeadDetailReport] 
AS
/*
 FileName: [SP_ACC_AccountHeadDetailReport]
 CreatedBy/date: 18thOct'23
 Description: To get Account Head Detail Report
 Remarks: 

 Change History
 S.No.    Date/User                    Change          Remarks
 1.       30thOct'23/Santosh           Created         Initial Draft.      
*/
BEGIN
	
SELECT 
PG.PrimaryGroupId,
PG.PrimaryGroupName,
COA.ChartOfAccountId,
COA.ChartOfAccountName,
COA.COACode,
LG.LedgerGroupId,
LG.LedgerGroupName,
LG.Code AS LedgerGroupCode,
L.LedgerId,
L.LedgerName,
L.Code AS LedgerCode,
SL.SubLedgerId,
SL.SubLedgerName,
SL.SubLedgerCode
FROM ACC_MST_PrimaryGroup PG
JOIN ACC_MST_ChartOfAccounts COA ON PG.PrimaryGroupId = COA.PrimaryGroupId
JOIN ACC_MST_LedgerGroup LG ON COA.ChartOfAccountId = LG.COAId
JOIN ACC_Ledger L ON LG.LedgerGroupID = L.LedgerGroupId
JOIN ACC_MST_SubLedger SL ON L.LedgerId = SL.LedgerId
END