CREATE PROCEDURE [dbo].[SP_Report_BILL_Invoice_Return] 
      @FromDate DateTime=null,
      @ToDate DateTime=null
    
AS
/*
FileName: [SP_BILL_Report_Invoice_Return]
CreatedBy/date: Ashim/24-07-2017
Description: This sp will give sum of total amount return by each item along with its necesorry details recipt no, hospital no, patient name, service department name,return date, and return remarks
Remarks:   
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Ashim/09-05-2017                created the script
2.      Sud:26Aug'21                   * Converting the comparision to type=DATE, earlier it was DateTime
                                       * Taking EmployeeName and PatientName from single column (FullName, ShortName) of respective tables.  
*/
BEGIN
        SELECT
                CONVERT(DATE,br.CreatedOn) AS [Date],
                br.BillingTransactionId,
                (br.FiscalYear + '-' + br.InvoiceCode + CONVERT(varchar(10), br.RefInvoiceNum) ) AS RefInvoiceNo,
                p.PatientCode,
                p.ShortName AS PatientName,
				br.BillReturnId,
                br.CreditNoteNumber,
                br.SubTotal,
                br.DiscountAmount,
                br.TaxableAmount,
                br.TaxTotal,
                br.TotalAmount,
				br.PaymentMode,
                br.Remarks,
				cntr.CounterName,
                emp.FullName  as 'User'
        FROM    BIL_TXN_InvoiceReturn br
        JOIN    PAT_Patient p ON p.PatientId=br.PatientId
        JOIN    EMP_Employee emp ON emp.EmployeeId = br.CreatedBy
		JOIN	BIL_CFG_Counter cntr ON br.CounterId = cntr.CounterId
        WHERE  CONVERT(DATE,br.CreatedOn)
                  BETWEEN Convert(Date,@FromDate) and Convert(Date,@ToDate)
        ORDER BY  CONVERT(DATE,br.CreatedOn) desc
END