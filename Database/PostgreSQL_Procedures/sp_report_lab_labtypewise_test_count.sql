CREATE OR REPLACE FUNCTION sp_report_lab_labtypewise_test_count(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_testid INT DEFAULT NULL,
    p_categoryid INT DEFAULT NULL,
    p_orderstatus VARCHAR DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    v_dynamicpivotquery VARCHAR;
    v_columnname VARCHAR;
BEGIN
    /*
    filename: "sp_report_lab_labtypewise_test_count"
    createdby/date: anjana/2020-08-12
    description: to get list of outpatient 
    
     
    
    change history
    s.no.    updatedby/date                        remarks
    1.      anjana/2020-08-12          initial draft
    2.      dev narayan/2021-9-07        changed the filter from categoryname to categoryid and testname to testid
    3.      dev narayan/2021-09-12       changed the sp for dynamically accepting lab order status from client
    
    */
    
    
    
    
    
    
    
     
    
    select coalesce(v_columnname || ',','') || quotename(labtypename) into v_columnname from (select distinct labtypename from mst_labtypes) as labtypename;
    
     
    p_categoryid := coalesce(p_categoryid,0);
    p_testid := coalesce(p_testid,0);
    
    
    v_dynamicpivotquery := n'
    Declare v_orderstatuslist Table(OrderStatus varchar(20))
    Insert into v_orderstatuslist
    Select value from ' || 'string_split(' || '''' || p_orderstatus || '''' || ',' || ''',''' || ')' || ' where RTRIM(value) <>' || '''' || '''' || '; '  ||
    'SELECT * FROM (SELECT arrangedData.LabTestId,arrangedData.LabTestName,arrangedData.LabTestCategoryId,arrangedData.TestCategoryName,arrangedData.LabTypeName,
    COUNT(arrangedData.RequisitionId) as Total FROM
    (
    SELECT req.LabTestId,req.LabTestName, req.LabTestCategoryId, req.TestCategoryName,req.CreatedOn, labTypes.LabTypeName,
    CASE WHEN req.LabTypeName=labTypes.LabTypeName THEN req.RequisitionId ELSE null END AS RequisitionId
    FROM
    (
    SELECT r.RequisitionId,CONVERT(DATE,r.CreatedOn) as CreatedOn,t.LabTestId,t.LabTestCategoryId,t.LabTestName, r.LabTypeName, t.TestCategoryName
    FROM
    (
    SELECT tst.LabTestId,tst.LabTestName,tst.LabTestCategoryId,cat.TestCategoryName FROM LAB_LabTests tst
    JOIN LAB_TestCategory cat on tst.LabTestCategoryId=cat.TestCategoryId
    ) t
    LEFT JOIN (
    SELECT rq.* FROM LAB_TestRequisition rq
    inner join v_orderstatuslist os on rq.OrderStatus = os.OrderStatus  WHERE  rq.BillingStatus IN(' || '''paid''' || ',' || '''unpaid'''
    || ')
    )as r ON t.LabTestId=r.LabTestId
    ) req
    CROSS JOIN MST_LabTypes labTypes
    ) AS arrangedData
    where Convert(Date, arrangedData.CreatedOn) between ' ||
    || '''' ||(coalesce(p_fromdate,(current_timestamp)::date))::varchar || '''' || ' AND ' || '''' || (coalesce(p_todate,(current_timestamp)::date))::varchar || '''' ||
    || ' and (arrangedData.LabTestCategoryId= ' || (p_categoryid)::varchar || ' OR ' || (p_categoryid)::varchar || '=0)' || ' and (arrangedData.LabTestId=' || (p_testid)::varchar || ' OR '
    || (p_testid)::varchar || '=0)' || ' GROUP BY arrangedData.LabTestId,arrangedData.LabTestName,arrangedData.LabTestCategoryId,arrangedData.TestCategoryName,
    arrangedData.LabTypeName) allData
    PIVOT
    (
    SUM(Total) FOR "LabTypeName" IN (' || v_columnname || ')
    ) AS pivotedData';
    
    
    execute v_dynamicpivotquery;
END;
$$ LANGUAGE plpgsql;