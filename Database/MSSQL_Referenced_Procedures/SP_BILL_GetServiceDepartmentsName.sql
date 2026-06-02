CREATE PROCEDURE [dbo].[SP_BILL_GetServiceDepartmentsName]
/*
 File: SP_BILL_GetServiceDepartmentsName Created: Ramavtar/2018-09-09
 Description: to get service-departments name for reporting 
 (it gets all the service department names as require in reporting)
 Change History:
 S.No      ModifiedBy/Date                     Remarks
 1.       Ramavtar/11Sep'18                        Initial Draft
*/
AS
BEGIN
	SELECT DISTINCT
		[dbo].[FN_BIL_GetSrvDeptReportingName](ServiceDepartmentName, ItemName) 'ServiceDepartmentName'
	FROM [dbo].[VW_BIL_TxnItemsInfoWithDateSeparation]
END