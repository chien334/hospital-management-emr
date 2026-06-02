CREATE PROCEDURE [dbo].[SP_PHRM_GetMainStoreStockDetails] 
@ShowStockFromAllStores BIT = 1
AS
/*
SP Name: SP_PHRM_GetMainStoreStockDetails
Author: Sanjit Raj Shakya
CreatedOn: 22 Dec, 2021
Remarks: Created to replace Linq Query in Api GetMainStoreStock in PharmacyController
Execution: EXEC SP_PHRM_GetMainStoreStockDetails @ShowStockFromAllStores = 1
 Change History
 S.No.    Date/User              Change          Remarks-
 1.      Sanjit/22 Dec'21                       inital draft
 2.      Ramesh/27 Dec'21                       Changed Innerjoin to LeftJoin of StockBarCode with MST Stock 
 3.      Rohit/5jul'22                          Make group by in SubQuery
 4.      Nirmala/20Dec'22                       Add Rack No
 5.      Rohit/13Feb'23						MRP-> SalePrice
 6.      Rohit/Sud/04Apr'23                 Removed Hardcoding of MainStore and take from PHRM_MST_Store's column values 
                                             ( where Category='store' AND  SubCategory= 'pharmacy')
*/
BEGIN

Declare @Phrm_MainStoreId INT = (Select Top(1) StoreId from PHRM_MST_Store where Category='store' AND  SubCategory= 'pharmacy')
IF (@Phrm_MainStoreId IS NULL)
BEGIN
  RAISERROR('Pharmacy MainStore not configured in stores table.', 11, 1);
END

	SELECT SS.StockId
		,SS.ItemId
		,I.ItemName
		,I.ItemCode
		,Store.StoreId
		,Store.Name AS StoreName
		,U.UOMName
		,G.GenericId
		,G.GenericName
		,S.BatchNo
		,S.ExpiryDate
		,S.CostPrice
		,S.SalePrice
		,ISNULL(SS.AvailableQuantity, 0) AS AvailableQuantity
		,I.IsInsuranceApplicable
		,SB.BarcodeId AS BarcodeNumber
		,R.RackNo
	FROM (
		SELECT StoreId
			,StockId
			,ItemId
			,Sum(AvailableQuantity) AvailableQuantity
		FROM PHRM_TXN_StoreStock
		WHERE IsActive = 1
		GROUP BY StoreId
			,StockId
			,ItemId
		) SS
	INNER JOIN PHRM_MST_Stock S ON SS.StockId = S.StockId
	INNER JOIN PHRM_MST_Item I ON SS.ItemId = I.ItemId
		AND S.ItemId = I.ItemId
	LEFT JOIN PHRM_MAP_ItemToRack M ON I.ItemId = M.ItemId
		AND SS.StoreId = M.StoreId
	LEFT JOIN PHRM_MST_Rack R ON R.RackId = M.RackId
	INNER JOIN PHRM_MST_Generic G ON I.GenericId = G.GenericId
	INNER JOIN PHRM_MST_UnitOfMeasurement U ON I.UOMId = U.UOMId
	INNER JOIN PHRM_MST_Store Store ON SS.StoreId = Store.StoreId
	LEFT JOIN PHRM_MST_StockBarcode SB ON S.BarcodeId = SB.BarcodeId
	WHERE (
			@ShowStockFromAllStores = 1
			   OR store.StoreId =  @Phrm_MainStoreId
			)
	ORDER BY I.ItemName
END