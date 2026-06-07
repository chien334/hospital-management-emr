CREATE OR REPLACE FUNCTION sp_report_bill_billdenomination(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_userid INT DEFAULT NULL
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
    begin
        if (p_fromdate is not null) or (p_todate is not null)
    
        then
            RETURN QUERY SELECT
    		u.employeeid AS "UserId",
    		u.firstname AS "FirstName",
    		u.middlename AS "MiddleName",
    		u.lastname AS "LastName",
    
    		hu.firstname AS "hFirstName",
    		hu.middlename AS "hMiddleName",
    		hu.lastname AS "hLastName",
    
    		h.handovertype AS "HandoverType",
    		h.handoveruserid AS "HandoverUserId",
    		h.handoveramount AS "HandoverAmount",
    		h.createdon AS "CreatedOn",
    		d.servicedepartmentname AS "DepartmentName"
    
    		from emp_employee u
    		join bil_mst_handover h on u.employeeid=h.userid
    		join emp_employee hu on hu.employeeid=h.handoveruserid
    		join bil_mst_servicedepartment d on u.departmentid = d.departmentid
    
            where u.employeeid=p_userid and (h.createdon)::date between p_fromdate and p_todate
    		order by h.createdon desc;
        end if;
    end;
END;
$$ LANGUAGE plpgsql;