-- =============================================
-- Author:		<Anish Bhattarai>
-- Create date: <3 August 2020>
-- Description:	<Get all the Items requested for the given Inpatient>
-- =============================================
CREATE PROCEDURE [dbo].[SP_InPatient_Item_Details] 
( 
@patientId int, 
@patientVisitId int,
@moduleName varchar(50)=null
)
AS
BEGIN

IF(@moduleName='' OR LOWER(@moduleName)='null' OR LOWER(@moduleName)='nursing' OR LOWER(@moduleName)='emergency')
BEGIN
SET @moduleName = null
END


select billItems.* , emp.FullName as 'RequestingUserName',dept.DepartmentName as 'RequestingUserDept', 
dept.DepartmentCode as 'DepartmenCode',LOWER(srv.IntegrationName) as 'IntegrationName', null as 'AllowCancellation' from 
(Select * from BIL_TXN_BillingTransactionItems 
Where ISNULL(ReturnStatus,0)=0 and PatientId=@patientId and PatientVisitId=@patientVisitId and LOWER(BillStatus)='provisional') billItems
Join (select * from BIL_MST_ServiceDepartment where LOWER(IntegrationName)=LOWER(@moduleName) OR @moduleName Is Null) srv on billItems.ServiceDepartmentId = srv.ServiceDepartmentId
Join EMP_Employee emp on emp.EmployeeId = billItems.CreatedBy
Left Join MST_Department dept on emp.DepartmentId = dept.DepartmentId
Order by billItems.CreatedOn desc
END