/*
Author:		<Anish Bhattarai>
Create date: <10 Aug, 2020>
Description:	<Update OrderStatus on BillTxnItems table on Radiology Actions>

Change History:
S.N			ChangedBy/Date					Remarks
1.			Anish/10thAug'23				Initial draft
2.			Krishna/20thJuly'23				Alter Join condition for BillingTransactionItem and ImagingRequisition
*/

CREATE PROCEDURE [dbo].[SP_Bill_OrderStatusUpdate_Radiology] 
(
	@reqID INT,
	@status VARCHAR(20)
)
AS
BEGIN
	Update BIL_TXN_BillingTransactionItems set OrderStatus=@status where BillingTransactionItemId IN (
	(select txnItem.BillingTransactionItemId from (select * from RAD_PatientImagingRequisition 
	where ImagingRequisitionId = @reqID) as req 
	join BIL_TXN_BillingTransactionItems as txnItem on req.BillingTransactionItemId = txnItem.BillingTransactionItemId
	join BIL_MST_ServiceDepartment as srv on txnItem.ServiceDepartmentId = srv.ServiceDepartmentId
	where LOWER(srv.IntegrationName) = 'radiology' and ISNULL(txnItem.ReturnStatus,0)= 0 and  txnItem.CancelledBy IS NULL)
	);
END