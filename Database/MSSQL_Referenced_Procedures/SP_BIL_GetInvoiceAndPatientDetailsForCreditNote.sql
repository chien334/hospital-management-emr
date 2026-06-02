CREATE PROCEDURE [dbo].[SP_BIL_GetInvoiceAndPatientDetailsForCreditNote]
   @InvoiceNumber INT, 
   @FiscalYearId INT
AS
/*
FileName: SP_BIL_GetInvoiceAndPatientDetailsForCreditNote
Description: 
 * To get PatientInformation, InvoiceInformation, RemainingInvoiceItems Information 
    and AlreadyReturned Items information for Credit Note.
 * Remaining Invoice items is needed since we can only return the remaining qty if some qty is already returned.
 * Returns Four tables

USAGE: EXEC SP_BIL_GetInvoiceAndPatientDetailsForCreditNote 2,6
Change History
S.No.    UpdatedBy/Date                        Remarks
1.      Sud/1May'21                 Initial Draft
2.		Krishna/19thNOV'21			made changes to get the SettlementId and CashDisocunt from Settlement Table.
3.		Krishna/2Jun'22				changed ProviderId to PerformerId and RequestedBy to PrescriberId
4.		Krishna/23rdNov'22			Read PriceCategoryId, PriceCategoryName, ClaimCode
5.		Krishna/9thApril'23			Change Join with PAT_CFG_MembershipType to BIL_CFG_Scheme
6.      Sud/16Apr'23                Rename ItemId of InvoiceReturnItem to ServiceItemId and It's impact handling
7.		Krishna/25thApril'23		Read IsBillingCoPayment AS IsCoPayment
8.		Krishna/11thMay'23			Read CoPayCashAmount and CoPayCreditAmount from BillingTransactionItems table
9.		Krishna/18thJune'23		    Read OrganizationId in Invoice Information
*/
BEGIN
 
 Declare @PatientId INT, @PatientVisitId INT, @BillTxnId INT

Select @PatientId=PatientId,@PatientVisitId=PatientVisitId, @BillTxnId=BillingTransactionId
from BIL_TXN_BillingTransaction 
where InvoiceNo=@InvoiceNumber and FiscalYearId=@FiscalYearId

--Select @PatientId, @PatientVisitId, @BillTxnId

Select  
pat.PatientId, pat.PatientCode, pat.ShortName,
pat.DateOfBirth,pat.Gender, cont.CountryName, dist.CountrySubDivisionName, pat.Address
from PAT_Patient pat WITH(NOLOCK) INNER JOIN MST_CountrySubDivision dist
                         ON pat.CountrySubDivisionId=dist.CountrySubDivisionId
                     INNER JOIN MST_Country cont
					   ON dist.CountryId=cont.CountryId
where PatientId=@PatientId

Select txn.PatientId, txn.BillingTransactionId, txn.InvoiceCode, txn.InvoiceNo, txn.PaymentMode
, txn.CreatedOn 'InvoiceDate',  
fy.FiscalYearFormatted+'-'+txn.InvoiceCode+Convert(varchar(20),txn.InvoiceNo) 'InvoiceNoFormatted',
txn.SubTotal, txn.DiscountAmount, txn.TaxTotal, txn.TotalAmount, txn.BillStatus,
txn.TransactionType, txn.InvoiceType, txn.IsInsuranceBilling, txn.InsuranceProviderId,
usr.UserName,ISNULL(txn.SettlementId,0) 'SettlementId',
ISNULL(stl.DiscountAmount,0) 'CashDiscount', scheme.SchemeId,scheme.SchemeName, 
priceCat.PriceCategoryId, priceCat.PriceCategoryName, txn.ClaimCode, scheme.IsBillingCoPayment AS 'IsCoPayment', txn.OrganizationId 

from BIL_TXN_BillingTransaction txn WITH(NOLOCK)
          INNER JOIN BIL_CFG_FiscalYears fy on txn.FiscalYearId = fy.FiscalYearId
           INNER JOIN BIL_CFG_Scheme scheme on txn.SchemeId = scheme.SchemeId 
           LEFT JOIN BIL_MST_Credit_Organization crOrg
                ON txn.OrganizationId=crOrg.OrganizationId
           LEFT JOIN RBAC_User usr on txn.CreatedBy=usr.EmployeeId
		   
		   LEFT JOIN BIL_TXN_Settlements stl WITH(NOLOCK) on txn.SettlementId = stl.SettlementId
		   LEFT JOIN PAT_PatientVisits visits WITH(NOLOCK) on visits.PatientVisitId = txn.PatientVisitId
		   LEFT JOIN BIL_CFG_PriceCategory priceCat on priceCat.PriceCategoryId = visits.PriceCategoryId
where BillingTransactionId = @BillTxnId

Select  
	itm.BillingTransactionItemId,
	itm.BillingTransactionId,
	itm.PatientId,
	itm.ServiceDepartmentId,
	itm.ServiceItemId, --sud:16Apr'23
	itm.ItemCode,--sud:16Apr'23
	itm.ItemName,--sud:16Apr'23
	itm.Price,
	itm.Quantity-ISNULL(ret.RetQuantity,0) 'RemainingQty',
	itm.Price*(itm.Quantity-ISNULL(ret.RetQuantity,0))  'SubTotal',
    itm.DiscountAmount/itm.Quantity 'DiscountAmtPerUnit',
	--Remaining DiscountAmt= DiscPerUnit * RemainingQty
    (itm.DiscountAmount/itm.Quantity)*(itm.Quantity-ISNULL(ret.RetQuantity,0)) 'DiscountAmount',
	ISNULL(itm.Tax,0)/itm.Quantity  'TaxAmtPerUnit',
	(ISNULL(itm.Tax,0)/itm.Quantity)*(itm.Quantity-ISNULL(ret.RetQuantity,0)) 'TaxAmount',
    itm.TotalAmount/itm.Quantity 'TotalAmtPerUnit',
	(itm.TotalAmount/itm.Quantity) * (itm.Quantity-ISNULL(ret.RetQuantity,0)) 'TotalAmount',
	itm.DiscountPercent,
	itm.PerformerId,
	itm.BillStatus,
	itm.RequisitionId,
	itm.RequisitionDate,
	itm.PrescriberId,
	itm.PatientVisitId,
	itm.BillingPackageId,
	itm.CreatedBy,
	itm.CreatedOn,
	itm.BillingType,
	itm.RequestingDeptId,
	itm.VisitType,
	itm.PriceCategory,
	itm.PriceCategoryId,--sud:16Apr'23
	itm.PatientInsurancePackageId,
	itm.IsInsurance,
	itm.DiscountSchemeId,
	itm.LabTypeName,
	itm.OrderStatus,
	itm.CoPaymentCashAmount AS 'CoPayCashAmount',
	itm.CoPaymentCreditAmount AS 'CoPayCreditAmount'

from BIL_TXN_BillingTransactionItems itm WITH(NOLOCK)
  LEFT JOIN ( Select BillingTransactionItemId, SUM(RetQuantity) 'RetQuantity' 
	  from  BIL_TXN_InvoiceReturnItems WITH(NOLOCK)
	  group by BillingTransactionItemId
	  ) ret

 ON itm.BillingTransactionItemId=ret.BillingTransactionItemId
Where itm.BillingTransactionId=@BillTxnId
AND (itm.Quantity-ISNULL(ret.RetQuantity,0)) > 0  --RemainingQty more than Zero

 
 
Select crNote.BillReturnId,
  crNote.CreatedOn 'CreditNoteDate',
 crNote.CreditNoteNumber,
 crNote.FiscalYearId,
 fy.FiscalYearFormatted+'-CR-'+Convert(varchar(20),crNote.CreditNoteNumber) 'CreditNoteNumFormatted',

 retItm.BillingTransactionItemId,
 retItm.BillingTransactionId,
 retItm.ServiceDepartmentId,
 retItm.ServiceItemId,  --Sud:16Apr'23--ColumnName is Changed Now
 retItm.ItemName,
 retItm.RetQuantity,
 retItm.RetSubTotal,
 retItm.RetDiscountAmount,
 retItm.RetTotalAmount

from BIL_TXN_InvoiceReturnItems retItm WITH(NOLOCK) 
  INNER JOIN BIL_TXN_InvoiceReturn crNote WITH(NOLOCK)
       ON retItm.BillReturnId=crNote.BillReturnId
 INNER JOIN BIL_CFG_FiscalYears fy
     on crNote.FiscalYearId = fy.FiscalYearId
Where retItm.BillingTransactionId = @BillTxnId
END