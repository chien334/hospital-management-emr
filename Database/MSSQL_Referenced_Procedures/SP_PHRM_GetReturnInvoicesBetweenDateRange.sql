CREATE PROCEDURE [dbo].[SP_PHRM_GetReturnInvoicesBetweenDateRange]
  @FromDate DATE = NULL,
  @ToDate DATE = NULL,
  @StoreId INT = NULL
AS

/*
FileName:[SP_PHRM_GetReturnInvoicesBetweenDateRange] 
CreatedBy/date:  Ramesh/16thDec'21
Description:  Get Invoice Return Details for Pharmacy-> Duplicate Print
Change History
S.No.    UpdatedBy/Date                        Remarks
1.      Ramesh/26Apr'21                   Initial Draft
2.		Rohit/15Feb'21					  Fetched InvoiceReferenceNo for Multiple Invoice Return
*/
BEGIN
  SELECT
    inv.InvoiceId,
    invret.InvoiceReturnId,
    inv.InvoicePrintId,
	invret.ReferenceInvoiceNo,
    pat.FirstName + ISNULL(' ' + pat.MiddleName, '') + ' ' + pat.LastName AS PatientName,
    pat.Address ,
    pat.PhoneNumber AS 'ContactNumber',
    pat.PatientCode,
    pat.DateOfBirth,
    pat.Gender,
    invret.DiscountAmount,
    pat.IsOutdoorPat,
    invret.SubTotal,
    invret.TotalAmount,
	invret.DiscountAmount,
	invret.VATAmount,
    invret.PaidAmount,
    invret.PaymentMode,
    invret.CreatedOn 'CreateOn',
    invret.CreatedBy,
    invret.CreditNoteID,
    invret.Remarks,
	invret.PrintCount,
    CASE WHEN ISNULL(pat.IsOutdoorPat, 0) = 0 THEN 'Indoor' ELSE 'Outdoor' END AS PatientType,
    fy.FiscalYearFormatted AS FiscalYear,
    usr.UserName,
    pat.Ins_NshiNumber 'NSHINumber',
    invret.ClaimCode 'ClaimCode'
  FROM
    PHRM_TXN_InvoiceReturn invret
    LEFT JOIN PHRM_TXN_Invoice inv ON inv.InvoiceId = invret.InvoiceId
    INNER JOIN PAT_Patient pat ON pat.PatientId = invret.PatientId
    INNER JOIN BIL_CFG_FiscalYears fy ON invret.FiscalYearId = fy.FiscalYearId
    INNER JOIN RBAC_User usr ON invret.CreatedBy = usr.EmployeeId
  WHERE
  CONVERT(DATE, invret.CreatedOn) BETWEEN @FromDate AND @ToDate
    AND invret.StoreId = @StoreId
  ORDER BY invret.CreatedOn DESC
END