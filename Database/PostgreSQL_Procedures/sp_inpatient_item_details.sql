CREATE OR REPLACE FUNCTION sp_inpatient_item_details(
    p_patientid INT,
    p_patientvisitid INT,
    p_modulename VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "billItems.*" VARCHAR,
    "RequestingUserName" VARCHAR,
    "RequestingUserDept" VARCHAR,
    "DepartmenCode" VARCHAR,
    "IntegrationName" TIMESTAMP,
    "AllowCancellation" TIMESTAMP
) AS $$
BEGIN
    begin
    
    if(p_modulename='' or lower(p_modulename)='null' or lower(p_modulename)='nursing' or lower(p_modulename)='emergency')
    then
    p_modulename := null;
    end if;
    
    
    RETURN QUERY SELECT billitems.* , emp.fullname AS "RequestingUserName",dept.departmentname AS "RequestingUserDept", 
    dept.departmentcode AS "DepartmenCode",lower(srv.integrationname) AS "IntegrationName", null AS "AllowCancellation" from 
    (select * from bil_txn_billingtransactionitems 
    where coalesce(returnstatus,0)=0 and patientid=p_patientid and patientvisitid=p_patientvisitid and lower(billstatus)='provisional') billitems
    join (select * from bil_mst_servicedepartment where lower(integrationname)=lower(p_modulename) or p_modulename is null) srv on billitems.servicedepartmentid = srv.servicedepartmentid
    join emp_employee emp on emp.employeeid = billitems.createdby
    left join mst_department dept on emp.departmentid = dept.departmentid
    order by billitems.createdon desc;
    end;
END;
$$ LANGUAGE plpgsql;