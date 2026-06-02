CREATE PROCEDURE [dbo].[SP_Phrm_RankMembershipwiseSalesReport] @FromDate DATE = NULL
	,@ToDate DATE = NULL
	,@Ranks VARCHAR(500) = ''
	,@Memberships VARCHAR(1000) = ''
AS
/*
[SP_Phrm_RankMembershipwiseSalesReport] '2023-1-12'
FileName: [SP_Phrm_RankMembershipwiseSalesReport]
CreatedBy/date:Nirmala/2023-1-12
Description: .
Remarks:    A
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Nirmala/2023-1-12                created the script for Rank-Membership-Wise-Sales Report
*/
BEGIN
	SELECT invoice.CreateOn 'InvoiceDate'
		,invoice.InvoicePrintId 'InvoiceNo'
		,SUM(invoice.subtotal) 'SubTotal'
		,SUM(invoice.DiscountAmount) 'DiscountAmount'
		,SUM(invoice.TotalAmount) 'TotalAmount'
		,invoice.PaymentMode
		,ISNULL(pat.Rank, '') AS Rank
		,pat.ShortName 'PatientName'
		,pat.PatientCode 'HospitalNo'
		,mem.MembershipTypeName
		,store.Name 'Store'
		,emp.FullName 'User'
	FROM PHRM_TXN_Invoice invoice
	INNER JOIN pat_patient pat ON pat.PatientId = invoice.PatientId
	INNER JOIN PAT_CFG_MembershipType mem ON pat.MembershipTypeId = mem.MembershipTypeId
	INNER JOIN PHRM_MST_Store store ON store.StoreId = invoice.StoreId
	INNER JOIN EMP_Employee emp ON invoice.CreatedBy = emp.EmployeeId
	WHERE pat.Rank IS NOT NULL
		AND CONVERT(DATE, invoice.CreateOn) BETWEEN CONVERT(DATE, @FromDate)
			AND CONVERT(DATE, @ToDate)
		AND (
			pat.Rank IN (
				SELECT value
				FROM STRING_SPLIT(@Ranks, ',')
				)
			OR @Ranks = ''
			)
		AND (
			mem.MembershipTypeId IN (
				SELECT value
				FROM STRING_SPLIT(@Memberships, ',')
				)
			OR @Memberships = ''
			)
	GROUP BY invoice.PatientId
		,invoice.CreateOn
		,invoice.InvoicePrintId
		,pat.Rank
		,pat.ShortName
		,pat.PatientCode
		,invoice.PaymentMode
		,mem.MembershipTypeName
		,store.Name
		,emp.FullName
END