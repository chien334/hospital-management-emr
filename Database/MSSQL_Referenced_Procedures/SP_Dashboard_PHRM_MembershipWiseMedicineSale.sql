CREATE PROCEDURE SP_Dashboard_PHRM_MembershipWiseMedicineSale
   @FromDate datetime=NULL,
   @ToDate datetime=NULL

AS
 /*
 SP_Dashboard_PHRM_MembershipWiseMedicineSale '2022-10-3','2022-10-31'
FileName: [SP_Dashboard_PHRM_MembershipWiseMedicineSale]
CreatedBy/date: Rohit/2022-12-30
Description: To get information of Membership wise sales.
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Rohit/2022-12-30                 created the script
*/
BEGIN

SELECT TOP 10 mem.MembershipTypeName
	,SUM(invoice.TotalAmount) 'TotalSales'
	,SUM(invoice.Quantity) 'QuantitySold'
FROM PAT_Patient pat
INNER JOIN PAT_CFG_MembershipType mem ON pat.MembershipTypeId = mem.MembershipTypeId
INNER JOIN (
		SELECT inv.PatientId,
			SUM(inv.SubTotal) 'TotalAmount',
			SUM(invitm.Quantity) 'Quantity'
		FROM PHRM_TXN_Invoice inv
		INNER JOIN PHRM_TXN_InvoiceItems invitm ON inv.InvoiceId = invitm.InvoiceId
		WHERE CONVERT(DATE, inv.CreateOn) BETWEEN @FromDate AND @ToDate
		GROUP BY inv.PatientId
	) invoice ON invoice.PatientId = pat.PatientId
GROUP BY mem.MembershipTypeName
ORDER BY SUM(invoice.TotalAmount) DESC
END