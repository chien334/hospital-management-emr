CREATE PROCEDURE [dbo].[SP_Report_TotalRevenueFromLab]
	@FromDate DATE=NULL ,
	@ToDate DATE= NULL
AS
/*
FileName: [SP_Report_TotalRevenueFromLab] 
Description: to get the total revenue from lab 
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Rusha 2019-09-23					To get daily total revenue
*/
BEGIN
	    IF(@FromDate IS NOT NULL OR @ToDate IS NOT NULL OR LEN(@FromDate)>0 OR LEN(@ToDate)>0)
		BEGIN
			SELECT   CONVERT(DATE,PaidDate) AS [Date],SUM(TotalAmount) AS TotalRevenue,
					 SUM(DiscountAmount) AS TotalDiscount, SUM(isnull(TaxableAmount,0)) as TotalTax 
					 FROM BIL_TXN_BillingTransactionItems bt
					 join BIL_MST_ServiceDepartment sd on  sd.ServiceDepartmentId = bt.ServiceDepartmentId
					 WHERE sd.IntegrationName = 'LAB' and bt.ReturnStatus is null
					 AND CONVERT(DATE,PaidDate) BETWEEN @FromDate AND @ToDate 
			GROUP BY CONVERT(DATE,PaidDate) 
		END
END