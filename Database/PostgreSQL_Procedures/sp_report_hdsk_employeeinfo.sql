CREATE OR REPLACE FUNCTION sp_report_hdsk_employeeinfo(

)
RETURNS TABLE (
    "EmployeeName" VARCHAR,
    "Designation" TIMESTAMP,
    "DepartmentName" VARCHAR,
    "ContactNumber" TIMESTAMP,
    "Extension" TIMESTAMP,
    "SpeedDial" VARCHAR,
    "OfficeHour" VARCHAR,
    "RoomNumber" VARCHAR
) AS $$
BEGIN
    
    RETURN QUERY SELECT coalesce(emp.salutation,'')||' '|| emp.firstname|| coalesce(' '||emp.middlename,'')||' '||emp.lastname AS "EmployeeName"
           ,emrl.employeerolename AS "Designation" 
    	   , dep.departmentname
    	   ,emp.contactnumber, emp.extension, emp.speeddial, coalesce(emp.officehour,'0') AS "OfficeHour", emp.roomno AS "RoomNumber"
    
    from     emp_employee emp
             left join emp_employeerole emrl
    		 on emrl.employeeroleid = emp.employeeroleid 
    		 inner join mst_department dep 
    		 on dep.departmentid = emp.departmentid;
END;
$$ LANGUAGE plpgsql;