CREATE OR REPLACE FUNCTION sp_report_lab_categorywiselabreport(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_orderstatus VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "SN" VARCHAR,
    "Category" VARCHAR,
    "Count" INT
) AS $$
BEGIN
    DROP TABLE IF EXISTS v_orderstatuslist;
    CREATE TEMP TABLE v_orderstatuslist (
        OrderStatus varchar(20)
    );
    /*
    filename: "sp_report_lab_categorywiselabreport"  '2019-12-02','2019-12-02'
    createdby/date: dinesh 31st dec 2019
    description: to get the total count of test conducted 
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1       dinesh											hams requirement(for categorywise test count)
    2       dev narayan                               add the lab order status filter
    */
    begin
      if (p_fromdate is not null or p_todate is not null or len(p_fromdate) > 0 or len(p_todate) > 0)
      then
    	
    	insert into v_orderstatuslist
    	select value from string_split(p_orderstatus,',') where rtrim(value) <>'';
    RETURN QUERY SELECT (cast(row_number() over (order by  testcategoryname desc)  as int)) AS "SN",cat.testcategoryname AS "Category",count(lt.labtestcategoryid) AS "Count" from lab_testrequisition req
    join v_orderstatuslist os on req.orderstatus = os.orderstatus
    join lab_labtests lt on req.labtestid=lt.labtestid
    join lab_testcategory  cat on cat.testcategoryid= lt.labtestcategoryid
    
    
    where (req.createdon)::date between p_fromdate and p_todate
    group by cat.testcategoryname order by "count" desc;
      end if;
    end;
END;
$$ LANGUAGE plpgsql;