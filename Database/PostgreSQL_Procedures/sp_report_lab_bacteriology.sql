/*
FileName: [SP_Report_Lab_Bacteriology]
CreatedBy/date: Ramavtar/2017-10-11
Description: to get number of times the given labtest performed
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Ramavtar/2017-10-11					created the script
2		Ramavtar/2017-11-24					alter the script
3		Hari/2017-12-07						alter the script
4		Ramavtar/2018-05-12					removed urine counts (only urine C/S is kept)
*/
CREATE OR REPLACE FUNCTION sp_report_lab_bacteriology(
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
    columns: testname, viewname, counts, seq	-- add counts column only when needed (when we required count for another table then add counts column else not)
    taking count for test whose billing status are 'paid' and 'unpaid' (ignoring return and cancel)
    for some row, we are getting count from lab_txn_testcomponentresult so we write expression there itself in insert into statement
    */
    
    
    insert into  v_temptable0(testname,viewname,seq) values 
    		(null,'Gm Stain',1),
    		('Blood c/s','Blood',2),
    		('Urine C/S','Urine C/S',3),
    --		('Urine RE/ME','Urine RE/ME',4),
    --		('Urine Ketone bodies/acetone','Urine Acetone',5),
    		('Body fluid Examination','Body Fluid',8),
    		('SWab Culture & Sensitivity (Anaerobic)','Swab',9),
    		('Swab Culture & Sensitivity (Aerobic)','Swab',9),
    		('Stool C/S','Stool',10),
    		(null,'Water',11),
    		('Pus Culture','Pus',12),
    		('Sputum C/S','Sputum',13),
    		(null,'ENT',14),
    		(null,'CSF',15),
    		('Body fluid Examination','Body Fluid AFB',16),
    		('Sputum AFB Stain(single slide)','Sputum AFB',17),
    		(null,'Leprosy Smear',18),
    		('Widal Test','Widal',19),
    		(null,'Fungus',20),
    		('Leptospira','Leptospira',21),
    		('H.Pylori','H. Pylori',24);
    		
    insert into  v_temptable0(viewname,counts,seq) values 
    --		('Positive',(select count(componentname) from lab_txn_testcomponentresult where componentname='Urine for Acetone' and value ='Positive' and (convert(date,createdon) between p_fromdate and p_todate)),6),
    --		('Negative',(select count(componentname) from lab_txn_testcomponentresult where componentname='Urine for Acetone' and value ='Negative' and (convert(date,createdon) between p_fromdate and p_todate)),7),
    		('Positive',(select count(distinct requisitionid) from lab_txn_testcomponentresult where componentname like 'Leptospira%' and value ='Positive' and ((createdon)::date between p_fromdate and p_todate)),22),
    		('Negative',(select count(distinct requisitionid) from lab_txn_testcomponentresult where componentname like 'Leptospira%' and value ='Negative' and ((createdon)::date between p_fromdate and p_todate)),23),
    		('Positive',(select count(componentname) from lab_txn_testcomponentresult where componentname='Helicobacter Pylori   Antigen' and value ='Positive' and ((createdon)::date between p_fromdate and p_todate)),25),
    		('Negative',(select count(componentname) from lab_txn_testcomponentresult where componentname='Helicobacter Pylori   Antigen' and value ='Negative' and ((createdon)::date between p_fromdate and p_todate)),26);
    
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