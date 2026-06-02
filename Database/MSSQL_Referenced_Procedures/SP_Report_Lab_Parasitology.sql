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
CREATE PROCEDURE [dbo].[SP_Report_Lab_Parasitology]
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
		(null,'Sp. Gravity',19)

insert into  @tempTable0(ViewName,counts,seq) values 
		('Positive',(select count(componentname) from LAB_TXN_TestComponentResult where ComponentName='Stool Occult Blood' and value ='Positive' and (convert(date,CreatedOn) between @FromDate and @ToDate)),3),
		('Negative',(select count(componentname) from LAB_TXN_TestComponentResult where ComponentName='Stool Occult Blood' and value ='Negative' and (convert(date,CreatedOn) between @FromDate and @ToDate)),4),
--		('Positive',(select count(componentname) from LAB_TXN_TestComponentResult where ComponentName='Ketone Bodies' and value ='Positive' and (convert(date,CreatedOn) between @FromDate and @ToDate)),7),
--		('Negative',(select count(componentname) from LAB_TXN_TestComponentResult where ComponentName='Ketone Bodies' and value ='Negative' and (convert(date,CreatedOn) between @FromDate and @ToDate)),8),
		('Positive',(select count(componentname) from LAB_TXN_TestComponentResult where ComponentName='Urine for Acetone' and value ='Positive' and (convert(date,CreatedOn) between @FromDate and @ToDate)),14),
		('Negative',(select count(componentname) from LAB_TXN_TestComponentResult where ComponentName='Urine for Acetone' and value ='Negative' and (convert(date,CreatedOn) between @FromDate and @ToDate)),15)

select seq,ViewName,isnull(tbl.counts,count(LabTestName)) as Quantity from @tempTable0 tbl
left join 
LAB_TestRequisition testreq on tbl.TestName = testreq.LabTestName and 
	(testreq.BillingStatus = 'unpaid' or testreq.BillingStatus = 'paid') and
	--changed: sud:4Jan'18:DateConversion
	(convert(date,testreq.OrderDateTime) between @FromDate and @ToDate)
group by seq,ViewName,counts
order by seq
END