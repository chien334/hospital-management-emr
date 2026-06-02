CREATE PROCEDURE [dbo].[SP_PHRMReport_ReturnFromCustomerReport] @FromDate DATE = NULL
	,@ToDate DATE = NULL
	,@UserId INT = NULL
	,@DispensaryId INT = NULL
AS
/*
 FileName: [SP_PHRMReport_ReturnFromCustomerReport] 
 Created: 2021-05-01/ramesh
 Description: To get details about return from Customer
 Example to execute the stored procedure we just created:
	EXECUTE dbo.SP_PHRMReport_ReturnFromCustomerReport '2021-05-01','2021-07-13'
 Remarks: 
 Change History
 S.No.    Date/User              Change          Remarks
 1.	     2021-05-01/Ramesh		                inital draft
 2.      2021-07-30/Ramesh                      Add DispensaryWise Filter and Show Dispensary Name in grid.
 3.		 2021-09-01/Sanjit						Added PatientName and Hospital Code, Removed StockTxn from JOIN Logic, instead used as nested query for ExpiryDate
 4.      Rohit/13Feb'23						    MRP-> SalePrice
*/
BEGIN
	-- body of the stored procedure
	SELECT G.GenericName
		,I.ItemName
		,CONVERT(DATE, IR.CreatedOn) AS ReturnedDate
		,IRI.CreditNoteNumber AS CreditNoteNumber
		,E.FullName AS UserName
		,C.CounterName
		,IRI.ReturnedQty
		,IRI.SalePrice
		,IRI.BatchNo
		,
		--> must remove the dependency from stock transaction table asap
		(
			SELECT TOP (1) ExpiryDate
			FROM PHRM_TXN_StockTransaction ST
			WHERE IRI.InvoiceReturnItemId = ST.ReferenceNo
				AND (
					ST.TransactionType = 'sale-returned-item'
					OR ST.TransactionType = 'manual-sales-return'
					)
			) AS ExpiryDate
		,ISNULL(IRI.TotalAmount, 0) AS TotalAmount
		,'PH' + ISNULL(CONVERT(VARCHAR(MAX), INV.InvoicePrintId), IR.ReferenceInvoiceNo) AS IssueNo
		,S.Name AS DispensaryName
		,PAT.PatientCode
		,PAT.ShortName AS PatientName
	FROM PHRM_TXN_InvoiceReturnItems IRI
	INNER JOIN PHRM_TXN_InvoiceReturn IR ON IRI.InvoiceReturnId = IR.InvoiceReturnId
	LEFT JOIN PHRM_TXN_Invoice INV ON IR.InvoiceId = INV.InvoiceId -- Left join For Manual Sales Return
	INNER JOIN PAT_Patient PAT ON INV.PatientId = PAT.PatientId
	INNER JOIN PHRM_MST_Item I ON IRI.ItemId = I.ItemId
	INNER JOIN PHRM_MST_Generic G ON I.GenericId = G.GenericId
	INNER JOIN EMP_Employee E ON IRI.CreatedBy = E.EmployeeId
	INNER JOIN PHRM_MST_Counter C ON IRI.CounterId = C.CounterId
	INNER JOIN PHRM_MST_Store S ON IRI.StoreId = S.StoreId
	WHERE (
			IRI.CreatedBy = @UserId
			OR @UserId IS NULL
			AND IRI.StoreId = @DispensaryId
			OR @DispensaryId IS NULL
			)
		AND CONVERT(DATE, IR.CreatedOn) BETWEEN @FromDate
			AND @ToDate
END