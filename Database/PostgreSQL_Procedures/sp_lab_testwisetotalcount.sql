CREATE OR REPLACE FUNCTION sp_lab_testwisetotalcount(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_catid INT DEFAULT NULL,
    p_orderstatus VARCHAR DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    v_qry VARCHAR;
BEGIN
    begin
    
    v_qry := 'Declare v_orderstatuslist Table(OrderStatus varchar(20))
    Insert into v_orderstatuslist
    Select value from ' || 'string_split(' || '''' || p_orderstatus || '''' || ',' || ''',''' || ')' || ' where RTRIM(value) <>' || '''' || '''' || '; '  ||
    'select cat.TestCategoryName,req.LabTestId,req.LabTestName, Count(req.RequisitionId) as TotalCount from LAB_TestRequisition req 
    join v_orderstatuslist os on os.OrderStatus = req.OrderStatus
    join LAB_LabTests test on req.LabTestId = test.LabTestId
    join LAB_TestCategory cat on test.LabTestCategoryId = cat.TestCategoryId where';
    
    if(p_catid is not null  and p_catid > 0)
    then
    v_qry := v_qry || ' cat.TestCategoryId = ' || cast(p_catid as varchar(10)) || ' and';
    end if;
    
    v_qry := v_qry || ' req.BillingStatus <> ' ||  '''cancel''' || ' and req.BillingStatus <> ' ||  '''returned''' 
    || ' and Convert(date,req.OrderDateTime) BETWEEN CONVERT(date,''' || cast(p_fromdate as varchar(50)) || ''',103)  AND ' 
    || 'CONVERT(date,''' || cast(p_todate as varchar(50)) || ''',103) group by req.LabTestId, req.LabTestName, cat.TestCategoryName order by req.LabTestId desc';
    
    open ref1 for execute v_qry;
        return next ref1;
    
    --select cat.testcategoryname,req.labtestid,req.labtestname, count(req.requisitionid) as totalcount from lab_testrequisition req 
    --join lab_labtests test on req.labtestid = test.labtestid
    --join lab_testcategory cat on test.labtestcategoryid = cat.testcategoryid
    --where req.billingstatus <> 'cancel' and req.billingstatus <> 'returned' 
    --and convert(date,req.orderdatetime) between convert(date, p_fromdate) and convert(date, p_todate)
    --group by req.labtestid, req.labtestname, cat.testcategoryname;
    
    end;
END;
$$ LANGUAGE plpgsql;