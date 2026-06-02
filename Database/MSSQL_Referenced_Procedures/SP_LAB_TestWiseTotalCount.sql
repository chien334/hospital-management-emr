-- =============================================
-- Author:		<ANish Bhattarai>
-- Create date: <27 Apr 2020>
-- Description:	<Get the count of test category wise>
--Co-Author:          <Dev Narayan Chaudhary>
--Modified Date:      <13 Sep 2021>
--Description:        <Added status filter>
-- =============================================
CREATE PROCEDURE [dbo].[SP_LAB_TestWiseTotalCount] 
( @FromDate DATETIME = NULL,
      @ToDate DATETIME = NULL,
	  @catId INT = NULL,
	  @OrderStatus varchar(200) = null)
AS
BEGIN
Declare @qry nvarchar(max);
Set @qry = 'Declare @OrderStatusList Table(OrderStatus varchar(20))
Insert into @OrderStatusList
Select value from ' + 'string_split(' + '''' + @OrderStatus + '''' + ',' + ''',''' + ')' + ' where RTRIM(value) <>' + '''' + '''' + '; '  +
'select cat.TestCategoryName,req.LabTestId,req.LabTestName, Count(req.RequisitionId) as TotalCount from LAB_TestRequisition req 
join @OrderStatusList os on os.OrderStatus = req.OrderStatus
join LAB_LabTests test on req.LabTestId = test.LabTestId
join LAB_TestCategory cat on test.LabTestCategoryId = cat.TestCategoryId where';

IF(@catId IS NOT NULL  and @catId > 0)
BEGIN
SET @qry = @qry + ' cat.TestCategoryId = ' + cast(@catId as varchar(10)) + ' and';
END

Set @qry = @qry + ' req.BillingStatus <> ' +  '''cancel''' + ' and req.BillingStatus <> ' +  '''returned''' 
+ ' and Convert(date,req.OrderDateTime) BETWEEN CONVERT(date,''' + cast(@FromDate AS VARCHAR(50)) + ''',103)  AND ' 
+ 'CONVERT(date,''' + cast(@ToDate AS VARCHAR(50)) + ''',103) group by req.LabTestId, req.LabTestName, cat.TestCategoryName order by req.LabTestId desc';

EXEC(@qry);

--select cat.TestCategoryName,req.LabTestId,req.LabTestName, Count(req.RequisitionId) as TotalCount from LAB_TestRequisition req 
--join LAB_LabTests test on req.LabTestId = test.LabTestId
--join LAB_TestCategory cat on test.LabTestCategoryId = cat.TestCategoryId
--where req.BillingStatus <> 'cancel' and req.BillingStatus <> 'returned' 
--and Convert(date,req.OrderDateTime) BETWEEN CONVERT(date, @FromDate) AND CONVERT(date, @ToDate)
--group by req.LabTestId, req.LabTestName, cat.TestCategoryName;

END