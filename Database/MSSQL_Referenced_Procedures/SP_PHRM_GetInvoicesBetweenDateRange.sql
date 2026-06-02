-- End: Bikash 3rd-June'21, Updating Morbidity Report values in RBAC_RouteConfig table 

CREATE PROCEDURE [dbo].[SP_PHRM_GetInvoicesBetweenDateRange] 
		@FromDate Date=NULL,
		@ToDate DATE=NULL,
		@StoreId INT=NULL
AS
/*
FileName:SP_PHRM_GetInvoicesBetweenDateRange
CreatedBy/date: Sud,Sanjit/8Apr'21 
Description:Get Invoice Details for Pharmacy-> Duplicate Print 

Change History
S.No.    UpdatedBy/Date                        Remarks
1.      Sud,Sanjit/8Apr'21                   Initial Draft
2.		Rusha/Ramesh/08 June,21				patientshortname correction
*/
BEGIN
SET @FromDate= ISNULL(@FromDate,Convert(Date,GetDate()))
SET @ToDate= ISNULL(@ToDate,Convert(Date,GetDate()))

select
	 inv.InvoiceId,
	 inv.InvoicePrintId,
	 --pat.ShortName 'PatientName',
	 pat.FirstName + ISNULL(' ' + pat.MiddleName, '') + ' ' + pat.LastName AS PatientName,
	 pat.PatientCode,
	 inv.SubTotal,
	 inv.DiscountAmount,
	 inv.VATAmount,
	 inv.PaidAmount,
	 inv.BilStatus,
	 inv.CreditAmount 'TotalCredit',
	 inv.CreateOn,
	 pat.IsOutdoorPat,
	 case when ISNULL(pat.IsOutdoorPat,0)=0 then 'Indoor'
	   ELSE 'Outdoor' END AS PatientType,
	inv.PaymentMode,
	fy.FiscalYearFormatted AS FiscalYear,
	 pat.Ins_NshiNumber 'NSHINumber',
	 inv.ClaimCode 'ClaimCode'

	 from PHRM_TXN_Invoice inv
	 inner join BIL_CFG_FiscalYears fy 
	 on inv.FiscalYearId=fy.FiscalYearId
	inner join PAT_Patient pat
	on inv.PatientId=pat.PatientId

where convert(date, inv.CreateOn) between   @FromDate and @ToDate
AND inv.StoreId = @StoreId
order by inv.CreateOn desc
END