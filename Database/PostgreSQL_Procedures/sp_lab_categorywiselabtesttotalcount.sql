CREATE OR REPLACE FUNCTION sp_lab_categorywiselabtesttotalcount(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_orderstatus VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "TestCategoryId" INT,
    "TestCategoryName" VARCHAR,
    "TotalCount" INT
) AS $$
BEGIN
    DROP TABLE IF EXISTS v_orderstatuslist;
    CREATE TEMP TABLE v_orderstatuslist (
        OrderStatus varchar(20)
    );
    
        
    	insert into v_orderstatuslist
    	select value from string_split(p_orderstatus,',') where rtrim(value) <>'';
    
    	RETURN QUERY SELECT cat.testcategoryid,cat.testcategoryname, count(req.requisitionid) AS "TotalCount" from lab_testrequisition req 
    	join v_orderstatuslist os on os.orderstatus = req.orderstatus
    	join lab_labtests test on req.labtestid = test.labtestid
    	join lab_testcategory cat on test.labtestcategoryid = cat.testcategoryid
    	where req.billingstatus <> 'cancel' and req.billingstatus <> 'returned'
    	and (req.orderdatetime)::date between (p_fromdate)::date and (p_todate)::date
    	group by cat.testcategoryid, cat.testcategoryname order by "totalcount" desc;
END;
$$ LANGUAGE plpgsql;