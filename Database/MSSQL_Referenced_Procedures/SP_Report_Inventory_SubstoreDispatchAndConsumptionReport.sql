CREATE PROCEDURE [dbo].[SP_Report_Inventory_SubstoreDispatchAndConsumptionReport] @StoreId INT = NULL
	,@FromDate DATE = NULL
	,@ToDate DATE = NULL
	,@SubCategoryId INT = NULL
	,@ItemId INT = NULL
AS
/*
FileName: [SP_Report_Inventory_SubstoreDispatchAndConsumptionReport] null, '2022-05-18','2022-05-19'
Created: 18May'22/Rohit
Description: To Get Substore Dispatched And Consumption Report Data With StoreId,FromDate,ToDate.
Change History
S.No.    Date/User              Change          Remarks
1.	     18May'22/Rohit		                  inital draft
2.		 12Oct'22/Rohit						  get CostPrice and TotalAmountValue
3.	     31Oct'22/Rohit						  Calculation changes for TotalAmountValue
4.       22Feb'23/Nirmala                     Add Filter Based On SubCategory and ItemName
*/
BEGIN
	SELECT X.ItemCategoryName
		,X.SubCategoryName
		,X.StoreId
		,X.SubstoreName
		,X.ItemId
		,X.ItemName
		,X.UOMName 'Unit'
		,X.CostPrice
		,SUM(ISNULL(X.DisatchedQty, 0)) AS DispatchedQty
		,SUM(ISNULL(CONVERT(MONEY, X.DisatchedQty) * X.CostPrice, 0)) AS DispatchedValue
		,SUM(ISNULL(X.ConsumedQty, 0)) AS ConsumedQty
		,SUM(ISNULL(CONVERT(MONEY, X.ConsumedQty) * X.CostPrice, 0)) AS ConsumedValue
		,X.Remarks
		,(SUM(ISNULL(CONVERT(MONEY, X.ConsumedQty) * X.CostPrice, 0)) + SUM(ISNULL(CONVERT(MONEY, X.DisatchedQty) * X.CostPrice, 0))) 'TotalAmountValue'
	FROM (
		SELECT IC.ItemCategoryName
			,ISC.SubCategoryName
			,Store.Name AS SubstoreName
			,I.ItemId
			,I.ItemName
			,UOM.UOMName
			,ST.CostPrice
			,Store.StoreId
			,CASE 
				WHEN ST.TransactionType = 'dispatched-item-to'
					THEN SUM(ISNULL(ST.INQty, 0))
				ELSE 0
				END AS DisatchedQty
			,CASE 
				WHEN ST.TransactionType = 'consumption-items'
					THEN SUM(ISNULL(ST.OutQty, 0))
				ELSE 0
				END AS ConsumedQty
			,ST.Remarks
		FROM INV_TXN_StockTransaction ST
		INNER JOIN INV_MST_Item I ON ST.ItemId = I.ItemId
		INNER JOIN INV_MST_ItemCategory IC ON I.ItemCategoryId = IC.ItemCategoryId
		INNER JOIN INV_MST_ItemSubCategory ISC ON I.SubCategoryId = ISC.SubCategoryId
		INNER JOIN INV_MST_UnitOfMeasurement UOM ON I.UnitOfMeasurementId = UOM.UOMId
		INNER JOIN PHRM_MST_Store Store ON ST.StoreId = Store.StoreId
		LEFT JOIN INV_TXN_DispatchItems DI ON ST.ReferenceNo = DI.DispatchItemsId
			AND ST.TransactionType = 'dispatched-item-to'
		LEFT JOIN WARD_INV_Consumption C ON ST.ReferenceNo = C.ConsumptionId
			AND ST.TransactionType = 'consumption-items'
		WHERE ST.TransactionType IN (
				'dispatched-item-to'
				,'consumption-items'
				)
			AND CONVERT(DATE, ST.TransactionDate) BETWEEN @FromDate
				AND @ToDate
			AND (
				ST.StoreId = @StoreId
				OR @StoreId IS NULL
				)
			AND (
				ISC.SubCategoryId = @SubCategoryId
				OR @SubCategoryId IS NULL
				)
			AND (
				I.ItemId = @ItemId
				OR @ItemId IS NULL
				)
		GROUP BY IC.ItemCategoryName
			,ISC.SubCategoryName
			,I.ItemName
			,I.ItemId
			,UOM.UOMName
			,ST.TransactionDate
			,ST.TransactionType
			,ST.CostPrice
			,Store.StoreId
			,Store.Name
			,ST.Remarks
		) X
	GROUP BY X.ItemCategoryName
		,X.SubCategoryName
		,X.StoreId
		,X.SubstoreName
		,X.ItemId
		,X.ItemName
		,X.UOMName
		,X.CostPrice
		,X.Remarks
	ORDER BY X.SubstoreName
		,X.ItemName ASC
END