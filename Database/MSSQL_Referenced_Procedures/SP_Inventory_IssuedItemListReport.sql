CREATE PROCEDURE [dbo].[SP_Inventory_IssuedItemListReport] @FromDate DATE
	,@ToDate DATE
	,@FiscalYearId INT = NULL
	,@ItemId INT = NULL
	,@SubStoreId INT = NULL
	,@MainStoreId INT = NULL
	,@EmployeeId INT = NULL
	,@SubCategoryId INT = NULL
AS
/*
FileName: [SP_Inventory_IssuedItemListReport]  '2022-04-1','2022-04-7',5,NULL,NULL,7,NULL
CreatedBy/date: Rohit/7thApr'22
Description: To get the Dispatch Item Detail Report from MainStore to Substore
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1.		Rohit/7thApr'22					created Iniitial Script
2.		Rohit/19Aug'22					Fetched SubCategoryName
3.		Rohit/8Sept'23					Fetched DispatchNo as ReferenceNo (Previously DispatchItemId is fetched as ReferenceNo)
*/
BEGIN
	SELECT di.DispatchNo 'DispatchNo'
		,s.Name 'SubStoreName'
		,itmsubcat.SubCategoryName
		,itm.ItemName
		,uom.UOMName 'Unit'
		,di.DispatchedQuantity 'Quantity'
		,CONVERT(DATE, di.DispatchedDate) 'IssuedDate'
		,emp.FullName 'EmployeeName'
	FROM INV_TXN_DispatchItems di
	JOIN INV_MST_Item itm ON di.ItemId = itm.ItemId
	JOIN INV_MST_ItemSubCategory itmsubcat ON itm.SubCategoryId = itmsubcat.SubCategoryId
	JOIN INV_MST_UnitOfMeasurement uom ON itm.UnitOfMeasurementId = uom.UOMId
	JOIN PHRM_MST_Store s ON di.TargetStoreId = s.StoreId
	JOIN EMP_Employee emp ON di.CreatedBy = emp.EmployeeId
	WHERE (
			di.ItemId = @ItemId
			OR @ItemId IS NULL
			)
		AND (
			di.CreatedBy = @EmployeeId
			OR @EmployeeId IS NULL
			)
		AND (
			di.TargetStoreId = @SubStoreId
			OR @SubStoreId IS NULL
			)
		AND (
			itmsubcat.SubCategoryId = @SubCategoryId
			OR @SubCategoryId IS NULL
			)
		AND CONVERT(DATE, di.DispatchedDate) BETWEEN CONVERT(DATE, @FromDate)
			AND CONVERT(DATE, @ToDate)
		AND di.FiscalYearId = @FiscalYearId
		AND di.SourceStoreId = @MainStoreId
	ORDER BY di.DispatchItemsId DESC
END