/*
FileName: [SP_Report_Lab_Cytology]
CreatedBy/date: Ramavtar/2017-10-11
Description: to get number of times the given labtest performed
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Ramavtar/2017-10-11					created the script
2		Ramavtar/2017-11-24					alter the script
3		Hari/2017-12-07						alter the script
*/
CREATE PROCEDURE [dbo].[SP_Report_Lab_Cytology]
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
declare @tempTable0 table (TestName varchar(100),ViewName varchar(100),seq int)

insert into  @tempTable0 values 
		('PAP Smear','PAP',1),
		(null,'Sputum',2),
		(null,'Body Fluid',3),
		(null,'FNAC',4)

select seq,ViewName,count(LabTestName) as Quantity from @tempTable0 tbl
left join 
LAB_TestRequisition testreq on tbl.TestName = testreq.LabTestName and 
	(testreq.BillingStatus = 'unpaid' or testreq.BillingStatus = 'paid') and
	--changed: sud:4Jan'18:DateConversion
	(convert(date,testreq.OrderDateTime) between @FromDate and @ToDate)
group by seq,ViewName
order by seq
END