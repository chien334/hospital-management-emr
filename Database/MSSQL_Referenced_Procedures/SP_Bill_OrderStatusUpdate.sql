CREATE PROCEDURE [dbo].[SP_Bill_OrderStatusUpdate] 
(
	@RequisitionId_OrderStatus LabRequisitionId_OrderStatus_Table READONLY
)
	
AS
/*
Author:		<Anish Bhattarai>
Create date: <7 Aug, 2020>
Description:	<Update the OrderStatus of BillTxnItem table>
Change History:
S.N			ChangedBy/Date					Remarks
1.			Anish/10thAug'23				Initial draft
2.			Krishna/20thJuly'23				Alter Join condition for BillingTransactionItem and LabRequisition
3.          DevN/12thSept'23                Alter Parametertype get list of requisitionId and orderstatus from client.
*/
BEGIN
UPDATE BIL_TXN_BillingTransactionItems SET OrderStatus = req.OrderStatus FROM 
    (SELECT requisition.RequisitionId,requisition.BillingTransactionItemId, parameter.OrderStatus FROM LAB_TestRequisition requisition 
	INNER JOIN @RequisitionId_OrderStatus parameter ON requisition.RequisitionId = parameter.RequisitionId) as req 
	join BIL_TXN_BillingTransactionItems as txnItem on req.BillingTransactionItemId = txnItem.BillingTransactionItemId
	join BIL_MST_ServiceDepartment as srv on txnItem.ServiceDepartmentId = srv.ServiceDepartmentId
	where srv.IntegrationName = 'lab' and ISNULL(txnItem.ReturnStatus,0)= 0 and  txnItem.CancelledBy IS NULL
END