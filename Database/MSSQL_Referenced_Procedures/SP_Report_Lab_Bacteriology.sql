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
CREATE PROCEDURE [dbo].[SP_Report_Lab_Bacteriology]
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
columns: TestName, ViewName, counts, seq	-- add counts column only when needed (when we required count for another table then add counts column else not)
taking count for test whose billing status are 'paid' and 'unpaid' (ignoring return and cancel)
for some row, we are getting count from LAB_TXN_TestComponentResult so we write expression there itself in insert statement
*/
declare @tempTable0 table (TestName varchar(100),ViewName varchar(100),counts int,seq int)

insert into  @tempTable0(TestName,ViewName,seq) values 
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
		('H.Pylori','H. Pylori',24)
		
insert into  @tempTable0(ViewName,counts,seq) values 
--		('Positive',(select count(componentname) from LAB_TXN_TestComponentResult where ComponentName='Urine for Acetone' and value ='Positive' and (convert(date,CreatedOn) between @FromDate and @ToDate)),6),
--		('Negative',(select count(componentname) from LAB_TXN_TestComponentResult where ComponentName='Urine for Acetone' and value ='Negative' and (convert(date,CreatedOn) between @FromDate and @ToDate)),7),
		('Positive',(select count(distinct RequisitionId) from LAB_TXN_TestComponentResult where ComponentName like 'Leptospira%' and value ='Positive' and (convert(date,CreatedOn) between @FromDate and @ToDate)),22),
		('Negative',(select count(distinct RequisitionId) from LAB_TXN_TestComponentResult where ComponentName like 'Leptospira%' and value ='Negative' and (convert(date,CreatedOn) between @FromDate and @ToDate)),23),
		('Positive',(select count(componentname) from LAB_TXN_TestComponentResult where ComponentName='Helicobacter Pylori   Antigen' and value ='Positive' and (convert(date,CreatedOn) between @FromDate and @ToDate)),25),
		('Negative',(select count(componentname) from LAB_TXN_TestComponentResult where ComponentName='Helicobacter Pylori   Antigen' and value ='Negative' and (convert(date,CreatedOn) between @FromDate and @ToDate)),26)

select seq,ViewName,isnull(tbl.counts,count(LabTestName)) as Quantity from @tempTable0 tbl
left join 
LAB_TestRequisition testreq on tbl.TestName = testreq.LabTestName and 
	(testreq.BillingStatus = 'unpaid' or testreq.BillingStatus = 'paid') and
	--changed: sud:4Jan'18:DateConversion
	(convert(date,testreq.OrderDateTime) between @FromDate and @ToDate)
group by seq,ViewName,counts
order by seq
END