CREATE PROCEDURE [dbo].[SP_PHRM_GoodsReceiptProductReport] @FromDate DATE = NULL
	,@ToDate DATE = NULL
	,@ItemId INT = NULL
AS
/*
FileName: [SP_PHRM_GoodsReceiptProductReport] '2021-07-09','2021-08-09'
CreatedBy/date:Vikas/2018-08-10
Description: .
Remarks: 4Sept'21/sud: This report may be hidden for temporary purpose, will correct it later after proper requirement
Change History
S.No.    UpdatedBy/Date                        Remarks
1      Vikas/2018-08-10                created the script
2      Nagesh/2018-08-11                updated
3	   Abhishek/ 2018-09-7				updated
4	   Naveed/2019-12-13				updated script for exclude zero quantity Items
5      Ramesh/2021-08-01                show BillNo as well in Grid
6      Rohit/Ramesh/2021-08-08          show SubTotal and Total Amt in Grid 
7      Sud/Pawan:4Sept'21               * Added VATAmount Column in Return Table.
                                        * Taking GoodReceiptDate from GR table instead of CreatedOn of GRI table. 
										   since We're doing Stock Entry on GoodReceiptDate (Check TransactionDate table of StockTxnTable)
8      Rohit/13Feb'23						MRP-> SalePrice

*/
BEGIN
	BEGIN
		SELECT CONVERT(DATE, gr.GoodReceiptDate) AS [Date]
			,gr.GoodReceiptPrintId
			,gr.InvoiceNo
			,gri.ItemId
			,gri.ItemName
			,gri.BatchNo
			,gri.ReceivedQuantity
			,gri.FreeQuantity
			,gri.GRItemPrice AS [ItemPrice]
			,gri.SalePrice
			,spl.SupplierName
			,spl.ContactNo
			,gri.SubTotal
			,gri.TotalAmount
			,gri.GrPerItemVATAmt 'VATAmount'
		FROM PHRM_GoodsReceiptItems gri
		JOIN PHRM_GoodsReceipt gr ON gri.GoodReceiptId = gr.GoodReceiptId
		JOIN PHRM_MST_Supplier spl ON gr.SupplierId = spl.SupplierId
		WHERE CONVERT(DATE, gr.GoodReceiptDate) BETWEEN @FromDate
				AND @ToDate
			AND (
				gri.ItemId = @ItemId
				OR ISNULL(@ItemId, 0) = 0
				)
		ORDER BY CONVERT(DATE, gr.GoodReceiptDate) DESC
	END
END