-- =============================================
-- Author:		<ANish Bhattarai>
-- Create date: <27 Apr 2020>
-- Description:	<Get the count of test category wise>
--Co-Author:          <Dev Narayan Chaudhary>
--Modified Date:      <13 Sep 2021>
--Description:        <Added status filter>
-- =============================================
CREATE PROCEDURE [dbo].[SP_LAB_CategoryWiseLabTestTotalCount] 
( @FromDate DATETIME = NULL,
      @ToDate DATETIME = NULL,
	  @OrderStatus varchar(200) = NULL)
AS
BEGIN
    Declare @OrderStatusList Table(OrderStatus varchar(20))
	Insert into @OrderStatusList
	Select value from string_split(@OrderStatus,',') where RTRIM(value) <>''

	select cat.TestCategoryId,cat.TestCategoryName, Count(req.RequisitionId) as TotalCount from LAB_TestRequisition req 
	join @OrderStatusList os on os.OrderStatus = req.OrderStatus
	join LAB_LabTests test on req.LabTestId = test.LabTestId
	join LAB_TestCategory cat on test.LabTestCategoryId = cat.TestCategoryId
	where req.BillingStatus <> 'cancel' and req.BillingStatus <> 'returned'
	and Convert(date,req.OrderDateTime) BETWEEN CONVERT(date, @FromDate) AND CONVERT(date, @ToDate)
	group by cat.TestCategoryId, cat.TestCategoryName order by [TotalCount] desc;
END