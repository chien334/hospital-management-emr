CREATE PROCEDURE [dbo].[SP_INCTV_GetFractionItems_ByTxnItemId]  -- EXEC SP_INCTV_GetFractionItems_ByTxnItemId 21058
  @BillingTansactionItemId int = NULL
AS
/*
 File: SP_INCTV_GetFractionItems_ByTxnItemId
 Description: to get the fractions for Current BillingTransactionItemId.
 Conditions/Checks: 
 Remarks: 
 Change History:
 S.No.    ChangeDate/By       Remarks
 1.      10Apr'20/Sud          Initial Draft 
*/
BEGIN
 
--Table:1 -- Get Fraction Information---
Select * from INCTV_TXN_IncentiveFractionItem
WHERE BillingTransactionItemId=@BillingTansactionItemId

END