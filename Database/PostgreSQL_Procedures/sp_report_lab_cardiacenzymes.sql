/*
FileName: [SP_Report_Lab_CardiacEnzymes]
CreatedBy/date: Ramavtar/2017-10-11
Description: to get number of times the given labtest performed
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Ramavtar/2017-10-11					created the script
2		Ramavtar/2017-11-24					alter the script
3		Hari/2017-12-07						alter the script
*/
CREATE OR REPLACE FUNCTION sp_report_lab_cardiacenzymes(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL
)
RETURNS TABLE (
    "seq" INT,
    "ViewName" VARCHAR,
    "Quantity" INT
) AS $$
BEGIN
    DROP TABLE IF EXISTS v_temptable0;
    CREATE TEMP TABLE v_temptable0 (
        TestName varchar(100),ViewName varchar(100),counts int,seq int
    );
    
    --changed: sud:4jan'18: default fromdate and todate are today's date.
      p_fromdate := (coalesce(p_fromdate,current_timestamp))::date;
      p_todate := (coalesce(p_todate,current_timestamp))::date;
    
    /*
    creating temporary table and inserting values which we need on screen
    columns: testname, viewname, counts, seq	-- add counts column only when needed (when we required count for another table then add counts column else dont)
    taking count for test whose billing status are 'paid' and 'unpaid' (ignoring return and cancel)
    for some row, we are getting count from lab_txn_testcomponentresult so we write expression there itself in insert into statement
    */
    
    
    insert into  v_temptable0(testname,viewname,seq) values 
    		('CK-MB','CPK-MB',1),
    		('CK-NAC','CPK-NAC',2),
    		('LDH','LDH',3),
    		('Troponin I','Trop-I',4);
    
    insert into  v_temptable0(viewname,counts,seq) values 
    		('Positive',(select count(componentname) from lab_txn_testcomponentresult where componentname='Troponin I' and value ='Positive' and ((createdon)::date between p_fromdate and p_todate)),5),
    		('Negative',(select count(componentname) from lab_txn_testcomponentresult where componentname='Troponin I' and value ='Negative' and ((createdon)::date between p_fromdate and p_todate)),6);
    
    RETURN QUERY SELECT seq,viewname,coalesce(tbl.counts,count(labtestname)) AS "Quantity" from v_temptable0 tbl
    left join 
    lab_testrequisition testreq on tbl.testname = testreq.labtestname and 
    	(testreq.billingstatus = 'unpaid' or testreq.billingstatus = 'paid') and
    	--changed: sud:4jan'18:dateconversion
    	((testreq.orderdatetime)::date between p_fromdate and p_todate)
    group by seq,viewname,counts
    order by seq;
END;
$$ LANGUAGE plpgsql;