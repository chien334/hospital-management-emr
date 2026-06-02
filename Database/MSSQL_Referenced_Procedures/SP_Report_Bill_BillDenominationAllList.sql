CREATE PROCEDURE [dbo].[SP_Report_Bill_BillDenominationAllList]	--- SP_Report_Bill_BillDenominationAllList '2020-02-14','2020-02-15'
	@FromDate DateTime=null,
	@ToDate DateTime=null
AS
/*
Change History:
S.No.  Date/User             Remarks
1.    Unknown/Unknown       Initial Draft
2.    15Feb'20/Sud          Made basic revision in joins so that it appears in report. Need Complete Re-Write soon. 
*/

BEGIN
    IF (@FromDate IS NOT NULL) OR (@ToDate IS NOT NULL)

    BEGIN

	  SELECT
		emp.EmployeeId 'UserId',
		emp.FirstName 'FirstName',
		emp.MiddleName 'MiddleName',
		emp.LastName 'LastName',

		emp2.FirstName 'hFirstName',
		emp2.MiddleName 'hMiddleName',
		emp2.LastName 'hLastName',

		h.HandoverType 'HandoverType',
		h.HandoverUserId 'HandoverUserId',
		h.HandoverAmount 'HandoverAmount',
		h.CreatedOn 'CreatedOn',
		'' as DepartmentName
		--d.ServiceDepartmentName 'DepartmentName'

		from EMP_Employee emp
		    join BIL_MST_Handover h on emp.EmployeeId = h.UserId
		    left join EMP_Employee emp2 on emp2.EmployeeId= h.HandoverUserId
		WHERE CONVERT(date,h.CreatedOn) between @FromDate AND @ToDate
		ORDER BY h.CreatedOn DESC

    END
END