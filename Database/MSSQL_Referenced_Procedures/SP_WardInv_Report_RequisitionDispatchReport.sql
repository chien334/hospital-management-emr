CREATE PROCEDURE [dbo].[SP_WardInv_Report_RequisitionDispatchReport] @FromDate DATETIME = NULL
	,@ToDate DATETIME = NULL
	,@StoreId INT = NULL
AS
/*
FileName: [SP_WardInv_Report_RequisitionDispatchReport]
CreatedBy/date: Rusha/06-04-2019
Description: To get stock details of requisition and dispatch from ward to inventory
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1.
2.		Rohit/10Oct'22							StoreId change to RequestFromStoreId and Join condition Fixed
3.		Rohit/31Oct'22							RequisitionDate and DispatchedDate fetched instead of CreatedOn
4.		Rohit/6Dec'22							SubCategoryName and SubCategory fetched to add frontend filter
*/
BEGIN
	SELECT convert(DATE, req.RequisitionDate) AS RequisitionDate
		,convert(DATE, disitm.DispatchedDate) AS DispatchDate
		,itm.ItemName
		,sc.SubCategoryName
		,sc.SubCategoryId
		,reqitm.Quantity AS RequestQty
		,reqitm.ReceivedQuantity
		,reqitm.PendingQuantity
		,disitm.DispatchedQuantity
		,reqitm.Remark
	FROM INV_TXN_RequisitionItems AS reqitm
	JOIN INV_TXN_Requisition AS req ON req.RequisitionId = reqitm.RequisitionId
	LEFT JOIN INV_TXN_DispatchItems AS disitm ON disitm.RequisitionItemId = reqitm.RequisitionItemId
	JOIN INV_MST_Item AS itm ON itm.ItemId = reqitm.ItemId
	INNER JOIN INV_MST_ItemSubCategory sc ON itm.SubCategoryId = sc.SubCategoryId
	WHERE req.RequestFromStoreId = @StoreId
		AND CONVERT(DATE, req.RequisitionDate) BETWEEN @FromDate
			AND @ToDate
END