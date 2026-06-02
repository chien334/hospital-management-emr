CREATE PROCEDURE [dbo].[SP_Report_Lab_LabTypeWise_Test_Count]
    @FromDate Date=null ,
    @ToDate Date=null,
    @TestId int= null,
    @CategoryId int= null,
	@OrderStatus varchar(200) =null
AS
/*
FileName: [SP_Report_Lab_LabTypeWise_Test_Count]
CreatedBy/date: Anjana/2020-08-12
Description: to get list of outpatient 

 

Change History
S.No.    UpdatedBy/Date                        Remarks
1.      Anjana/2020-08-12          Initial Draft
2.      Dev Narayan/2021-9-07        Changed the filter from categoryName to categoryId and testname to testId
3.      Dev Narayan/2021-09-12       Changed the sp for dynamically accepting lab order status from client

*/
BEGIN



DECLARE @DynamicPivotQuery AS NVARCHAR(MAX)
DECLARE @ColumnName AS NVARCHAR(MAX)

 

SELECT @ColumnName= ISNULL(@ColumnName + ',','') + QUOTENAME(LabTypeName)
FROM (SELECT DISTINCT LabTypeName FROM MST_LabTypes) AS LabTypeName

 
SET @CategoryId = ISNULL(@CategoryId,0);
SET @TestId = ISNULL(@TestId,0);


SET @DynamicPivotQuery = N'
Declare @OrderStatusList Table(OrderStatus varchar(20))
Insert into @OrderStatusList
Select value from ' + 'string_split(' + '''' + @OrderStatus + '''' + ',' + ''',''' + ')' + ' where RTRIM(value) <>' + '''' + '''' + '; '  +
'SELECT * FROM (SELECT arrangedData.LabTestId,arrangedData.LabTestName,arrangedData.LabTestCategoryId,arrangedData.TestCategoryName,arrangedData.LabTypeName,
COUNT(arrangedData.RequisitionId) as Total FROM
(
SELECT req.LabTestId,req.LabTestName, req.LabTestCategoryId, req.TestCategoryName,req.CreatedOn, labTypes.LabTypeName,
CASE WHEN req.LabTypeName=labTypes.LabTypeName THEN req.RequisitionId ELSE null END AS RequisitionId
FROM
(
SELECT r.RequisitionId,CONVERT(DATE,r.CreatedOn) as CreatedOn,t.LabTestId,t.LabTestCategoryId,t.LabTestName, r.LabTypeName, t.TestCategoryName
FROM
(
SELECT tst.LabTestId,tst.LabTestName,tst.LabTestCategoryId,cat.TestCategoryName FROM LAB_LabTests tst
JOIN LAB_TestCategory cat on tst.LabTestCategoryId=cat.TestCategoryId
) t
LEFT JOIN (
SELECT rq.* FROM LAB_TestRequisition rq
inner join @OrderStatusList os on rq.OrderStatus = os.OrderStatus  WHERE  rq.BillingStatus IN(' + '''paid''' + ',' + '''unpaid'''
+ ')
)as r ON t.LabTestId=r.LabTestId
) req
CROSS JOIN MST_LabTypes labTypes
) AS arrangedData
where Convert(Date, arrangedData.CreatedOn) between ' +
+ '''' +Convert(Varchar(20), ISNULL(@FromDate,Convert(Date, GETDATE())) ) + '''' + ' AND ' + '''' + Convert(varchar(20), ISNULL(@ToDate,Convert(Date, GETDATE()))) + '''' +
+ ' and (arrangedData.LabTestCategoryId= ' + Convert(VARCHAR(200),@CategoryId) + ' OR ' + Convert(VARCHAR(200),@CategoryId) + '=0)' + ' and (arrangedData.LabTestId=' + Convert(VARCHAR(200),@TestId) + ' OR '
+ Convert(VARCHAR(200),@TestId) + '=0)' + ' GROUP BY arrangedData.LabTestId,arrangedData.LabTestName,arrangedData.LabTestCategoryId,arrangedData.TestCategoryName,
arrangedData.LabTypeName) allData
PIVOT
(
SUM(Total) FOR [LabTypeName] IN (' + @ColumnName + ')
) AS pivotedData';


EXEC sp_executesql @DynamicPivotQuery
END