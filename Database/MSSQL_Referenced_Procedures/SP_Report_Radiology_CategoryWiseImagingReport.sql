-- [SP_Report_Radiology_CategoryWiseImagingReport] '2022-02-01','2022-06-01'
CREATE PROCEDURE [dbo].[SP_Report_Radiology_CategoryWiseImagingReport] --'2022-01-01','2022-06-01'
  @FromDate Datetime= null,
  @ToDate Datetime= null
AS
/*
FileName: [SP_Report_Radiology_CategoryWiseImagingReport]
CreatedBy/date: Sagar/2017-05-30
Description: to get count of all service department in Radiology
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       nagesh/2017-05-30                     created the script
2       umed / 2017-06-06                      Modify the script i.e format and alias of table 
                                               and remove unnecessary Third Table from Script
3.     sud/2022-05-16                      Excluding returned items from the count.
*/
BEGIN
    IF(@FromDate IS NOT NULL OR @ToDate IS NOT NULL or LEN(@FromDate)>0 OR LEN(@ToDate)>0)
        BEGIN 
          DECLARE @DynamicPivotQuery AS NVARCHAR(MAX),
              @PivotColumnNames AS NVARCHAR(MAX),
              @PivotSelectColumnNames AS NVARCHAR(MAX)

          SELECT @PivotColumnNames= ISNULL(@PivotColumnNames + ',','')
          + QUOTENAME(ServiceDepartmentName)
          FROM ( 
               SELECT  DISTINCT  b.ServiceDepartmentName     
               FROM   BIL_MST_ServiceDepartment a 
               INNER JOIN BIL_TXN_BillingTransactionItems b 
               ON a.ServiceDepartmentName=b.ServiceDepartmentName
               WHERE DepartmentId=(SELECT TOP 1 DepartmentId FROM MST_Department WHERE DepartmentName='Radiology') 
               AND CONVERT(DATE,b.PaidDate) BETWEEN @FromDate and @ToDate
               GROUP BY CONVERT(DATE,b.PaidDate),b.ServiceDepartmentName
             )   AS dep

           SELECT 'Date' AS 'ColumnName'
             UNION ALL
          SELECT  DISTINCT  b.ServiceDepartmentName     
               FROM   BIL_MST_ServiceDepartment a 
               INNER JOIN BIL_TXN_BillingTransactionItems b 
               ON a.ServiceDepartmentName=b.ServiceDepartmentName
               WHERE DepartmentId=(SELECT TOP 1 DepartmentId FROM MST_Department WHERE DepartmentName='Radiology') 
               AND CONVERT(DATE,b.PaidDate) BETWEEN @FromDate and @ToDate
               GROUP BY CONVERT(DATE,b.PaidDate),b.ServiceDepartmentName;

          SET @DynamicPivotQuery = N'SELECT Date, ' + @PivotColumnNames + '
              FROM (
                 SELECT  DISTINCT  b.ServiceDepartmentName, 
                     CONVERT(VARCHAR,b.PaidDate,111)AS Date,
                     COUNT(b.BillingTransactionId) AS TotalCount        
                 FROM   BIL_MST_ServiceDepartment a 
                    INNER JOIN BIL_TXN_BillingTransactionItems b 
                    ON a.ServiceDepartmentName=b.ServiceDepartmentName
                 WHERE DepartmentId=(SELECT TOP 1 DepartmentId FROM MST_Department WHERE DepartmentName=''Radiology'')
                       AND ISNULL(ReturnStatus,0)=0
                     AND b.PaidDate BETWEEN CONVERT(Datetime,'''+ Convert(varchar(20),@FromDate)  + ''') AND  CONVERT(DATETIME,'''+Convert(varchar(20),@ToDate)+''')+1
                   
                  GROUP BY CONVERT(VARCHAR,b.PaidDate,111),b.ServiceDepartmentName) A
                  PIVOT(sum(TotalCount) for ServiceDepartmentName in (' + @PivotColumnNames + ')) as pvt';

          --SELECT @DynamicPivotQuery

          EXEC SP_executesql @DynamicPivotQuery
        END  
END