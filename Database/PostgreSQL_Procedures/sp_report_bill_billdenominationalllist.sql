CREATE OR REPLACE FUNCTION sp_report_bill_billdenominationalllist(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL
)
RETURNS TABLE (
    "UserId" INT,
    "FirstName" VARCHAR,
    "MiddleName" INT,
    "LastName" VARCHAR,
    "hFirstName" VARCHAR,
    "hMiddleName" INT,
    "hLastName" VARCHAR,
    "HandoverType" VARCHAR,
    "HandoverUserId" INT,
    "HandoverAmount" DECIMAL,
    "CreatedOn" TIMESTAMP,
    "DepartmentName" VARCHAR
) AS $$
BEGIN
    /*
    change history:
    s.no.  date/user             remarks
    1.    unknown/unknown       initial draft
    2.    15feb'20/Sud          Made basic revision in joins so that it appears in report. Need Complete Re-Write soon. 
    */
    
    BEGIN
        IF (p_fromdate IS NOT NULL) OR (p_todate IS NOT NULL)
    
        THEN
    
    	  RETURN QUERY SELECT
    		emp.EmployeeId AS "UserId",
    		emp.FirstName AS "FirstName",
    		emp.MiddleName AS "MiddleName",
    		emp.LastName AS "LastName",
    
    		emp2.FirstName AS "hFirstName",
    		emp2.MiddleName AS "hMiddleName",
    		emp2.LastName AS "hLastName",
    
    		h.HandoverType AS "HandoverType",
    		h.HandoverUserId AS "HandoverUserId",
    		h.HandoverAmount AS "HandoverAmount",
    		h.CreatedOn AS "CreatedOn",
    		'' AS "DepartmentName"
    		--d.ServiceDepartmentName 'departmentname'
    
    		from emp_employee emp
    		    join bil_mst_handover h on emp.employeeid = h.userid
    		    left join emp_employee emp2 on emp2.employeeid= h.handoveruserid
    		where (h.createdon)::date between p_fromdate and p_todate
    		order by h.createdon desc;
    
        end if;
    end;
END;
$$ LANGUAGE plpgsql;