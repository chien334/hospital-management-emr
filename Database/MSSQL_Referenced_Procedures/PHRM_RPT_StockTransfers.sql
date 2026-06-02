CREATE PROCEDURE [dbo].[PHRM_RPT_StockTransfers] @FromDate DATE = NULL
	,@ToDate DATE = NULL
	,@ItemId INT = NULL
	,@SourceStoreId INT = NULL
	,@TargetStoreId INT = NULL
	,@NotReceivedStocks BIT = NULL
AS
/*
FileName: PHRM_RPT_StockTransfers
CreatedBy/date: Sanjit/ 1st July, 2021
Description:
Remarks:  
Execute Query:
    EXECUTE dbo.PHRM_RPT_StockTransfers '2022-06-19','2022-07-21',NULL,NULL,NULL,0
Change History
S.No.    UpdatedBy/Date                        Remarks
1.      Sanjit/ 7th Sep, 2021           Changed the date format to all the dates in YYYY-MM-DD HH:MM
2.      Rusha/21thJuly22				Added Generic name in column
3.		Rohit/16Dec'22					Added Convert Date in CreatedOn for Predicate
4.      Rohit/13Feb'23						MRP-> SalePrice
*/
BEGIN
	-- body of the stored procedure
	SELECT G.GenericName
		,I.ItemName
		,D.BatchNo
		,D.CostPrice
		,D.SalePrice
		,
		-- to get date in the format of YYYY-MM-DD HH:MM
		CONVERT(CHAR(16), D.CreatedOn, 21) 'TransferredOn'
		,D.DispatchedQuantity 'TransferQuantity'
		,DE.FullName 'TransferredBy'
		,SS.Name 'TransferredFrom'
		,TS.Name 'TransferredTo'
		,RE.FullName 'ReceivedBy'
		,CONVERT(CHAR(16), D.ReceivedOn, 21) 'ReceivedOn'
		,AE.FullName 'ApprovedBy'
		,CONVERT(CHAR(16), R.ApprovedOn, 21) 'ApprovedOn'
		,ISNULL((D.CostPrice * D.DispatchedQuantity), 0) 'PurchaseValue'
		,ISNULL((D.SalePrice * D.DispatchedQuantity), 0) 'SalesValue'
	FROM PHRM_StoreDispatchItems AS D
	INNER JOIN PHRM_MST_Item AS I ON D.ItemId = I.ItemId
	JOIN PHRM_MST_Generic AS G ON I.GenericId = G.GenericId
	INNER JOIN PHRM_MST_Store AS SS ON D.SourceStoreId = SS.StoreId
	INNER JOIN PHRM_MST_Store AS TS ON D.TargetStoreId = TS.StoreId
	LEFT OUTER JOIN PHRM_StoreRequisition AS R ON D.RequisitionId = R.RequisitionId
	INNER JOIN EMP_Employee AS DE ON D.CreatedBy = DE.EmployeeId
	LEFT OUTER JOIN EMP_Employee AS AE ON R.ApprovedBy = AE.EmployeeId
	LEFT OUTER JOIN EMP_Employee AS RE ON D.ReceivedById = RE.EmployeeId
	WHERE CONVERT(DATE, D.CreatedOn) BETWEEN @FromDate
			AND @ToDate
		AND (
			D.ItemId = @ItemId
			OR @ItemId IS NULL
			)
		AND (
			D.SourceStoreId = @SourceStoreId
			OR @SourceStoreId IS NULL
			)
		AND (
			D.TargetStoreId = @TargetStoreId
			OR @TargetStoreId IS NULL
			)
		AND (
			D.ReceivedById IS NULL
			OR @NotReceivedStocks IS NULL
			OR @NotReceivedStocks = 0
			)
	ORDER BY D.DispatchItemsId DESC
END