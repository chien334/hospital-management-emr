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
CREATE PROCEDURE [dbo].[SP_Report_Lab_Biochemistry]
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
declare @tempTable0 table (TestName varchar(100),ViewName varchar(100),seq int)

insert into  @tempTable0 values 
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
		('SGOT(AST)','SGOT',19)

select seq,ViewName,count(LabTestName) as Quantity from @tempTable0 tbl
left join 
LAB_TestRequisition testreq on tbl.TestName = testreq.LabTestName and 
	(testreq.BillingStatus = 'unpaid' or testreq.BillingStatus = 'paid') and
	--changed: sud:4Jan'18:DateConversion
	(convert(date,testreq.OrderDateTime) between @FromDate and @ToDate)
group by seq,ViewName
order by seq
declare @tempTable1 table (TestName varchar(100),ViewName varchar(100),seq int)

insert into  @tempTable1 values 
		('Liver Function Test(LFT)(Billirubin T/D, SGPT, SGOT,ALP)','SGPT',1),
		('SGPT(ALT)','SGPT',1),
		('Alkaline Phosphatase (ALP)','Alk Phos',2),
		('Liver Function Test(LFT)(Billirubin T/D, SGPT, SGOT,ALP)','Alk Phos',2),
		('Liver Function Test(LFT)(Billirubin T/D, SGPT, SGOT,ALP)','Bili-T',3),
		('S. Billirubin (Total & Direct)','Bili-T',3),
		('billirubin','Bili-T',3),
		('Liver Function Test(LFT)(Billirubin T/D, SGPT, SGOT,ALP)','Bili-D',4),
		('S. Billirubin (Total & Direct)','Bili-D',4),
		('billirubin','Bili-D',4),
		('Na + (Sodium)','Na+',5),
		('Na+/K+ (Sodium & Potassium)','Na+',5),
		('RFT (Urea, Creatinine, Na+, K+, Uric acid)','Na+',5),
		('K+ (Potassium)','K+',6),
		('Na+/K+ (Sodium & Potassium)','K+',6),
		('RFT (Urea, Creatinine, Na+, K+, Uric acid)','K+',6),
		('ADA','ADA',7),
		('Magnesium','Magnesium',8),
		('-24 hours urine protein','24hr Protein',9),
		('-24 hours urine protein','24hr Urine U/A',10),
		(null,'Creatinine Clearance',11),
		('Lipid Profile (Cholesterol, Triglyceride, HDL, LDL, VLDL)','Lipid Profile',12)

select seq,ViewName,count(LabTestName) as Quantity from @tempTable1 tbl1
left join 
LAB_TestRequisition testreq on tbl1.TestName = testreq.LabTestName and 
	(testreq.BillingStatus = 'unpaid' or testreq.BillingStatus = 'paid') and
	--changed: sud:4Jan'18:DateConversion
	(convert(date,testreq.OrderDateTime) between @FromDate and @ToDate)
group by seq,ViewName
order by seq

END