CREATE PROCEDURE [dbo].[SP_INCTV_ViewTxn_InvoiceItemLevel] --SP_INCTV_ViewTxn_InvoiceItemLevel '2020-02-05','2020-02-10',313716,0
	@BillingTansactionId INT = NULL
AS
/*
 File: SP_INCTV_ViewTxn_InvoiceItemLevel
 Description: 
 Conditions/Checks: 

 Remarks: We're returning 2 tables from here
 Change History:
 S.No.    ChangeDate/By					Remarks
 1.      24Jan'20/Pratik          Initial Draft (Needs Revision)
 2.      16Feb'20/Sud			  Rewrite after change in logic.. 
 3.      11June2020/Pratik		  GroupDistribution Impacts on Existing Functionalities 
 4.      14Aug2023/Nirmala        Fetch ServiceItemId And IntegrationItemId
 5.		 22ndSept'23/Krishna	  Read PriceCategory 
*/
BEGIN
	--Table:1 -- Get BillingTransactionItem information---
	SELECT PatientId
		,BillingTransactionItemId
		,BillingTransactionId
		,IntegrationItemId
		,ItemName
		,Quantity
		,Price
		,SubTotal
		,DiscountAmount
		,TotalAmount
		,ServiceItemId
		,priceCat.PriceCategoryId
		,priceCat.PriceCategoryName
	FROM (SELECT PatientId,BillingTransactionItemId,BillingTransactionId, IntegrationItemId, ItemName, Quantity,
			Price, SubTotal, DiscountAmount, TotalAmount, ServiceItemId, PriceCategoryId
			FROM BIL_TXN_BillingTransactionItems
	WHERE BillingTransactionId = @BillingTansactionId) itms
	INNER JOIN BIL_CFG_PriceCategory priceCat ON itms.PriceCategoryId = priceCat.PriceCategoryId

	--Table:2 -- Get Fraction Information---
	SELECT *
	FROM INCTV_TXN_IncentiveFractionItem
	WHERE BillingTransactionId = @BillingTansactionId
END