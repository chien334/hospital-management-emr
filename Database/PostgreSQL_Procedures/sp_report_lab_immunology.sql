/*
FileName: [SP_Report_Lab_Immunology]
CreatedBy/date: Ramavtar/2017-10-11
Description: to get number of times the given labtest performed
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Ramavtar/2017-10-11					created the script
2		Ramavtar/2017-11-24					alter the script
3		Hari/2017-12-07						alter the script
*/
CREATE OR REPLACE FUNCTION sp_report_lab_immunology(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
BEGIN
    DROP TABLE IF EXISTS v_temptable0;
    CREATE TEMP TABLE v_temptable0 (
        TestName varchar(100),ViewName varchar(100),counts int,seq int
    );
    DROP TABLE IF EXISTS v_temptable1;
    CREATE TEMP TABLE v_temptable1 (
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
    		('UPT(Urinary Beta HCG)','Pregnancy Test',1),
    		('ASO Titre','ASO',4),
    		('CRP','CRP',5),
    		('CRP-Quantatitive','CRP Quantatitive',8),
    		('RA Factor','RA Factor',9),
    		('RA Factor Quantitative','RA Factor Quantitative',12),
    		('Anti CCP Quantitative','Anti CCP',13),
    		('TPHA','TPHA',14),
    		('ANA','ANA',15),
    		('DS DNA','DNA-ELISA',16),
    		('VDRL','RPR-VDRL',17),
    		('CEA','CEA',20),
    		('CA 125','CA-125',21),
    		('CA-19.9','Ca 19-9',22),
    		(null,'Ca 15.3',23),
    		('TORGH (IGGl1gm)','TORCH IG-G/M',24),
    		(null,'MEASLES-IG-G',25),
    		(null,'RUBELLA-IGG',26),
    		(null,'Echino-coccus',27);
    
    insert into v_temptable0(viewname,counts,seq) values 
    		('Positive',(select count(componentname) from lab_txn_testcomponentresult where componentname='UPT (Urinary Beta HCG)' and value ='Positive' and ((createdon)::date between p_fromdate and p_todate)),2),
    		('Negative',(select count(componentname) from lab_txn_testcomponentresult where componentname='UPT (Urinary Beta HCG)' and value ='Negative' and ((createdon)::date between p_fromdate and p_todate)),3),
    		('Positive',(select count(componentname) from lab_txn_testcomponentresult where componentname='CRP' and value ='Positive' and ((createdon)::date between p_fromdate and p_todate)),6),
    		('Negative',(select count(componentname) from lab_txn_testcomponentresult where componentname='CRP' and value ='Negative' and ((createdon)::date between p_fromdate and p_todate)),7),
    		('Positive',(select count(componentname) from lab_txn_testcomponentresult where componentname='RA Factor' and value ='Positive' and ((createdon)::date between p_fromdate and p_todate)),10),
    		('Negative',(select count(componentname) from lab_txn_testcomponentresult where componentname='RA Factor' and value ='Negative' and ((createdon)::date between p_fromdate and p_todate)),11),
    		('Reactive',(select count(componentname) from lab_txn_testcomponentresult where componentname='VDRL' and value ='Reactive' and ((createdon)::date between p_fromdate and p_todate)),18),
    		('Non-Reactive',(select count(componentname) from lab_txn_testcomponentresult where componentname='VDRL' and value ='Non-Reactive' and ((createdon)::date between p_fromdate and p_todate)),19);
    
    select seq,viewname,coalesce(tbl.counts,count(labtestname)) as quantity from v_temptable0 tbl
    left join 
    lab_testrequisition testreq on tbl.testname = testreq.labtestname and 
    	(testreq.billingstatus = 'unpaid' or testreq.billingstatus = 'paid') and
    	--changed: sud:4jan'18:DateConversion
    	((testreq.OrderDateTime)::date between p_fromdate and p_todate)
    group by seq,ViewName,counts
    order by seq;
    
    
    insert into  v_temptable1(TestName,ViewName,seq) values 
    		(null,'amoebiasis',1),
    		(null,'f-protein',2),
    		('psa (total)','psa',3),
    		(null,'ferritine',4),
    		(null,'cysticercosis',5),
    		('brucella antibody','brucella',6),
    		(null,'thyroglobulin',7),
    		(null,'electrophoresis',8),
    		('b-hcg','beta-hcg',9),
    		(null,'rk-39',10),
    		(null,'je',11),
    		('dengue serology','dengue',12),
    		(null,'rapid mp test',15),
    		('mantoux test','mantoux',16),
    		('scrub typhus (elisa method)','scrub typhus',17),
    		('scrub typhus (rapid method)','scrub typhus',17);
    
    insert into v_temptable1(ViewName,counts,seq) values 
    		('positive',(select count(distinct RequisitionId) from LAB_TXN_TestComponentResult where ComponentName like 'dengue%' and value ='positive' and ((CreatedOn)::date between p_fromdate and p_todate)),13),
    		('negative',(select count(distinct RequisitionId) from LAB_TXN_TestComponentResult where ComponentName like 'dengue%' and value ='negative' and ((CreatedOn)::date between p_fromdate and p_todate)),14),
    		('positive',(select count(distinct RequisitionId) from LAB_TXN_TestComponentResult where ComponentName like 'scrub typhus%' and value ='positive' and ((CreatedOn)::date between p_fromdate and p_todate)),18),
    		('negative',(select count(distinct RequisitionId) from LAB_TXN_TestComponentResult where ComponentName like 'scrub typhus%' and value ='negative' and ((CreatedOn)::date between p_fromdate and p_todate)),19);
    
    select seq,ViewName,COALESCE(tbl1.counts,count(LabTestName)) as Quantity from v_temptable1 tbl1
    left join 
    LAB_TestRequisition testreq on tbl1.TestName = testreq.LabTestName and 
    	(testreq.BillingStatus = 'unpaid' or testreq.BillingStatus = 'paid') and
    	--changed: sud:4Jan'18:dateconversion
    	((testreq.orderdatetime)::date between p_fromdate and p_todate)
    group by seq,viewname,counts
    order by seq;
END;
$$ LANGUAGE plpgsql;