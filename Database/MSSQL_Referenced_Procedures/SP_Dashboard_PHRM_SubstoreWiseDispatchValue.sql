CREATE PROCEDURE SP_Dashboard_PHRM_SubstoreWiseDispatchValue
   @FromDate datetime=NULL,
   @ToDate datetime=NULL

AS
 /*
 SP_Dashboard_PHRM_SubstoreWiseDispatchValue '2022-10-3','2022-10-31'
FileName: [SP_Dashboard_PHRM_SubstoreWiseDispatchValue]
CreatedBy/date: Rohit/2022-12-30
Description: To get information of dispatched value in substores.
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Rohit/2022-12-30                 created the script
*/
BEGIN

	SELECT TOP 10 mststr.Name
		,ISNULL(SUM(DispatchedQuantity * CostPrice), 0) TotalDispatchValue
	FROM PHRM_StoreDispatchItems d  
	INNER JOIN PHRM_MST_Store mststr ON d.TargetStoreId = mststr.StoreId
	WHERE CONVERT(DATE,DispatchedDate) BETWEEN @FromDate AND @ToDate AND  mststr.Category in ('substore','dispensary')
	GROUP BY TargetStoreId, mststr.Name
	Order By TotalDispatchValue DESC

END