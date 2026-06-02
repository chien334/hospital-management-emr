CREATE PROCEDURE SP_Dashboard_PHRM_MostSoldMedicine
   @FromDate datetime=NULL,
   @ToDate datetime=NULL

AS
 /*
 SP_Dashboard_PHRM_MostSoldMedicine '2022-10-3','2022-10-31'
FileName: [SP_Dashboard_PHRM_MostSoldMedicine]
CreatedBy/date: Rohit/2022-12-30
Description: To get information of Top 10 Sold Medicine.
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Rohit/2022-12-30                 created the script
*/
BEGIN

SELECT TOP 10 itm.ItemName, SUM(invitm.SoldQuantity) 'SoldQuantity'
FROM PHRM_MST_Item itm
INNER JOIN (
		SELECT ItemId, SUM(Quantity) 'SoldQuantity'
		FROM PHRM_TXN_InvoiceItems
		WHERE CONVERT(DATE, CreatedOn) BETWEEN @FromDate AND @ToDate
		GROUP BY ItemId
	) invitm ON itm.ItemId = invitm.ItemId
GROUP BY itm.ItemName
ORDER BY SoldQuantity DESC
END