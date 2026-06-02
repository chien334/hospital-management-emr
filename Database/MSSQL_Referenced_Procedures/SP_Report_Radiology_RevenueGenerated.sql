CREATE PROCEDURE [dbo].[SP_Report_Radiology_RevenueGenerated] 

@FromDate Date=null ,
@ToDate Date= null
AS

/*
FileName: [SP_Report_Radiology_RevenueGenerated]
CreatedBy/date: Sagar/2017-05-25
Description: to get the total of Price , Totalpaid amount, and total Tax between given dates
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Sagar/2017-05-25	                   created the script
2       umed / 2017-06-09                      Modify the script i.e format and alias of table 
                                             and also remove the hard coded DepartmentID with dynamically of Radiology department
*/
BEGIN
		If(@FromDate IS NOT NULL OR @ToDate IS NOT NULL or LEN(@FromDate)>0 OR LEN(@ToDate)>0)
			BEGIN
					SELECT  CONVERT(date,D.PaidDate) AS [Date],
					        SUM(D.Price) AS TotalPrice,
							SUM(D.TotalAmount) AS TotalPaidAmount,
							SUM(D.Tax) AS TotalTax
					FROM    BIL_MST_ServiceDepartment T
					INNER JOIN
					       BIL_TXN_BillingTransactionItems D ON 
					       D.ServiceDepartmentName=T.ServiceDepartmentName
					WHERE convert(date,D.PaidDate) BETWEEN @FromDate AND @ToDate AND DepartmentId=(SELECT TOP 1 DepartmentId FROM MST_Department WHERE DepartmentName='Radiology')
					GROUP BY CONVERT(date,D.PaidDate) 
			END
END