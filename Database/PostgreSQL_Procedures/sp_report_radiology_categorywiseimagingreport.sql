CREATE OR REPLACE FUNCTION sp_report_radiology_categorywiseimagingreport(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    v_dynamicpivotquery VARCHAR;
    v_pivotcolumnnames VARCHAR;
    v_pivotselectcolumnnames VARCHAR;
BEGIN
    /*
    filename: "sp_report_radiology_categorywiseimagingreport"
    createdby/date: sagar/2017-05-30
    description: to get count of all service department in radiology
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1       nagesh/2017-05-30                     created the script
    2       umed / 2017-06-06                      modify the script i.e format and alias of table 
                                                   and remove unnecessary third table from script
    3.     sud/2022-05-16                      excluding returned items from the count.
    */
    begin
        if(p_fromdate is not null or p_todate is not null or len(p_fromdate)>0 or len(p_todate)>0)
            then 
              
    
              select coalesce(v_pivotcolumnnames || ',','')
              || quotename(servicedepartmentname) into v_pivotcolumnnames from ( 
                   select  distinct  b.servicedepartmentname     
                   from   bil_mst_servicedepartment a 
                   inner join bil_txn_billingtransactionitems b 
                   on a.servicedepartmentname=b.servicedepartmentname
                   where departmentid=(select  departmentid from mst_department where departmentname='Radiology' limit 1) 
                   and (b.paiddate)::date between p_fromdate and p_todate
                   group by (b.paiddate)::date,b.servicedepartmentname
                 )   as dep;
    
               open ref1 for select 'Date' as "columnname"
                 union all
              select  distinct  b.servicedepartmentname     
                   from   bil_mst_servicedepartment a 
                   inner join bil_txn_billingtransactionitems b 
                   on a.servicedepartmentname=b.servicedepartmentname
                   where departmentid=(select  departmentid from mst_department where departmentname='Radiology' limit 1) 
                   and (b.paiddate)::date between p_fromdate and p_todate
                   group by (b.paiddate)::date,b.servicedepartmentname;
        return next ref1;
    
              v_dynamicpivotquery := n'SELECT Date, ' || v_pivotcolumnnames || '
                  FROM (
                     SELECT  DISTINCT  b.ServiceDepartmentName, 
                         CONVERT(VARCHAR,b.PaidDate,111)AS Date,
                         COUNT(b.BillingTransactionId) AS TotalCount        
                     FROM   BIL_MST_ServiceDepartment a 
                        INNER JOIN BIL_TXN_BillingTransactionItems b 
                        ON a.ServiceDepartmentName=b.ServiceDepartmentName
                     WHERE DepartmentId=(SELECT TOP 1 DepartmentId FROM MST_Department WHERE DepartmentName=''Radiology'')
                           AND COALESCE(ReturnStatus,0)=0
                         AND b.PaidDate BETWEEN CONVERT(TIMESTAMP,'''|| (p_fromdate)::varchar  || ''') AND  CONVERT(TIMESTAMP,'''||(p_todate)::varchar||''')+1
                       
                      GROUP BY CONVERT(VARCHAR,b.PaidDate,111),b.ServiceDepartmentName) A
                      PIVOT(sum(TotalCount) for ServiceDepartmentName in (' || v_pivotcolumnnames || ')) as pvt';
    
              --select v_dynamicpivotquery
    
              open ref1 for execute v_dynamicpivotquery;
        return next ref1;
            end if;  
    end;
END;
$$ LANGUAGE plpgsql;