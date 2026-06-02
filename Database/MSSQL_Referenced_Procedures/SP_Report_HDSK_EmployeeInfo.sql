CREATE PROCEDURE [dbo].[SP_Report_HDSK_EmployeeInfo] 
		/*
FileName: [SP_Report_HDSK_EmployeeInfo]
CreatedBy/date: Sagar/2017-06-21
Description: To Get Employee Information in Helpdesk Module.
Remarks:   Getting Information about Employee from 3 tables.
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Sagar/2017-06-21	               Created the script 
2       Umed/2017-08-14                 Modified script as per sudarsan sir Suggestion 
                                       (Left-Join Employee with Role table) ISNULL with Employee name, added Designation , Extention, SpeedDial, Office Hour
*/
AS
BEGIN
select ISNULL(emp.Salutation,'')+' '+ emp.FirstName+ ISNULL(' '+emp.MiddleName,'')+' '+emp.LastName AS EmployeeName
       ,emrl.EmployeeRoleName AS Designation 
	   , dep.DepartmentName
	   ,emp.ContactNumber, emp.Extension, emp.SpeedDial, ISNULL(emp.OfficeHour,'0') AS OfficeHour, emp.RoomNo 'RoomNumber'

FROM     EMP_Employee emp
         LEFT JOIN EMP_EmployeeRole emrl
		 ON emrl.EmployeeRoleId = emp.EmployeeRoleId 
		 INNER JOIN MST_Department dep 
		 ON dep.DepartmentId = emp.DepartmentId

END