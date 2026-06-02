CREATE PROCEDURE [dbo].[SP_Report_BILL_CustomReport] 
 @FromDate date=null,
 @ToDate date=null,
 @ReportName varchar(200)=null
 AS
 /*
FileName: [SP_Report_BILL_CustomReport]
CreatedBy/date: Nagesh/2018-08-27
Description: sp for custom report like 100% on opd 
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1      Nagesh/2018-08-27	        created the script
2	   Ramavtar/12Nov'18			correcting parameter passed to fn-> FN_BIL_GetSrvDeptReportingName
*/
 BEGIN
  IF ((@FromDate IS NOT NULL) and (@ToDate IS NOT NULL)) 
		BEGIN
			SELECT count(*) as NoOfPatient from BIL_TXN_BillingTransactionItems bil 
			WHERE (ServiceDepartmentName='OPD' and DiscountPercent=100 AND  ISNULL(ReturnStatus,0) != 1)
			AND CONVERT(date, bil.CreatedOn) Between @FromDate AND @ToDate

			;with T as 
			(
				SELECT  CONVERT(DATE,bil.CreatedOn) AS [Date],
				ItemName,dbo.FN_BIL_GetSrvDeptReportingName(bil.ServiceDepartmentName,ItemName)as ServDepartmentName,Quantity,TotalAmount 
				from BIL_TXN_BillingTransactionItems  bil
				WHERE PatientId in 
				(   SELECT PatientId FROM BIL_TXN_BillingTransactionItems 
					WHERE (ServiceDepartmentName='OPD' and DiscountPercent=100 and ISNULL(ReturnStatus,0) != 1) 
					AND CONVERT(DATE, bil.CreatedOn) Between @FromDate AND @ToDate
				)   
			AND CONVERT(date, bil.CreatedOn) Between @FromDate AND @ToDate
			AND ISNULL(ReturnStatus,0) != 1      
			) 
			SELECT  CASE WHEN  [ItemName]='Vitamin D' OR ItemName='Health Card' THEN ItemName
               ELSE ServDepartmentName END  as Particulars
				,SUM(Quantity) AS TotalNumber, 
				SUM(TotalAmount) AS TotalIncome
				FROM T
				GROUP BY ( CASE WHEN  [ItemName]='Vitamin D' OR ItemName='Health Card' THEN ItemName
               ELSE ServDepartmentName END )
		END
END