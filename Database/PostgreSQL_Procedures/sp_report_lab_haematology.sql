/*
FileName: [SP_Report_Lab_Haematology]
CreatedBy/date: Ramavtar/2017-10-11
Description: to get number of times the given labtest performed
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Ramavtar/2017-10-11					created the script
2		Ramavtar/2017-11-24					alter the script
3		Hari/2017-12-07						alter the script
4       Hari/2018-03-22           added extra components (eg:PCV,MCV,MCH,MCHC) in the reports.
*/
CREATE OR REPLACE FUNCTION sp_report_lab_haematology(
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
    		('Hb%','Hb%',1),
    		('CBC(TC, DC, HB%, Platelets)','Hb%',1),
    		('RBC count','RBC',2),
    		('PBS (Peripheral Blood Smear) without CBC','RBC',2),
    		('CBC(TC, DC, HB%, Platelets)','WBC',3),
    		('PBS (Peripheral Blood Smear) without CBC','WBC',3),
    		('CBC(TC, DC, HB%, Platelets)','Platelets',4),
    		('Platelets Count','Platelets',4),
    		('PBS (Peripheral Blood Smear) without CBC','Platelets',4),
    		(null,'Bands',10),
    		(null,'Others',11),
    		('Reticulocyte Count','Retic',12),
    		('ESR','ESR',13),
    		(null,'Parasites',14),
    		('BT','BT',19),
    		('CT','CT',20);
    insert into v_temptable0(viewname,counts,seq) values
    		('Neutro',(select count(componentname) from lab_txn_testcomponentresult where componentname='neutrophil' and value !='00' and value !='0' and ((createdon)::date between p_fromdate and p_todate)),5),
    		('lympho',(select count(componentname) from lab_txn_testcomponentresult where componentname='Lymphocyte' and value !='00' and value !='0' and ((createdon)::date between p_fromdate and p_todate)),6),
    		('Mono',(select count(componentname) from lab_txn_testcomponentresult where componentname='Monocyte' and value !='00' and value !='0' and ((createdon)::date between p_fromdate and p_todate)),7),
    		('Eosino',(select count(componentname) from lab_txn_testcomponentresult where componentname='Eosinophil' and value !='00' and value !='0' and ((createdon)::date between p_fromdate and p_todate)),8),
    		('Baso',(select count(componentname) from lab_txn_testcomponentresult where componentname='Basophil' and value !='00' and value !='0' and ((createdon)::date between p_fromdate and p_todate)),9),
    		('PCV',(select count(componentname) from lab_txn_testcomponentresult where componentname='PCV' and value !='00' and value !='0' and ((createdon)::date between p_fromdate and p_todate)),15),
    		('MCV',(select count(componentname) from lab_txn_testcomponentresult where componentname='MCV' and value !='00' and value !='0' and ((createdon)::date between p_fromdate and p_todate)),16),
    		('MCH',(select count(componentname) from lab_txn_testcomponentresult where componentname='MCH' and value !='00' and value !='0' and ((createdon)::date between p_fromdate and p_todate)),17),
    		('MCHC',(select count(componentname) from lab_txn_testcomponentresult where componentname='MCHC' and value !='00' and value !='0' and ((createdon)::date between p_fromdate and p_todate)),18);
    
    
    select seq,viewname,coalesce(tbl.counts,count(labtestname)) as quantity from v_temptable0 tbl
    left join 
    lab_testrequisition testreq on tbl.testname = testreq.labtestname and 
    	(testreq.billingstatus = 'unpaid' or testreq.billingstatus = 'paid') and
    	--changed: sud:4jan'18:DateConversion
    	((testreq.OrderDateTime)::date between p_fromdate and p_todate)
    group by seq,ViewName,counts
    order by seq;
    
    
    insert into  v_temptable1(TestName,ViewName,seq) values 
    		(null,'pt',1),
    		('aptt','aptt',2),
    		('pt/inr','pt-inr',3),
    		('blood group','blood group',4),
    		(null,'rh type',5),
    		(null,'bm csf spleen aspiratee',6),
    		(null,'aldehyde',7),
    		('mp serology','mp total',8),
    		(null,'mf',11),
    		('hba1c','hba1c',12),
    		(null,'hb electrophoresis',13),
    		(null,'le',14),
    		('d-dimer','fdp/ d-dimer',15),
    		(null,'aec',16);
    insert into v_temptable1(ViewName,counts,seq) values
    		('positive',(select count(componentname) from LAB_TXN_TestComponentResult where ComponentName='malarial parasite test' and value ='positive' and ((CreatedOn)::date between p_fromdate and p_todate)),9),
    		('negative',(select count(componentname) from LAB_TXN_TestComponentResult where ComponentName='malarial parasite test' and value ='negative' and ((CreatedOn)::date between p_fromdate and p_todate)),10);
    
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