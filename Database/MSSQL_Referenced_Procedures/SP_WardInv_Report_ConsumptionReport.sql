CREATE PROCEDURE [dbo].[SP_WardInv_Report_ConsumptionReport] @FromDate DATETIME = NULL
	,@ToDate DATETIME = NULL
	,@StoreId INT = NULL
AS
/*
FileName: [SP_WardInv_Report_ConsumptionReport] '2022-04-02','2022-04-02','41'
CreatedBy/date: Rusha/06-25-2019
Description: To get the Consumption Details of Inventory Items Consume by Ward
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1.		Rusha/07-12-2019					only show consumable items
2.		Rohit/2Feb'22						Fetched UnitOfMeasurement,ItemRate,TotalConsumedValue and also order by CreatedOn in descending order.
3.		Rohit/3Apr'22						Fetched Remarks(& PatientCode,PatientName for Patient Consumption) and also ConsumptionReceiptId (for      patient consumption)
4.		Rohit/13Apr'22						Remove Department Column
5.		Rohit/22Apr'22					    Join WARD_INV_Consumption and INV_MST_Stock with StockId to get the exact cost price of ConsumptionItem.
6.		Rohit/31Oct'22					    CreatedOn-> ConsumptionDate
7.      Nirmala/8Nov'22                     remove current date filter
8.      Nirmala/23Jan'23                    Fetch SubcategoryId and SubCategoryName
*/
BEGIN
	IF (
			(@FromDate IS NOT NULL)
			AND (@ToDate IS NOT NULL)
			)
	BEGIN
		SELECT CONVERT(DATE, con.ConsumptionDate) AS [Date]
			,con.ItemName
			,con.Quantity
			,uom.UOMName
			,UsedBy AS [User]
			,(con.Remark + '[' + (p.PatientCode) + '   (' + p.FirstName + ISNULL(p.MiddleName, ' ') + p.LastName + ')]') AS 'Remark'
			,stk.CostPrice
			,con.Quantity * stk.CostPrice AS TotalConsumedValue
			,con.ConsumptionReceiptId
			,itemcategory.SubCategoryId
			,itemcategory.SubCategoryName
		FROM WARD_INV_Consumption AS con
		LEFT JOIN WARD_INV_ConsumptionReceipt cr ON con.ConsumptionReceiptId = cr.ConsumptionReceiptId
		LEFT JOIN PAT_Patient p ON cr.PatientId = p.PatientId
		INNER JOIN INV_MST_Stock stk ON con.StockId = stk.StockId
		INNER JOIN INV_MST_Item AS itm ON con.ItemId = itm.ItemId
		INNER JOIN INV_MST_ItemSubCategory AS itemcategory ON itm.SubCategoryId = itemcategory.SubCategoryId
		INNER JOIN INV_MST_UnitOfMeasurement uom ON itm.UnitOfMeasurementId = uom.UOMId
		WHERE con.StoreId = @StoreId
			AND CONVERT(DATE, con.ConsumptionDate) BETWEEN @FromDate
				AND @ToDate
			AND itm.ItemType = 'Consumables'
		GROUP BY con.ConsumptionDate
			,con.ItemName
			,con.Quantity
			,UsedBy
			,con.Remark
			,stk.CostPrice
			,uom.UOMName
			,con.ConsumptionReceiptId
			,p.FirstName
			,p.MiddleName
			,p.LastName
			,PatientCode
			,itemcategory.SubCategoryId
			,itemcategory.SubCategoryName
		ORDER BY con.ConsumptionDate DESC
	END
END