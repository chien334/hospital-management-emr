CREATE PROCEDURE [dbo].[SP_PHRM_GetSettlementSummaryReport] 
    @FromDate DATE,
    @ToDate DATE,
    @StoreId INT = NULL
AS
/*
 FileName: [SP_PHRM_GetSettlementSummaryReport] 
 Created: 6Dec'21/Rohit
 Description: To get all the settlement report data.
 Remarks: We need to use this procedure to get all the settlement report data.
 Change History
 S.No.    Date/User              Change          Remarks
 1.	     6Dec'21/Rohit		                   Created SP
*/
BEGIN
    SELECT
        sett.PatientId,
        pat.ShortName AS 'PatientName',
        pat.PatientCode,
        pat.Gender,
        pat.PhoneNumber AS 'ContactNo',
        pat.DateOfBirth,
        MAX(sett.CreatedOn) AS LatestSettlementDate,
        ROUND(SUM(ISNULL(CollectionFromReceivable, 0)),3) 'CollnFromReceivable',
        ROUND(SUM(ISNULL(DiscountAmount, 0)),3) 'CashDiscountGiven',
        ROUND(SUM(ISNULL(DiscountReturnAmount, 0)),3) 'CashDiscReturn'
    FROM
        PHRM_TXN_Settlement sett
        INNER JOIN PAT_Patient pat ON sett.PatientId = pat.PatientId
    WHERE 
		CONVERT(Date, sett.CreatedOn) BETWEEN @FromDate AND @ToDate
        AND (sett.StoreId = @StoreId OR @StoreId IS NULL)
	GROUP BY
		sett.PatientId,
        pat.ShortName,
        pat.PatientCode,
        pat.Gender,
        pat.PhoneNumber,
        pat.DateOfBirth
	ORDER BY MAX(sett.SettlementDate) DESC
END