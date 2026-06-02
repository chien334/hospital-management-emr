CREATE PROCEDURE [dbo].[SP_PHRMReport_BillingReport]
	@FromDate Date = NULL,
	@ToDate Date = NULL,
	@InvoiceNumber int = NULL

AS
/*
FileName: [SP_PHRMReport_BillingReport]
CreatedBy/date: Umed/2018-02-23
Description: To get the Details Such As ItemName, ItemCode, Expiry, PurchaseRate, PurchaseValue,SalesRate, SalesValue of Each Item Against Each Invoice Number
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Umed/2018-02-23             created the script
                                    (To get the Details Such As ItemName, ItemCode, Expiry, PurchaseRate, PurchaseValue,SalesRate, SalesValue of Each Item Against Each Invoice Number)
2       Rusha/2019-04-29            Recreated the Script
3.      Sanjit/Sud/2021-08-10       Removed group by from the query
4.		Sanjit/Sud/Pawan/2021-09-01	Removed double query for InvoiceNumber Null Check, changed DateTime to Date in @FromDate, @ToDate
									Removed @ToDate+1 Logic from Where Condition
									Added SubTotal, StoreName, StoreId
5.		Rohit/12Sept'22				Added Received Amount and CreditAmount and also ordered by invoice created date
*/

BEGIN
	SELECT CONVERT(DATE,inv.CreateOn) AS [InvoiceDate], inv.InvoicePrintId, pat.PatientCode AS HospitalNo, pat.ShortName AS PatientName, emp.FullName AS UserName, inv.SubTotal, inv.DiscountAmount, inv.TotalAmount,inv.ReceivedAmount,inv.TotalAmount-inv.ReceivedAmount 'CreditAmount', inv.PaymentMode, store.Name AS StoreName, store.StoreId
	FROM PHRM_TXN_Invoice AS  inv
		INNER JOIN PAT_Patient AS pat ON pat.PatientId=inv.PatientId
		INNER JOIN EMP_Employee AS emp ON inv.CreatedBy = emp.EmployeeId
		INNER JOIN PHRM_MST_Store store ON inv.StoreId = store.StoreId
	WHERE (inv.InvoicePrintId = @InvoiceNumber OR ISNULL(@InvoiceNumber,0) = 0) AND ( CONVERT (Date, inv.CreateOn) BETWEEN @FromDate AND @ToDate )
	ORDER BY inv.InvoicePrintId desc
END