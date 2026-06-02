CREATE PROCEDURE [dbo].[SP_PHRM_InvoiceItemDetailsToReturnByHospitalNo] @HospitalNo VARCHAR(20) = NULL
	,@PaymentMode VARCHAR(20) = NULL
	,@FromDate DATE = NULL
	,@ToDate DATE = NULL
	,@StoreId INT = NULL
	,@SchemeId INT = NULL
AS
/*
 FileName: [SP_PHRM_InvoiceItemDetailsToReturnByHospitalNo]
 Created: 30Jan'23/Rohit
 Description: To Get the Multiple Invoice Items Details to return by Hospital No.
 Remarks: 
 Change History
 S.No.    Date/User              Change          Remarks
 1.	     30Jan'23/Rohit		                     inital draft
 2.      Rohit/13Feb'23						     MRP-> SalePrice
 3.		 Rohit/14Feb'23							 Item which is totally return should not be included (invitm.Quantity !=ISNULL(retitm.PreviouslyReturnedQty, 0))
 4.  Rohit/Sud: 20Apr'23 (TEMPORARY REVISION ONLY)   --- Removed PriceCategory Dependency for Manipal UAT ONLY. Need immediate Revision/Correction
 5.  Nirmala/ 6/1/23                              Select Invoice Created Date and VisitType
 6.  Nirmala/29/Jun/23                            Remove ISNULL() in DefaultCreditOrganizationId and DefaultPaymentMode
*/
BEGIN

Declare @DefSchemeId INT = (Select SchemeId from BIL_CFG_Scheme WHERE IsSystemDefault = 1)
IF (@SchemeId IS NULL OR @SchemeId = 0)
BEGIN
	SET @SchemeId = @DefSchemeId
END
	

	SELECT TOP 1 pat.PatientId
		,pat.ShortName 'PatientName'
		,ISNULL(visit.VisitType,'outpatient') 'VisitType'
		,CASE 
			WHEN pat.IsOutdoorPat = 1
				THEN 'Outdoor'
			ELSE 'Indoor'
			END AS PatientType
		,pat.PatientCode 'HospitalNo'
	FROM PAT_Patient pat 
	LEFT JOIN PAT_PatientVisits visit ON pat.PatientId=visit.PatientId
	WHERE pat.PatientCode = @HospitalNo

	SELECT pc.SchemeName
	,pc.SchemeId
		,ISNULL(pc.IsPharmacyCoPayment,0) AS 'IsPharmacyCoPayment'
		,ISNULL(pc.PharmacyCoPayCashPercent,0) AS 'PharmacyCoPayCashPercent'
		,ISNULL(pc.PharmacyCoPayCreditPercent,0) AS 'PharmacyCoPayCreditPercent'
		,ISNULL(pc.OpPhrmDiscountPercent,0) AS  'OpPhrmDiscountPercent'
		,pc.DefaultCreditOrganizationId AS 'DefaultCreditOrganizationId'
		,pc.DefaultPaymentMode AS 'DefaultPaymentMode'
	 From BIL_CFG_Scheme pc
	 where ISNULL(pc.SchemeId, 1) = @SchemeId


	--SELECT pc.PriceCategoryName
	--	,ISNULL(pmc.PatientMapPriceCategoryId, 0) 'PatientMapPriceCategoryId'
	--	,ISNULL(pmc.PriceCategoryId, 0) 'PriceCategory'
	--	,ISNULL(pc.IsCoPayment, 0) 'IsCoPayment'
	--	,ISNULL(pc.Copayment_CashPercent, 0) 'CoPaymentCashPercent'
	--	,ISNULL(pc.Copayment_CreditPercent, 0) 'CoPaymentCreditPercent'
	--FROM PAT_Patient pat
	--INNER JOIN PAT_Map_PriceCategory pmc ON pat.PatientId = pmc.PatientId
	--INNER JOIN BIL_CFG_PriceCategory pc ON pmc.PriceCategoryId = pc.PriceCategoryId
	--WHERE pat.PatientCode = @HospitalNo
	--	AND ISNULL(pc.PriceCategoryId, 1) = @PriceCategoryId


	SELECT invitm.ItemId
		,invitm.ItemName
		,invitm.BatchNo
		,invitm.SalePrice
		,invitm.Quantity
		,invitm.Quantity 'SoldQty'
		,ISNULL(retitm.PreviouslyReturnedQty, 0) 'PreviouslyReturnedQty'
		,0 'SubTotal'
		,0 'DiscountAmount'
		,0 'VATAmount'
		,0 'TotalAmount'
		,invitm.DiscountPercentage
		,invitm.VATPercentage
		,'PH' + CONVERT(VARCHAR(20), inv.InvoicePrintId) 'BillNo'
		,inv.InvoiceId
		,invitm.InvoiceItemId
		,invitm.CreatedOn
		,inv.FiscalYearId
		,inv.InvoicePrintId 'InvoiceNo'
		,inv.SettlementId
	FROM PAT_Patient pat
	INNER JOIN PHRM_TXN_Invoice inv ON pat.PatientId = inv.PatientId
	INNER JOIN PHRM_TXN_InvoiceItems invitm ON inv.InvoiceId = invitm.InvoiceId
	LEFT JOIN (
		SELECT InvoiceItemId
			,ISNULL(SUM(ReturnedQty), 0) 'PreviouslyReturnedQty'
		FROM PHRM_TXN_InvoiceReturnItems
		GROUP BY InvoiceItemId
		) retitm ON invitm.InvoiceItemId = retitm.InvoiceItemId
	WHERE pat.PatientCode = @HospitalNo
		AND inv.PaymentMode = @PaymentMode
		AND CONVERT(DATE, inv.CreateOn) BETWEEN @FromDate AND @ToDate
		AND inv.StoreId = @StoreId
		--AND ISNULL(invitm.PriceCategoryId, 1) = @PriceCategoryId
		AND invitm.Quantity !=ISNULL(retitm.PreviouslyReturnedQty, 0)
	ORDER BY inv.CreateOn DESC

END