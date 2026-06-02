CREATE PROCEDURE [dbo].[SP_BillItemCancellation_From_Ward]
(
	@BillingTransactionItemId int, 
	@RequisitionId int, 
	@IntegrationName varchar(50), 
	@UserId int, 
	@Remarks varchar(500)
)
AS
/*
Author:		<Anish Bhattarai>
Create date: <12 August>
Description:	<Cancellation of Bill Item>
Change History
S.N.		UpdatedBy/Date				Remarks
1			Anish/12August				initial script
2			Bibek/25thSept'23			update lab and imaging requisitions using billingtransactionItemId 
*/

BEGIN
	BEGIN TRY
		BEGIN TRANSACTION;
	
		declare @CancelledOn DateTime;
		set @CancelledOn = GETDATE();
		select @CancelledOn;

		Update BIL_TXN_BillingTransactionItems
		set BillStatus='cancel', CancelledBy=@UserId,CancelledOn=@CancelledOn,CancelRemarks=@Remarks where BillingTransactionItemId=@BillingTransactionItemId

		IF(LOWER(@IntegrationName)='lab')
		BEGIN
			Update LAB_TestRequisition set BillingStatus='cancel', BillCancelledBy=@UserId, BillCancelledOn=@CancelledOn where BillingTransactionItemId=@BillingTransactionItemId
		END

		IF(LOWER(@IntegrationName)='radiology')
		BEGIN
			Update RAD_PatientImagingRequisition set BillingStatus='cancel', BillCancelledBy=@UserId, BillCancelledOn=@CancelledOn where BillingTransactionItemId=@BillingTransactionItemId
		END	

		COMMIT;

	END TRY

	BEGIN CATCH
		ROLLBACK;
	END CATCH

END