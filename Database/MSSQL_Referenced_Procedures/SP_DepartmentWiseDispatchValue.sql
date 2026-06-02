CREATE PROCEDURE [dbo].[SP_DepartmentWiseDispatchValue] 
	 @SourceStoreId INT = NULL
	,@FromDate DATE = NULL
	,@ToDate DATE = NULL
AS
/*
FileName: [SP_DepartmentWiseDispatchValue]
CreatedBy/date: ROHIT/1Dec'22
Description: to get Department and DepartmentWiseDispatchedvalue
Remarks:  
To Execute : Exec SP_DepartmentWiseDispatchValue NULL,'2022-07-07','2022-12-01'
			 Exec SP_DepartmentWiseDispatchValue NULL,NULL,NULL
NOTE:  
Change History
S.No.    UpdatedBy/Date                        Remarks
1       ROHIT/2Dec'22				           created

*/
BEGIN
	SELECT Dis.TargetStoreId
		,phrm.Name
		,ROUND(SUM(DispatchedQuantity), 0) 'DispatchedQuantity'
		,ROUND(SUM(Dis.DispatchedQuantity * Dis.CostPrice), 3) AS TotalDispatchValue
	FROM PHRM_MST_Store phrm
	JOIN INV_TXN_DispatchItems Dis ON phrm.StoreId = Dis.TargetStoreId
	WHERE (
			Dis.SourceStoreId = @SourceStoreId
			OR @SourceStoreId IS NULL
			)
		AND CONVERT(DATE, Dis.DispatchedDate) BETWEEN @FromDate
			AND @ToDate
	GROUP BY phrm.Name
		,Dis.TargetStoreId
	ORDER BY TotalDispatchValue DESC
END