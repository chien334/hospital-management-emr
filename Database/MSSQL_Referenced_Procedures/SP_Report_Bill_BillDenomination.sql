CREATE PROCEDURE [dbo].[SP_Report_Bill_BillDenomination]	--- [SP_Report_BIL_DoctorReport] '2018-08-08','2018-08-08'
	@FromDate DateTime=null,
	@ToDate DateTime=null,
	@UserId int=null
AS

BEGIN
    IF (@FromDate IS NOT NULL) OR (@ToDate IS NOT NULL)

    BEGIN
        SELECT
		u.EmployeeId 'UserId',
		u.FirstName 'FirstName',
		u.MiddleName 'MiddleName',
		u.LastName 'LastName',

		hu.FirstName 'hFirstName',
		hu.MiddleName 'hMiddleName',
		hu.LastName 'hLastName',

		h.HandoverType 'HandoverType',
		h.HandoverUserId 'HandoverUserId',
		h.HandoverAmount 'HandoverAmount',
		h.CreatedOn 'CreatedOn',
		d.ServiceDepartmentName 'DepartmentName'

		from EMP_Employee u
		join BIL_MST_Handover h on u.EmployeeId=h.UserId
		join EMP_Employee hu on hu.EmployeeId=h.HandoverUserId
		join BIL_MST_ServiceDepartment d on u.DepartmentId = d.DepartmentId

        WHERE u.EmployeeId=@UserId AND CONVERT(date,h.CreatedOn) between @FromDate AND @ToDate
		ORDER BY h.CreatedOn DESC
    END
END