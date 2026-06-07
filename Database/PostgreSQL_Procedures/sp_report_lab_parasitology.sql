/*
FileName: [SP_Report_Lab_Parasitology]
CreatedBy/date: Ramavtar/2017-10-11
Description: to get number of times the given labtest performed
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Ramavtar/2017-10-11					created the script
2		Ramavtar/2017-11-24					alter the script
3		Hari/2017-12-07						alter the script
4		Ramavtar/2018-05-12					remove positive/negative count from urine R/E
*/
CREATE OR REPLACE FUNCTION sp_report_lab_parasitology(
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
    		('Stool RE/ME','Stool R/E',1),
    		('Stool occult blood','Occult blood',2),
    		('Reducing Sugar','Reducing Sugar',5),
    		('Urine RE/ME','Urine R/E',6),
    		('Bile Salt','Bile Salts',9),
    		('Bile Pigment','Bile Pigments',10),
    		(null,'Urobilinogen',11),
    		(null,'Porphobilinogen',12),
    		('Urine Ketone bodies/acetone','Acetone',13),
    		('Chyle','Chyle',16),
    		('Semen Analysis','Semen Analysis',17),
    		('Bence Jones Protein','Bence Jones Prot',18),
    		(null,'Sp. Gravity',19);
    
    insert into  v_temptable0(viewname,counts,seq) values 
    		('Positive',(select count(componentname) from lab_txn_testcomponentresult where componentname='Stool Occult Blood' and value ='Positive' and ((createdon)::date between p_fromdate and p_todate)),3),
    		('Negative',(select count(componentname) from lab_txn_testcomponentresult where componentname='Stool Occult Blood' and value ='Negative' and ((createdon)::date between p_fromdate and p_todate)),4),
    --		('Positive',(select count(componentname) from lab_txn_testcomponentresult where componentname='Ketone Bodies' and value ='Positive' and (convert(date,createdon) between p_fromdate and p_todate)),7),
    --		('Negative',(select count(componentname) from lab_txn_testcomponentresult where componentname='Ketone Bodies' and value ='Negative' and (convert(date,createdon) between p_fromdate and p_todate)),8),
    		('Positive',(select count(componentname) from lab_txn_testcomponentresult where componentname='Urine for Acetone' and value ='Positive' and ((createdon)::date between p_fromdate and p_todate)),14),
    		('Negative',(select count(componentname) from lab_txn_testcomponentresult where componentname='Urine for Acetone' and value ='Negative' and ((createdon)::date between p_fromdate and p_todate)),15);
    
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