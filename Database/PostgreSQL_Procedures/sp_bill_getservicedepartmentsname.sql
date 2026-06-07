CREATE OR REPLACE FUNCTION sp_bill_getservicedepartmentsname(

)
RETURNS TABLE (
    "ServiceDepartmentName" VARCHAR
) AS $$
BEGIN
    
    	RETURN QUERY SELECT distinct
    		"fn_bil_getsrvdeptreportingname"(servicedepartmentname, itemname) AS "ServiceDepartmentName"
    	from "vw_bil_txnitemsinfowithdateseparation";
END;
$$ LANGUAGE plpgsql;