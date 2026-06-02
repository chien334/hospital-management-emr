CREATE PROCEDURE [dbo].[SP_FRC_GetTotalFractionbyItem]
AS
BEGIN
 Select itm.ItemId,itm.ItemName, billingItems.ServiceDepartmentName, itm.Price, SUM(frac.FinalAmount) as 'FractionAmount' from FRC_FractionCalculation frac
join BIL_TXN_BillingTransactionItems billingItems on frac.BillTxnItemId= billingItems.BillingTransactionItemId
join BIL_CFG_BillItemPrice itm on billingItems.ItemId= itm.ItemId 
where billingItems.ServiceDepartmentId=itm.ServiceDepartmentId and itm.isFractionApplicable= 1 
group by itm.ItemId, itm.ItemName, billingitems.ServiceDepartmentName, itm.Price
order by itm.ItemId
END