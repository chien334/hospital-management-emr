CREATE PROCEDURE [dbo].[SP_PHRM_BreakageItemReport] @FromDate DATETIME = NULL
	,@ToDate DATETIME = NULL
AS
/*
FileName: [[SP_PHRM_BreakageItemReport]]
CreatedBy/date:Vikas/2018-08-10
Description: .
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1      Vikas/2018-08-10	              created the script
2	   Rusha/2019-03-31				  add writeoff quantity 
3      Rohit/13Feb'23						MRP-> SalePrice
*/
BEGIN
	IF (
			(@FromDate IS NOT NULL)
			AND (@ToDate IS NOT NULL)
			)
	BEGIN
		SELECT convert(DATE, wi.CreatedOn) AS [Date]
			,usr.UserName
			,i.ItemName
			,ItemPrice AS SalePrice
			,WriteOffQuantity AS BreakageQty
			,Round(sum(wi.TotalAmount), 2, 0) AS [TotalAmount]
		FROM PHRM_WriteOffItems wi
		JOIN RBAC_User usr ON wi.CreatedBy = usr.EmployeeId
		JOIN PHRM_MST_Item i ON i.ItemId = wi.ItemId
		WHERE CONVERT(DATE, wi.CreatedOn) BETWEEN @FromDate
				AND @ToDate
		GROUP BY convert(DATE, wi.CreatedOn)
			,usr.UserName
			,i.ItemName
			,ItemPrice
			,WriteOffQuantity
	END
END