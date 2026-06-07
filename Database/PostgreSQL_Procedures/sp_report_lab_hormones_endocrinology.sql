/*
FileName: [SP_Report_Lab_Hormones_Endocrinology]
CreatedBy/date: Ramavtar/2017-10-11
Description: to get number of times the given labtest performed
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Ramavtar/2017-10-11					created the script
2		Ramavtar/2017-11-24					alter the script
3		Hari/2017-12-07						alter the script
*/
CREATE OR REPLACE FUNCTION sp_report_lab_hormones_endocrinology(
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
        TestName varchar(100),ViewName varchar(100),seq int
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
    
    
    insert into  v_temptable0 values 
    		('T3/FT3','T3',1),
    		('TFT(T3,T4,TSH)','T3',1),
    		('T4/FT4','T4',2),
    		('TFT(T3,T4,TSH)','T4',2),
    		('TSH','TSH',3),
    		('TFT(T3,T4,TSH)','TSH',3),
    		(null,'Cortisol',4),
    		('Alpha Feto Protein','a feto protein',5),
    		('LH','LH',6),
    		('FSH','FSH',7),
    		(null,'Pro-lactine',8),
    		(null,'Oestrogen',9),
    		(null,'Progesterone',10),
    		(null,'Testosterone',11),
    		('Anti TPO(Anti Thyroperioxidase)','Anti TPO',12),
    		('Vitamin D','Vitamin D',13),
    		('Iron Profile','Iron Profile',14),
    		('PSA (Total)','PSA',15);
    		
    RETURN QUERY SELECT seq,viewname,count(labtestname) AS "Quantity" from v_temptable0 tbl
    left join 
    lab_testrequisition testreq on tbl.testname = testreq.labtestname and 
    	(testreq.billingstatus = 'unpaid' or testreq.billingstatus = 'paid') and
    	--changed: sud:4jan'18:dateconversion
    	((testreq.orderdatetime)::date between p_fromdate and p_todate)
    group by seq,viewname
    order by seq;
END;
$$ LANGUAGE plpgsql;