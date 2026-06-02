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
CREATE PROCEDURE [dbo].[SP_Report_Lab_Immunology]
	-- Add the parameters for the stored procedure here
	@FromDate DATETIME=NULL,
	@ToDate DATETIME= NULL
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
		(null,'Echino-coccus',27)

insert into @tempTable0(ViewName,counts,seq) values 
		('Positive',(select count(componentname) from LAB_TXN_TestComponentResult where ComponentName='UPT (Urinary Beta HCG)' and value ='Positive' and (convert(date,CreatedOn) between @FromDate and @ToDate)),2),
		('Negative',(select count(componentname) from LAB_TXN_TestComponentResult where ComponentName='UPT (Urinary Beta HCG)' and value ='Negative' and (convert(date,CreatedOn) between @FromDate and @ToDate)),3),
		('Positive',(select count(componentname) from LAB_TXN_TestComponentResult where ComponentName='CRP' and value ='Positive' and (convert(date,CreatedOn) between @FromDate and @ToDate)),6),
		('Negative',(select count(componentname) from LAB_TXN_TestComponentResult where ComponentName='CRP' and value ='Negative' and (convert(date,CreatedOn) between @FromDate and @ToDate)),7),
		('Positive',(select count(componentname) from LAB_TXN_TestComponentResult where ComponentName='RA Factor' and value ='Positive' and (convert(date,CreatedOn) between @FromDate and @ToDate)),10),
		('Negative',(select count(componentname) from LAB_TXN_TestComponentResult where ComponentName='RA Factor' and value ='Negative' and (convert(date,CreatedOn) between @FromDate and @ToDate)),11),
		('Reactive',(select count(componentname) from LAB_TXN_TestComponentResult where ComponentName='VDRL' and value ='Reactive' and (convert(date,CreatedOn) between @FromDate and @ToDate)),18),
		('Non-Reactive',(select count(componentname) from LAB_TXN_TestComponentResult where ComponentName='VDRL' and value ='Non-Reactive' and (convert(date,CreatedOn) between @FromDate and @ToDate)),19)

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
		(null,'Amoebiasis',1),
		(null,'F-Protein',2),
		('PSA (Total)','PSA',3),
		(null,'Ferritine',4),
		(null,'Cysticercosis',5),
		('Brucella Antibody','Brucella',6),
		(null,'Thyroglobulin',7),
		(null,'Electrophoresis',8),
		('B-HCG','Beta-HCG',9),
		(null,'RK-39',10),
		(null,'JE',11),
		('Dengue serology','Dengue',12),
		(null,'Rapid MP Test',15),
		('Mantoux test','Mantoux',16),
		('Scrub Typhus (Elisa Method)','Scrub Typhus',17),
		('Scrub Typhus (Rapid Method)','Scrub Typhus',17)

insert into @tempTable1(ViewName,counts,seq) values 
		('Positive',(select count(distinct RequisitionId) from LAB_TXN_TestComponentResult where ComponentName like 'Dengue%' and value ='Positive' and (convert(date,CreatedOn) between @FromDate and @ToDate)),13),
		('Negative',(select count(distinct RequisitionId) from LAB_TXN_TestComponentResult where ComponentName like 'Dengue%' and value ='Negative' and (convert(date,CreatedOn) between @FromDate and @ToDate)),14),
		('Positive',(select count(distinct RequisitionId) from LAB_TXN_TestComponentResult where ComponentName like 'Scrub Typhus%' and value ='Positive' and (convert(date,CreatedOn) between @FromDate and @ToDate)),18),
		('Negative',(select count(distinct RequisitionId) from LAB_TXN_TestComponentResult where ComponentName like 'Scrub Typhus%' and value ='Negative' and (convert(date,CreatedOn) between @FromDate and @ToDate)),19)

select seq,ViewName,isnull(tbl1.counts,count(LabTestName)) as Quantity from @tempTable1 tbl1
left join 
LAB_TestRequisition testreq on tbl1.TestName = testreq.LabTestName and 
	(testreq.BillingStatus = 'unpaid' or testreq.BillingStatus = 'paid') and
	--changed: sud:4Jan'18:DateConversion
	(convert(date,testreq.OrderDateTime) between @FromDate and @ToDate)
group by seq,ViewName,counts
order by seq
END