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
CREATE PROCEDURE [dbo].[SP_Report_Lab_Haematology]
	-- Add the parameters for the stored procedure here
	@FromDate DATETIME = NULL,
	@ToDate DATETIME = NULL
AS
BEGIN
--changed: sud:4Jan'18: default fromdate and todate are today's date.
  set @FromDate = Convert(date,ISNULL(@FromDate,getdate()))
  set @ToDate = Convert(date,ISNULL(@ToDate,getdate()))

/*
creating temporary table and inserting values which we need on screen
columns: TestName, ViewName, counts, seq	-- add counts column only when needed (when we required count for another table then add counts column else dont)
taking count for test whose billing status are 'paid' and 'unpaid' (ignoring return and cancel)
for some row, we are getting count from LAB_TXN_TestComponentResult so we write expression there itself in insert statement
*/
declare @tempTable0 table (TestName varchar(100),ViewName varchar(100),counts int,seq int)

insert into  @tempTable0(TestName,ViewName,seq) values 
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
		('CT','CT',20)
insert into @tempTable0(ViewName,counts,seq) values
		('Neutro',(select count(componentname) from LAB_TXN_TestComponentResult where ComponentName='neutrophil' and value !='00' and value !='0' and (convert(date,CreatedOn) between @FromDate and @ToDate)),5),
		('lympho',(select count(componentname) from LAB_TXN_TestComponentResult where ComponentName='Lymphocyte' and value !='00' and value !='0' and (convert(date,CreatedOn) between @FromDate and @ToDate)),6),
		('Mono',(select count(componentname) from LAB_TXN_TestComponentResult where ComponentName='Monocyte' and value !='00' and value !='0' and (convert(date,CreatedOn) between @FromDate and @ToDate)),7),
		('Eosino',(select count(componentname) from LAB_TXN_TestComponentResult where ComponentName='Eosinophil' and value !='00' and value !='0' and (convert(date,CreatedOn) between @FromDate and @ToDate)),8),
		('Baso',(select count(componentname) from LAB_TXN_TestComponentResult where ComponentName='Basophil' and value !='00' and value !='0' and (convert(date,CreatedOn) between @FromDate and @ToDate)),9),
		('PCV',(select count(componentname) from LAB_TXN_TestComponentResult where ComponentName='PCV' and value !='00' and value !='0' and (convert(date,CreatedOn) between @FromDate and @ToDate)),15),
		('MCV',(select count(componentname) from LAB_TXN_TestComponentResult where ComponentName='MCV' and value !='00' and value !='0' and (convert(date,CreatedOn) between @FromDate and @ToDate)),16),
		('MCH',(select count(componentname) from LAB_TXN_TestComponentResult where ComponentName='MCH' and value !='00' and value !='0' and (convert(date,CreatedOn) between @FromDate and @ToDate)),17),
		('MCHC',(select count(componentname) from LAB_TXN_TestComponentResult where ComponentName='MCHC' and value !='00' and value !='0' and (convert(date,CreatedOn) between @FromDate and @ToDate)),18)


select seq,ViewName,isnull(tbl.counts,count(LabTestName)) as Quantity from @tempTable0 tbl
left join 
LAB_TestRequisition testreq on tbl.TestName = testreq.LabTestName and 
	(testreq.BillingStatus = 'unpaid' or testreq.BillingStatus = 'paid') and
	--changed: sud:4Jan'18:DateConversion
	(convert(date,testreq.OrderDateTime) between @FromDate and @ToDate)
group by seq,ViewName,counts
order by seq
declare @tempTable1 table (TestName varchar(100),ViewName varchar(100),counts int,seq int)

insert into  @tempTable1(TestName,ViewName,seq) values 
		(null,'PT',1),
		('APTT','APTT',2),
		('PT/INR','PT-INR',3),
		('Blood Group','Blood Group',4),
		(null,'Rh Type',5),
		(null,'BM CSF Spleen Aspiratee',6),
		(null,'Aldehyde',7),
		('MP Serology','MP Total',8),
		(null,'MF',11),
		('HBA1c','HbA1c',12),
		(null,'Hb Electrophoresis',13),
		(null,'LE',14),
		('D-Dimer','FDP/ D-dimer',15),
		(null,'AEC',16)
insert into @tempTable1(ViewName,counts,seq) values
		('Positive',(select count(componentname) from LAB_TXN_TestComponentResult where ComponentName='Malarial Parasite Test' and value ='Positive' and (convert(date,CreatedOn) between @FromDate and @ToDate)),9),
		('Negative',(select count(componentname) from LAB_TXN_TestComponentResult where ComponentName='Malarial Parasite Test' and value ='Negative' and (convert(date,CreatedOn) between @FromDate and @ToDate)),10)

select seq,ViewName,isnull(tbl1.counts,count(LabTestName)) as Quantity from @tempTable1 tbl1
left join 
LAB_TestRequisition testreq on tbl1.TestName = testreq.LabTestName and 
	(testreq.BillingStatus = 'unpaid' or testreq.BillingStatus = 'paid') and
	--changed: sud:4Jan'18:DateConversion
	(convert(date,testreq.OrderDateTime) between @FromDate and @ToDate)
group by seq,ViewName,counts
order by seq

END