-- End: Ramavtar 18Nov, Incentive Modules Routes added --



CREATE PROCEDURE [dbo].[SP_FRC_GetFractionApplicableList]
AS
/*
 Altered by Sud on 20Nov'19 for Transaction Date
*/
BEGIN
select 
  per.PercentSettingId,txnItm.BillingTransactionItemId as BillTransactionItemId,
  txnItm.CreatedOn 'TransactionDate',
  itmPrice.ItemName, 
  itmPrice.BillItemPriceId, txnItm.TotalAmount, txnItm.BillingType, (pat.FirstName + ' ' + pat.LastName) as FullName,
  txnItm.ServiceDepartmentName,  c.BillTxnItemId 
  from BIL_TXN_BillingTransactionItems txnItm
  join BIL_CFG_BillItemPrice itmPrice on txnItm.ItemId = itmPrice.ItemId 
    join PAT_Patient pat on txnItm.PatientId = pat.PatientId
  left join FRC_FractionCalculation c on txnItm.BillingTransactionItemId = c.BillTxnItemId
  left join FRC_PercentSetting per on per.BillItemPriceId = itmPrice.BillItemPriceId
where txnItm.ServiceDepartmentId = itmPrice.ServiceDepartmentId 
    and itmPrice.isFractionApplicable = 1 
	and per.PercentSettingId IS NOT NULL

group by txnItm.BillingTransactionItemId,txnItm.CreatedOn, itmPrice.ItemId, 
  c.BillTxnItemId, itmPrice.ItemId ,  itmPrice.BillItemPriceId, per.PercentSettingId,
  c.BillTxnItemId, itmPrice.ItemName ,
  txnItm.ServiceDepartmentName, txnItm.TotalAmount ,
  txnItm.BillingType, FirstName, LastName
order by txnItm.BillingTransactionItemId DESC
END