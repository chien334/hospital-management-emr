/*
FileName: [SP_Report_Lab_Virology]
CreatedBy/date: Ramavtar/2017-10-11
Description: to get number of times the given labtest performed
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Ramavtar/2017-10-11					created the script
2		Ramavtar/2017-11-24					alter the script
3		Hari/2017-12-07						alter the script
*/
CREATE OR REPLACE FUNCTION sp_report_lab_virology(
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
    		('HIV','HIV',1),
    		('HAV (HEPATITIS A) Total Ab','HAV',4),
    		('HBsAg','HBsAg',5),
    		('HCV','HCV',8),
    		('HEV(Hepatistis E) Total Ab','HEV',11),
    		(null,'Western blot',12),
    		(null,'CD4 Count',13),
    		(null,'Viral load',14);
    insert into  v_temptable0(viewname,counts,seq) values 
    		('Reactive',(select count(componentname) from lab_txn_testcomponentresult where componentname='HIV (I & II)' and value ='Reactive' and ((createdon)::date between p_fromdate and p_todate)),2),
    		('Non-Reactive',(select count(componentname) from lab_txn_testcomponentresult where componentname='HIV (I & II)' and value ='Non-Reactive' and ((createdon)::date between p_fromdate and p_todate)),3),
    		('Reactive',(select count(componentname) from lab_txn_testcomponentresult where componentname='HBsAg' and value ='Reactive' and ((createdon)::date between p_fromdate and p_todate)),6),
    		('Non-Reactive',(select count(componentname) from lab_txn_testcomponentresult where componentname='HBsAg' and value ='Non-Reactive' and ((createdon)::date between p_fromdate and p_todate)),7),
    		('Reactive',(select count(componentname) from lab_txn_testcomponentresult where componentname='HCV' and value ='Reactive' and ((createdon)::date between p_fromdate and p_todate)),9),
    		('Non-Reactive',(select count(componentname) from lab_txn_testcomponentresult where componentname='HCV' and value ='Non-Reactive' and ((createdon)::date between p_fromdate and p_todate)),10);
    
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