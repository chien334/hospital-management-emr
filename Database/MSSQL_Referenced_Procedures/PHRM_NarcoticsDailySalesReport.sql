CREATE PROCEDURE [dbo].[PHRM_NarcoticsDailySalesReport] @FromDate DATE = NULL
	,@ToDate DATE = NULL
	,@ItemId INT = NULL
	,@StoreId INT = NULL
AS
/*
FileName: [PHRM_NarcoticsDailySalesReport]
CreatedBy/date: Rohit/1Feb'22
Description: To get the narcotics daily sales information 
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Rohit/1Feb'22                        created the script
2       Rohit/28Apr'22                       Do not show Return Narcotics sale(updated)
3       Rusha/21thJuly22				     Added Generic name in column
4.		Rohit/13Feb'23						MRP-> SalePrice
*/
BEGIN
	SELECT InvoicePrintId
		,InvoiceId
		,ItemId
		,ItemName
		,GenericName
		,BatchNo
		,Quantity
		,SalePrice
		,Price
		,TotalAmount
		,CreatedOn
		,PatientName
		,DoctorName
		,NMCNumber
	FROM (
		SELECT inv.InvoicePrintId
			,inv.InvoiceId
			,mstitm.ItemId
			,mstitm.ItemName
			,gen.GenericName
			,invitm.BatchNo
			,invitm.Quantity - ISNULL(retitm.ReturnedQty, 0) 'Quantity'
			,invitm.SalePrice
			,invitm.Price
			,invitm.TotalAmount - ISNULL(retitm.ReturnTotal, 0) 'TotalAmount'
			,inv.CreateOn AS CreatedOn
			,pet.FirstName + ' ' + ISNULL(pet.MiddleName, '') + ' ' + pet.LastName AS PatientName
			,e.FullName AS DoctorName
			,e.MedCertificationNo AS NMCNumber
		FROM PHRM_TXN_InvoiceItems invitm
		LEFT JOIN (
			SELECT invretitm.InvoiceItemId
				,SUM(ISNULL(invretitm.ReturnedQty, 0)) 'ReturnedQty'
				,SUM(ISNULL(invretitm.TotalAmount, 0)) 'ReturnTotal'
			FROM PHRM_TXN_InvoiceReturnItems invretitm
			GROUP BY invretitm.InvoiceItemId
			) retitm ON invitm.InvoiceItemId = retitm.InvoiceItemId
		INNER JOIN PHRM_TXN_Invoice inv ON invitm.InvoiceId = inv.InvoiceId
		INNER JOIN PHRM_MST_Item mstitm ON invitm.ItemId = mstitm.ItemId
		LEFT JOIN PHRM_MST_Generic gen ON mstitm.GenericId = gen.GenericId
		INNER JOIN PAT_Patient pet ON inv.PatientId = pet.PatientId
		INNER JOIN EMP_Employee emp ON inv.CreatedBy = emp.EmployeeId
		LEFT JOIN EMP_Employee e ON inv.PrescriberId = e.EmployeeId
		WHERE mstitm.IsNarcotic = 1
			AND (
				CONVERT(DATE, inv.CreateOn) BETWEEN @FromDate
					AND @ToDate
				)
			AND (
				invitm.ItemId = @ItemId
				OR @ItemId IS NULL
				)
			AND (
				inv.StoreId = @StoreId
				OR @StoreId IS NULL
				)
		) TBL
	WHERE Quantity > 0
	ORDER BY InvoiceId DESC
END