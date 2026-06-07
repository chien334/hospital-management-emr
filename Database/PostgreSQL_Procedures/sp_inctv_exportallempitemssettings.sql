CREATE OR REPLACE FUNCTION sp_inctv_exportallempitemssettings(

)
RETURNS TABLE (
    "EmployeeId" INT,
    "EmployeeName" VARCHAR,
    "TDSPercent" VARCHAR,
    "ServiceDepartmentId" INT,
    "ServiceDepartmentName" VARCHAR,
    "ItemId" INT,
    "ItemName" VARCHAR,
    "PerformerPercent" VARCHAR,
    "PrescriberPercent" VARCHAR,
    "HasGroupDistribution" TIMESTAMP,
    "DistributionInfo" TIMESTAMP
) AS $$
BEGIN
    /*
     filename: "sp_inctv_exportallempitemssettings" 
     created: 16th dec 2020/pratik
     description: to export all data from incentive setting (i.e. employeeitemssetup page)
     remarks: 
     change history
     s.no.    date/user               change          remarks
     1.		pratik:16th dec 2020					inital draft
     2.		krishna,2jun'22				alter		changed AssignedToPercent to PerformerPercent and ReferredByPercent to PrescriberPercent	
    */
    BEGIN	   
    RETURN QUERY SELECT 
    emp.EmployeeId,emp.FullName AS "EmployeeName" ,
    inctvInfo.TDSPercent,
    billItmPrice.ServiceDepartmentId,
    servDeprt.ServiceDepartmentName,
    billItmPrice.ItemId,
    billItmPrice.ItemName,
    empbillitmMap.PerformerPercent,
    empbillitmMap.PrescriberPercent,
    --empbillitmMap.HasGroupDistribution,
    CASE
        WHEN empbillitmMap.HasGroupDistribution =1 THEN 'yes'
        ELSE 'no'
    END AS "HasGroupDistribution",
    
    groupDist.DistributionInfo
    from INCTV_EmployeeIncentiveInfo inctvInfo
         join EMP_Employee emp  
            on inctvInfo.EmployeeId=emp.EmployeeId 
    
    left join INCTV_MAP_EmployeeBillItemsMap empbillitmMap
         on inctvInfo.EmployeeId=empbillitmMap.EmployeeId 
    
    join BIL_CFG_BillItemPrice billItmPrice
        on billItmPrice.BillItemPriceId=empbillitmMap.BillItemPriceId  
    	
    join BIL_MST_ServiceDepartment servDeprt
        on billItmPrice.ServiceDepartmentId=servDeprt.ServiceDepartmentId  and servDeprt.IsActive=1
    
    left join (
    		SELECT x.EmployeeBillItemsMapId, DistributionInfo = (SELECT string_agg(emp1.FullName||': ' ||(dist1.DistributionPercent)::VARCHAR||'%', ', ') from inctv_cfg_itemgroupdistribution dist1 inner join emp_employee emp1
    					  on dist1.distributetoemployeeid = emp1.employeeid and dist1.isactive=1
    				where employeebillitemsmapid = x.employeebillitemsmapid)
    
    			  from inctv_map_employeebillitemsmap as x
    			  where coalesce(x.hasgroupdistribution,0)=1
    			  group by x.employeebillitemsmapid
    
    	  )groupdist
    
       on empbillitmmap.employeebillitemsmapid = groupdist.employeebillitemsmapid 
       where empbillitmmap.isactive=1 and inctvinfo.isactive=1
    order by emp.firstname, emp.lastname , servicedepartmentname, itemname;
    
    end;
END;
$$ LANGUAGE plpgsql;