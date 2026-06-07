CREATE PROCEDURE [dbo].[SP_PHRMReport_PurchaseOrderSummaryReport] 
	 @FromDate DATETIME = NULL
	,@ToDate DATETIME = NULL
	,@Status NVARCHAR(50) = NULL
AS
/*
FileName: [SP_PHRMReport_PurcaseOrderSummary] '2022/04/14','2022/07/19',''
CreatedBy/date: Umed/2017-11-23
Description: .
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Umed/2017-05-25	                     created the script
2		Rusha/2019-04-26					 Recreated of Script
3		Naveed/2019-12-13					 updated script for exclude zero quantity Items from Report
4		Rohit/2022-05-10					 Total Amount Mismatch resolve (Before it was taking MainLevel Total Amount)
5       Rusha/21thJuly22				     Added Generic name in column
6.		Rohit/28Mar'23						 Alter Column Name StandardRate -> SalePrice
7.		Nirmala/4Jul'23						 Alter Column Name SalePrice -> StandardRate
*/
BEGIN
	IF (
			(@FromDate IS NOT NULL)
			)
		AND (@Status IS NOT NULL)
	BEGIN

		IF (@Status = 'all')
		BEGIN
			SELECT convert(DATE, PO.PODate) AS [Date]
				,itm.ItemName
				,gen.GenericName
				,po.POStatus
				,poitm.Subtotal
				,poitm.VATAmount
				,poitm.TotalAmount
				,sum(poitm.Quantity) AS Quantity
				,poitm.StandardRate
				,sum(poitm.ReceivedQuantity) AS ReceivedQuantity
			FROM PHRM_PurchaseOrder AS po
			JOIN PHRM_PurchaseOrderItems AS poitm ON poitm.PurchaseOrderId = po.PurchaseOrderId
			JOIN PHRM_MST_Item AS itm ON itm.ItemId = poitm.ItemId
			JOIN PHRM_MST_Generic AS gen ON itm.GenericId = gen.GenericId
			WHERE convert(DATETIME, PO.PODate) BETWEEN ISNULL(@FromDate, GETDATE())
					AND ISNULL(@ToDate, GETDATE()) + 1
				AND poitm.Quantity > 0
			GROUP BY convert(DATE, PO.PODate)
				,itm.ItemName
				,gen.GenericName
				,po.POStatus
				,poitm.Subtotal
				,poitm.VATAmount
				,poitm.TotalAmount
				,poitm.Quantity
				,poitm.StandardRate
				,poitm.ReceivedQuantity
			ORDER BY convert(DATE, PO.PODate) DESC;
		END

		ELSE IF (@Status = 'active')
		BEGIN
			SELECT convert(DATE, PO.PODate) AS [Date]
				,itm.ItemName
				,gen.GenericName
				,po.POStatus
				,poitm.Subtotal
				,poitm.VATAmount
				,poitm.TotalAmount
				,sum(poitm.Quantity) AS Quantity
				,poitm.StandardRate
				,sum(poitm.ReceivedQuantity) AS ReceivedQuantity
			FROM PHRM_PurchaseOrder AS po
			JOIN PHRM_PurchaseOrderItems AS poitm ON poitm.PurchaseOrderId = po.PurchaseOrderId
			JOIN PHRM_MST_Item AS itm ON itm.ItemId = poitm.ItemId
			JOIN PHRM_MST_Generic AS gen ON itm.GenericId = gen.GenericId
			WHERE po.POStatus = 'active'
				AND convert(DATETIME, PO.PODate) BETWEEN ISNULL(@FromDate, GETDATE())
					AND ISNULL(@ToDate, GETDATE()) + 1
				AND poitm.Quantity > 0
			GROUP BY convert(DATE, PO.PODate)
				,itm.ItemName
				,gen.GenericName
				,po.POStatus
				,poitm.Subtotal
				,poitm.VATAmount
				,poitm.TotalAmount
				,poitm.Quantity
				,poitm.StandardRate
				,poitm.ReceivedQuantity
			ORDER BY convert(DATE, PO.PODate) DESC;
		END

		ELSE IF (@Status = 'complete')
		BEGIN
			SELECT convert(DATE, PO.PODate) AS [Date]
				,itm.ItemName
				,gen.GenericName
				,po.POStatus
				,poitm.Subtotal
				,poitm.VATAmount
				,poitm.TotalAmount
				,sum(poitm.Quantity) AS Quantity
				,poitm.StandardRate
				,sum(poitm.ReceivedQuantity) AS ReceivedQuantity
			FROM PHRM_PurchaseOrder AS po
			JOIN PHRM_PurchaseOrderItems AS poitm ON poitm.PurchaseOrderId = po.PurchaseOrderId
			JOIN PHRM_MST_Item AS itm ON itm.ItemId = poitm.ItemId
			JOIN PHRM_MST_Generic AS gen ON itm.GenericId = gen.GenericId
			WHERE po.POStatus = 'complete'
				AND convert(DATETIME, PO.PODate) BETWEEN ISNULL(@FromDate, GETDATE())
					AND ISNULL(@ToDate, GETDATE()) + 1
				AND poitm.Quantity > 0
			GROUP BY convert(DATE, PO.PODate)
				,itm.ItemName
				,gen.GenericName
				,po.POStatus
				,poitm.Subtotal
				,poitm.VATAmount
				,poitm.TotalAmount
				,poitm.Quantity
				,poitm.StandardRate
				,poitm.ReceivedQuantity
			ORDER BY convert(DATE, PO.PODate) DESC;
		END
	END
END