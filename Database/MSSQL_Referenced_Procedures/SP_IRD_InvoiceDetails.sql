CREATE PROCEDURE [dbo].[SP_IRD_InvoiceDetails]
    @FromDate Datetime = null,
    @ToDate DateTime = null
AS
  /*
    FileName: [SP_IRD_InvoiceDetails] 
    CreatedBy/date: Umed/2017-09-294
    Description: to get the Invoice Details as per IRD requirements 
    Change History
    S.No.    UpdatedBy/Date         Remarks
    1        Sud/2018-May-7         revised as per new ird requirements    
    2        Ramavtar/07Dec         applying filter on CreatedOn instead of PaidDate 
    3.       Vikas/02 Jan 2019      modify patient shortname(firstname and last name) to fullname(first,middle, and lastName)   
    4.       Sud/2Jul'21            Setting Is_Bill_Active=False if One or more CreditNote generated from current invoice.
                                    Taking Customer_name from Patient>ShortName field
    5.       Shankar/20thSept'21    Update for Payment_Method and TransactionId columns(revised as per new ird requirements)
    6.       Anish/3 December 2021  Getting the data of Return as well 
    7.       Ramesh/Dev 6 Dec 2021  Merged the billing IRD_InvoiceDetails sp with pharmachy IRD_InvoiceDetails sp
	8.       Ramesh/17th Dec'21     Remove CR in pharmacy cash sale invoice
    */
  BEGIN
    IF (@FromDate IS NOT NULL)
        OR (@ToDate IS NOT NULL) 
  BEGIN
        SET
  NOCOUNT ON
        SELECT *
        FROM
            (
                                                        (
                                SELECT
                    fiscYr.FiscalYearFormatted AS Fiscal_Year,
                    CONVERT(varchar(30), ret.CreditNoteNumber) AS Bill_No,
                    pats.ShortName AS Customer_name,
                    --sud:2July'21--revised column to take Customer_name
                    pats.PANNumber,
                    CONVERT( datetime,  ret.ReturnedOn) AS BillDate,
                    ret.ReturnSubTotal AS Amount,
                    ret.ReturnDiscountAmount AS DiscountAmount,
                    CONVERT(float,0.00) AS Taxable_Amount,
                    CONVERT(float,0.00) AS Tax_Amount,
                    ret.ReturnTotalAmount AS Total_Amount,
                    CASE WHEN ret.IsReturnSyncedWithIRD = 1 THEN 'Yes' ELSE 'No' END  AS SyncedWithIRD,
                    CASE WHEN biltxn.PrintCount > 0 THEN 'Yes' ELSE 'No' END AS Is_Printed,
                    CONVERT(varchar(20), CONVERT(time, ret.ReturnedOn), 100)AS Printed_Time,
                    ret.ReturnedBy AS Entered_By,
                    ret.ReturnedBy AS Printed_by,
                    --might need to change logic for isrealtime--: sud:9May'18--  
                    CASE WHEN ISNULL(ret.IsReturnRealTime, 0) = 1 THEN 'Yes' ELSE 'No' END AS Is_Realtime,
                    --CASE
                    --  WHEN ISNULL(biltxn.ReturnStatus, 0) = 0 THEN 'True'
                    --  ELSE 'False'
                    --END AS Is_Bill_Active
                    'True' AS Is_Bill_Active,
                    ret.ReturnPaymentMethod AS Payment_Method,
                    'N/A' as TransactionId,
                    CONVERT(float,0.00) as VAT_Refund_Amount
                FROM
                    BIL_TXN_BillingTransaction biltxn
                    INNER JOIN EMP_Employee emp ON emp.EmployeeId = biltxn.CreatedBy
                    INNER JOIN PAT_Patient pats ON pats.PatientId = biltxn.PatientId
                    INNER JOIN BIL_CFG_FiscalYears fiscYr ON biltxn.FiscalYearId = fiscYr.FiscalYearId
                    INNER JOIN(
    Select
                        BillingTransactionId 'ReturnTxnId',
                        'CRN' + CONVERT(varchar(10),CreditNoteNumber) 'CreditNoteNumber',
                        -SubTotal 'ReturnSubTotal',
                        -DiscountAmount 'ReturnDiscountAmount',
                        -TotalAmount 'ReturnTotalAmount',
                        IsRemoteSynced 'IsReturnSyncedWithIRD',
                        1 as ReturnPrintCount,
                        0 as 'ReturnVATRefundAmount',
                        e.FullName 'ReturnedBy',
                        r.CreatedOn 'ReturnedOn',
                        PaymentMode as 'ReturnPaymentMethod',
                        IsRealtime as 'IsReturnRealTime'
                    from
                        BIL_TXN_InvoiceReturn r
                        join EMP_Employee e on r.CreatedBy=e.EmployeeId
                    Where
      r.IsActive = 1
  ) ret ON biltxn.BillingTransactionId = ret.ReturnTxnId
                WHERE
  CONVERT(date, biltxn.CreatedOn) BETWEEN CONVERT(date, @FromDate) 
  AND CONVERT(date, @ToDate)
                )
            UNION ALL
                (
                SELECT
                    fiscYr.FiscalYearFormatted AS Fiscal_Year,
                    ISNULL(biltxn.InvoiceCode, 'BL') + CONVERT(varchar(30), biltxn.InvoiceNo) AS Bill_No,
                    pats.ShortName AS Customer_name,
                    --sud:2July'21--revised column to take Customer_name
                    pats.PANNumber,
                    CONVERT( datetime, biltxn.CreatedOn) AS BillDate,
                    biltxn.SubTotal AS Amount,
                    biltxn.DiscountAmount AS DiscountAmount,
                    CONVERT(float,0.00) AS Taxable_Amount,
                    CONVERT(float,0.00) AS Tax_Amount,
                    biltxn.TotalAmount AS Total_Amount,
                    CASE WHEN biltxn.IsRemoteSynced = 1 THEN 'Yes' ELSE 'No' END AS SyncedWithIRD,
                    CASE WHEN biltxn.PrintCount > 0 THEN 'Yes' ELSE 'No' END AS Is_Printed,
                    CONVERT(varchar(20), CONVERT(time, biltxn.CreatedOn), 100)AS Printed_Time,
                    emp.FullName AS Entered_By,
                    emp.FullName AS Printed_by,
                    --might need to change logic for isrealtime--: sud:9May'18--  
                    CASE WHEN ISNULL(biltxn.IsRealtime, 0) = 1 THEN 'Yes' ELSE 'No' END AS Is_Realtime,
                    --CASE
                    --  WHEN ISNULL(biltxn.ReturnStatus, 0) = 0 THEN 'True'
                    --  ELSE 'False'
                    --END AS Is_Bill_Active
                    'True' AS Is_Bill_Active,
                    biltxn.PaymentMode as Payment_Method,
                    'N/A' as TransactionId,
                    CONVERT(float,0.00) as VAT_Refund_Amount
                FROM
                    BIL_TXN_BillingTransaction biltxn
                    INNER JOIN EMP_Employee emp ON emp.EmployeeId = biltxn.CreatedBy
                    INNER JOIN PAT_Patient pats ON pats.PatientId = biltxn.PatientId
                    INNER JOIN BIL_CFG_FiscalYears fiscYr ON biltxn.FiscalYearId = fiscYr.FiscalYearId
                WHERE
  CONVERT(date, biltxn.CreatedOn) BETWEEN CONVERT(date, @FromDate) 
  AND CONVERT(date, @ToDate) 
  )
            UNION ALL
            (
                            SELECT
                    fisc.FiscalYearFormatted AS Fiscal_Year,
                    ret.CreditNoteNumber AS Bill_No,
                    pat.ShortName AS Customer_name,
                    pat.PANNumber,
                    CONVERT( datetime, ret.ReturnedOn) AS BillDate,
                    --ret.ReturnedOn AS BillDate,
                    ret.ReturnSubTotal AS Amount,
                    ret.ReturnDiscountAmount AS DiscountAmount,
                    CONVERT(float,0.00) AS Taxable_Amount,
                    CONVERT(float,0.00) AS Tax_Amount,
                    ret.ReturnTotalAmount AS Total_Amount,
                    CASE WHEN ret.IsReturnSyncedWithIRD = 1 THEN 'Yes' ELSE 'No' END  AS SyncedWithIRD,
                    CASE WHEN inv.PrintCount > 0 THEN 'Yes' ELSE 'No' END AS Is_Printed,
                    CONVERT( varchar(20), CONVERT(time, ret.ReturnedOn), 100)AS Printed_Time,
                    ret.ReturnedBy  AS Entered_By,
                    ret.ReturnedBy AS Printed_by,
                    --might need to change logic for isrealtime--: sud:9May'18--  
                    CASE WHEN ISNULL(ret.IsReturnRealTime, 0) = 1 THEN 'Yes' ELSE 'No' END AS Is_Realtime,
                    'True' AS Is_Bill_Active,
                    ret.ReturnPaymentMethod AS Payment_Method,
                    'N/A' AS TransactionId,
                    CONVERT(float,0.00) AS VAT_Refund_Amount
                FROM PHRM_TXN_Invoice inv
                    INNER JOIN EMP_Employee emp ON emp.EmployeeId=inv.CreatedBy
                    INNER JOIN PAT_Patient pat ON pat.PatientId=inv.PatientId
                    INNER JOIN BIL_CFG_FiscalYears fisc ON inv.FiscalYearId=fisc.FiscalYearId
                    INNER JOIN(
        SELECT
                        InvoiceId 'ReturnTxnId',
                        'CR-PH' + CONVERT(varchar(10),CreditNoteID) 'CreditNoteNumber',
                        -SubTotal 'ReturnSubTotal',
                        -DiscountAmount 'ReturnDiscountAmount',
                        -TotalAmount 'ReturnTotalAmount',
                        IsRemoteSynced 'IsReturnSyncedWithIRD',
                        1 AS ReturnPrintCount,
                        0 AS 'ReturnVATRefundAmount',
                        e.FullName 'ReturnedBy',
                        invRet.CreatedOn 'ReturnedOn',
                        PaymentMode AS 'ReturnPaymentMethod',
                        IsRealtime AS 'IsReturnRealTime'
                    FROM
                        PHRM_TXN_InvoiceReturn invRet
                        JOIN EMP_Employee e ON invRet.CreatedBy=e.EmployeeId
                        JOIN PHRM_CFG_FiscalYears fisc ON invRet.FiscalYearId = fisc.FiscalYearId
     ) ret
                    ON inv.InvoiceId = ret.ReturnTxnId
                WHERE (CONVERT(DATE,inv.CreateOn) BETWEEN CONVERT(DATE,@FromDate) AND CONVERT(DATE,@ToDate))
            UNION ALL
                (
                SELECT
                    fiscYr.FiscalYearFormatted AS Fiscal_Year,
                    'PH' + CONVERT(varchar(30), inv.InvoicePrintId) AS Bill_No,
                    pats.ShortName AS Customer_name,
                    --sud:2July'21--revised column to take Customer_name
                    pats.PANNumber,
                    CONVERT( datetime, inv.CreateOn) AS BillDate,
                    inv.SubTotal AS Amount,
                    inv.DiscountAmount AS DiscountAmount,
                    CONVERT(float,0.00) AS Taxable_Amount,
                    CONVERT(float,0.00) AS Tax_Amount,
                    inv.TotalAmount AS Total_Amount,
                    CASE WHEN inv.IsRemoteSynced = 1 THEN 'Yes' ELSE 'No' END  AS SyncedWithIRD,
                    CASE WHEN inv.PrintCount > 0 THEN 'Yes' ELSE 'No' END AS Is_Printed,
                    CONVERT(varchar(20), CONVERT(time, inv.CreateOn), 100)AS Printed_Time,
                    emp.FullName AS Entered_By,
                    emp.FullName AS Printed_by,
                    --might need to change logic for isrealtime--: sud:9May'18--  
                    CASE WHEN ISNULL(inv.IsRealtime, 0) = 1 THEN 'Yes' ELSE 'No' END AS Is_Realtime,
                    'True' AS Is_Bill_Active,
                    inv.PaymentMode as Payment_Method,
                    'N/A' as TransactionId,
                    CONVERT(float,0.00) as VAT_Refund_Amount
                FROM
                    PHRM_TXN_Invoice inv
                    INNER JOIN EMP_Employee emp ON emp.EmployeeId = inv.CreatedBy
                    INNER JOIN PAT_Patient pats ON pats.PatientId = inv.PatientId
                    INNER JOIN BIL_CFG_FiscalYears fiscYr ON inv.FiscalYearId = fiscYr.FiscalYearId
                WHERE
  CONVERT(date, inv.CreateOn) BETWEEN CONVERT(date, @FromDate) AND CONVERT(date, @ToDate))
  )
  )
  AS IRDDetails
        ORDER BY IRDDetails.BillDate DESC
    END
END