/*
FileName: [SP_Report_Inventory_FixedAssetsMovement] '2020-01-20','2021-01-20',null,null,null
CreatedBy/date: Aniket/29-09-2021
Description: To get the Details of report Quotion rates
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1.    Aniket/29-09-2021                    created the script
2.	  Rohit/20Jan'22					   Added IsFixedAssets filter and also Item Specification
*/
CREATE PROCEDURE [dbo].[SP_Report_Inventory_FixedAssetsMovement]
    @FromDate datetime = NULL,
    @ToDate datetime =NULL,
    @EmployeeId int NULL= NULL,
    @DepartmentId int NULL = NULL,
    @ItemId int NULL = NULL,
    @ReferenceNumber nvarchar NULL = NULL
AS
BEGIN
    IF ((@FromDate IS NOT NULL) AND (@ToDate IS NOT NULL))
BEGIN
        SELECT FS.BarCodeNumber,
            ALH.StartDate AS MovementDate,
            I.ItemName,
            UOT.UOMName AS UOMName,
            COUNT(*) AS Quantity,
            (FS.ItemRate * COUNT(*)) AS Amount,
            S.Name AS StoreName,
            ISNULL(E.FullName,'N/A') AS AssetHolder,
            GRI.GRItemSpecification AS Specification
        FROM INV_AssetLocationHistory ALH
            JOIN INV_TXN_FixedAssetStock FS ON ALH.FixedAssetStockId = FS.FixedAssetStockId
            JOIN INV_TXN_GoodsReceiptItems GRI ON FS.GoodsReceiptItemId = GRI.GoodsReceiptItemId
            JOIN INV_MST_Item I ON FS.ItemId = I.ItemId
            LEFT JOIN EMP_Employee E ON ALH.OldAssetHolderId = E.EmployeeId
            JOIN PHRM_MST_Store S ON ALH.OldStoreId = S.StoreId
            JOIN INV_MST_UnitOfMeasurement AS  UOT ON I.UnitOfMeasurementId = UOT.UOMId
        WHERE ((CONVERT(date,ALH.StartDate) BETWEEN ISNULL(@FromDate,GETDATE()) AND ISNULL(@ToDate,GETDATE())) AND I.IsFixedAssets  = 1
            OR (CONVERT(date,ALH.EndDate) BETWEEN ISNULL(@FromDate,GETDATE()) AND ISNULL(@ToDate,GETDATE())))
            AND ((FS.AssetHolderId = @EmployeeId OR @EmployeeId IS NULL) AND (FS.SubStoreId = @DepartmentId OR @DepartmentId IS NULL) AND (FS.ItemId = @ItemId OR @ItemId IS NULL) AND (FS.BarCodeNumber = @ReferenceNumber OR @ReferenceNumber IS NULL))
        GROUP BY FS.ItemId, ALH.FixedAssetStockId, ALH.OldAssetHolderId, ALH.OldStoreId, ALH.StartDate, FS.ItemRate, I.ItemName, S.Name, UOT.UOMName, I.Code, E.FullName,FS.BarCodeNumber, GRI.GRItemSpecification
    END
END