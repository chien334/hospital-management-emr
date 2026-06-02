CREATE PROCEDURE [dbo].[PHRM_RPT_PatientSalesDetail] @FromDate DATETIME = '2021-01-01'
	,@ToDate DATETIME = '2022-01-01'
	,@CounterId INT = NULL
	,@UserId INT = NULL
	,@StoreId INT = NULL
	,@PatientId INT = NULL
AS
-- =============================================
-- Author:		Sanjit
-- Create date: 17Jun'21
-- Description: generated patientwise sales report
-- =============================================
/* Change History
S.No.    UpdatedBy/Date                        Remarks
1.       sanjit/17Jun'21          			cretated script
2.		 Rohit/25Jul'22						Date is Converted
3        Rohit/13Feb'23						MRP-> SalePrice
*/
BEGIN
	-- body of the stored procedure
	SELECT X.*
	FROM (
		SELECT 'Sale' AS Type
			,I.CreateOn 'Date'
			,I.InvoiceId
			,I.InvoicePrintId
			,PAT.PatientCode 'HospitalNo'
			,PAT.FirstName + ' ' + ISNULL(PAT.MiddleName + ' ', '') + PAT.LastName 'PatientName'
			,PAT.ShortName
			,GEN.GenericName
			,ITM.ItemCode
			,ITM.ItemName
			,II.BatchNo
			,II.ExpiryDate
			,II.Price
			,II.SalePrice
			,II.Quantity
			,PAT.Ins_NshiNumber
			,I.ClaimCode
			,II.SubTotal
			,II.TotalAmount
			,E.FullName 'CreatedByName'
			,C.CounterName
		FROM PHRM_TXN_InvoiceItems II
		JOIN PHRM_MST_Item ITM ON II.ItemId = ITM.ItemId
		JOIN PHRM_MST_Generic GEN ON ITM.GenericId = GEN.GenericId
		JOIN PHRM_TXN_Invoice I ON II.InvoiceId = I.InvoiceId
		JOIN PAT_Patient PAT ON I.PatientId = PAT.PatientId
		JOIN EMP_Employee E ON I.CreatedBy = E.EmployeeId
		JOIN PHRM_MST_Counter C ON I.CounterId = C.CounterId
		WHERE Convert(DATE, I.CreateOn) BETWEEN @FromDate
				AND @ToDate
			AND (
				I.PatientId = @PatientId
				OR @PatientId IS NULL
				)
			AND (
				I.CounterId = @CounterId
				OR @CounterId IS NULL
				)
			AND (
				I.CreatedBy = @UserId
				OR @UserId IS NULL
				)
			AND (
				I.StoreId = @StoreId
				OR @StoreId IS NULL
				)
		
		UNION ALL
		
		SELECT 'Sales Refund' AS Type
			,I.CreatedOn 'Date'
			,I.InvoiceId
			,I.CreditNoteID
			,PAT.PatientCode 'HospitalNo'
			,PAT.FirstName + ' ' + ISNULL(PAT.MiddleName + ' ', '') + PAT.LastName 'PatientName'
			,PAT.ShortName
			,GEN.GenericName
			,ITM.ItemCode
			,ITM.ItemName
			,II.BatchNo
			,IITM.ExpiryDate
			,II.Price
			,II.SalePrice
			,II.ReturnedQty AS Quantity
			,PAT.Ins_NshiNumber
			,I.ClaimCode
			,II.SubTotal
			,II.TotalAmount
			,E.FullName 'CreatedByName'
			,C.CounterName
		FROM PHRM_TXN_InvoiceReturnItems II
		JOIN PHRM_MST_Item ITM ON II.ItemId = ITM.ItemId
		JOIN PHRM_MST_Generic GEN ON ITM.GenericId = GEN.GenericId
		JOIN PHRM_TXN_InvoiceReturn I ON II.InvoiceReturnId = I.InvoiceReturnId
		JOIN PHRM_TXN_InvoiceItems IITM ON II.InvoiceItemId = IITM.InvoiceItemId
		JOIN PAT_Patient PAT ON I.PatientId = PAT.PatientId
		JOIN EMP_Employee E ON I.CreatedBy = E.EmployeeId
		JOIN PHRM_MST_Counter C ON I.CounterId = C.CounterId
		WHERE Convert(DATE, I.CreatedOn) BETWEEN @FromDate
				AND @ToDate
			AND (
				I.PatientId = @PatientId
				OR @PatientId IS NULL
				)
			AND (
				I.CounterId = @CounterId
				OR @CounterId IS NULL
				)
			AND (
				I.CreatedBy = @UserId
				OR @UserId IS NULL
				)
			AND (
				I.StoreId = @StoreId
				OR @StoreId IS NULL
				)
		) X
	ORDER BY X.[Date]
END