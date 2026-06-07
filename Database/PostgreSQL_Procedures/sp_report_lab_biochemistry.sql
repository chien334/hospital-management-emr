/*
FileName: [SP_Report_Lab_Biochemistry]
CreatedBy/date: Ramavtar/2017-10-11
Description: to get number of times the given labtest performed
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Ramavtar/2017-10-11					created the script
2		Ramavtar/2017-11-24					alter the script
3		Hari/2017-12-07						alter the script
4		Ramavtar/2018-02-22					changed: added one more test to 'Alk Phos' count

*/
CREATE OR REPLACE FUNCTION sp_report_lab_biochemistry(
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
        TestName varchar(100),ViewName varchar(100),seq int
    );
    DROP TABLE IF EXISTS v_temptable1;
    CREATE TEMP TABLE v_temptable1 (
        TestName varchar(100),ViewName varchar(100),seq int
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
    
    
    insert into  v_temptable0 values 
    		('FBS','Sugar-F',1),
    		('FBS+PPBS','Sugar-F',1),
    		('PPBS','Sugar-PP',2),
    		('FBS+PPBS','Sugar-PP',2),
    		('RBS','Sugar-R',3),
    		('Urea','Blood Urea',4),
    		('Blood Urea Nitrogen(BUN)','Blood Urea',4),
    		('RFT (Urea, Creatinine, Na+, K+, Uric acid)','Blood Urea',4),
    		('Creatinine','Creatinine',5),
    		('RFT (Urea, Creatinine, Na+, K+, Uric acid)','Creatinine',5),
    		('Uric Acid','Uric Acid',6),
    		('RFT (Urea, Creatinine, Na+, K+, Uric acid)','Uric Acid',6),
    		('Total Protein','Protein',7),
    		('Albumin','Albumin',8),
    		('Microalbumin','Microalbumin',9),
    		('Lipid Profile (Cholesterol, Triglyceride, HDL, LDL, VLDL)','Total Choles',10),
    		('Cholesterol','Total Choles',10),
    		('Lipid Profile (Cholesterol, Triglyceride, HDL, LDL, VLDL)','HDL',11),
    		('HDL','HDL',11),
    		('Lipid Profile (Cholesterol, Triglyceride, HDL, LDL, VLDL)','TG',12),
    		('Lipid Profile (Cholesterol, Triglyceride, HDL, LDL, VLDL)','LDL',13),
    		('LDL','LDL',13),
    		('Lipid Profile (Cholesterol, Triglyceride, HDL, LDL, VLDL)','VLDL',14),
    		('VLDL','VLDL',14),
    		('Calcium','Calcium',15),
    		('Phosphorous','Phos-phorous',16),
    		('Amylase','Amylase',17),
    		('Gamma GT (YGT)','Gamma GT',18),
    		('Liver Function Test(LFT)(Billirubin T/D, SGPT, SGOT,ALP)','SGOT',19),
    		('SGOT(AST)','SGOT',19);
    
    select seq,viewname,count(labtestname) as quantity from v_temptable0 tbl
    left join 
    lab_testrequisition testreq on tbl.testname = testreq.labtestname and 
    	(testreq.billingstatus = 'unpaid' or testreq.billingstatus = 'paid') and
    	--changed: sud:4jan'18:DateConversion
    	((testreq.OrderDateTime)::date between p_fromdate and p_todate)
    group by seq,ViewName
    order by seq;
    
    
    insert into  v_temptable1 values 
    		('liver function test(lft)(billirubin t/d, sgpt, sgot,alp)','sgpt',1),
    		('sgpt(alt)','sgpt',1),
    		('alkaline phosphatase (alp)','alk phos',2),
    		('liver function test(lft)(billirubin t/d, sgpt, sgot,alp)','alk phos',2),
    		('liver function test(lft)(billirubin t/d, sgpt, sgot,alp)','bili-t',3),
    		('s. billirubin (total & direct)','bili-t',3),
    		('billirubin','bili-t',3),
    		('liver function test(lft)(billirubin t/d, sgpt, sgot,alp)','bili-d',4),
    		('s. billirubin (total & direct)','bili-d',4),
    		('billirubin','bili-d',4),
    		('na + (sodium)','na+',5),
    		('na+/k+ (sodium & potassium)','na+',5),
    		('rft (urea, creatinine, na+, k+, uric acid)','na+',5),
    		('k+ (potassium)','k+',6),
    		('na+/k+ (sodium & potassium)','k+',6),
    		('rft (urea, creatinine, na+, k+, uric acid)','k+',6),
    		('ada','ada',7),
    		('magnesium','magnesium',8),
    		('-24 hours urine protein','24hr protein',9),
    		('-24 hours urine protein','24hr urine u/a',10),
    		(null,'creatinine clearance',11),
    		('lipid profile (cholesterol, triglyceride, hdl, ldl, vldl)','lipid profile',12);
    
    select seq,ViewName,count(LabTestName) as Quantity from v_temptable1 tbl1
    left join 
    LAB_TestRequisition testreq on tbl1.TestName = testreq.LabTestName and 
    	(testreq.BillingStatus = 'unpaid' or testreq.BillingStatus = 'paid') and
    	--changed: sud:4Jan'18:dateconversion
    	((testreq.orderdatetime)::date between p_fromdate and p_todate)
    group by seq,viewname
    order by seq;
END;
$$ LANGUAGE plpgsql;