CREATE PROCEDURE [dbo].[SP_Report_Lab_CategoryWiseLabReport] 
@FromDate datetime = NULL,
@ToDate datetime = NULL,
@OrderStatus varchar (200) = null
AS


/*
FileName: [SP_Report_Lab_CategoryWiseLabReport]  '2019-12-02','2019-12-02'
CreatedBy/date: Dinesh 31st Dec 2019
Description: to get the total count of test conducted 
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Dinesh											Hams Requirement(For Categorywise Test Count)
2       Dev Narayan                               Add the lab order status filter
*/
BEGIN
  IF (@FromDate IS NOT NULL OR @ToDate IS NOT NULL OR LEN(@FromDate) > 0 OR LEN(@ToDate) > 0)
  BEGIN
	Declare @OrderStatusList Table(OrderStatus varchar(20))
	Insert into @OrderStatusList
	Select value from string_split(@OrderStatus,',') where RTRIM(value) <>''
select (Cast(ROW_NUMBER() OVER (ORDER BY  TestCategoryName desc)  AS int)) AS SN,cat.TestCategoryName as Category,count(lt.LabTestCategoryId) 'Count' from LAB_TestRequisition req
join @OrderStatusList os on req.OrderStatus = os.OrderStatus
join LAB_LabTests lt on req.LabTestId=lt.LabTestId
join LAB_TestCategory  cat on cat.TestCategoryId= lt.LabTestCategoryId


where convert(date,req.CreatedOn) between @FromDate and @ToDate
group by cat.TestCategoryName order by [Count] desc
  END
END