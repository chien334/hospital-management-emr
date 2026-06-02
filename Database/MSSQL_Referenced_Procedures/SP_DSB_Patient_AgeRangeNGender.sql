CREATE PROCEDURE [dbo].[SP_DSB_Patient_AgeRangeNGender]
AS
/*
FileName: [SP_DSB_Patient_AgeRangeNGender]
CreatedBy/date: sudarshan/2017-07-09
Description: to get gender+Age Range wise count of all registered patients.
Remarks:  
Change History
S.No.    UpdatedBy/Date                        Remarks
1        sudarshan/2017-07-09	               created
*/
BEGIN
	declare @TblAgeGroup table(AgeRange varchar(20), Seq int)
	insert into @TblAgeGroup values('0-9 Years',1)
	insert into @TblAgeGroup values('10-19 Years',2)
	insert into @TblAgeGroup values('20-59 Years',3)
	insert into @TblAgeGroup values('>=60 Years',4)
   

     SELECT  dbo.GetDobAgeRange(DateOfBirth,getdate()) AgeRange, 
	  ISNULL( SUM(CASE WHEN p.Gender = 'Male' THEN 1 END),0) AS Male,
	  ISNULL( SUM(CASE WHEN p.Gender = 'Female' THEN 1 END),0) AS Female,
	  ISNULL( SUM(CASE WHEN p.Gender = 'Others' THEN 1 END),0) AS Others
	FROM PAT_Patient p, @TblAgeGroup tbl
	WHERE dbo.GetDobAgeRange(DateOfBirth,getdate()) = tbl.AgeRange
	GRoup by dbo.GetDobAgeRange(DateOfBirth,getdate()), tbl.Seq
	Order by tbl.Seq

END