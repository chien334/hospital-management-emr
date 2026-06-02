CREATE PROCEDURE SP_Report_AgeClassifiedReport
  @FromDate DATE = '',
  @ToDate DATE = '',
  @DepartmentId INT = 0
AS

/*
FileName: [SP_Report_AgeClassifiedReport]
CreatedBy/date: 
Description: To get Departmentwise AgeClassification report  on a given date range
Remarks:    
Change History
S.No.    UpdatedBy/Date            Remarks
1     Santosh:28June'23               Complete rewrite as per new requirement to show sum in the given date range
*/
BEGIN
   DECLARE @cols AS NVARCHAR(MAX)
SELECT @cols = (SELECT  dbo.FN_COMMON_AgeClassifiedColumnNames('AgeClassification') )

DECLARE @sqlQuery NVARCHAR(MAX)
SET @sqlQuery= N'
Declare @AgeGroup nvarchar(20)    
Declare @MinDate int    
declare @MaxDate int     

Declare @temp table(     
DepartmentName nvarchar(max),    
VisitCount int,    
AgeGroup nvarchar(max) 
)

Declare DepartmentAgeReport CURSOR for 
Select AgeName,MinAgeInDays,MaxAgeInDays From CORE_MST_AgeClassification where reporttype=''AgeClassification''
open DepartmentAgeReport 
Fetch next from DepartmentAgeReport into @AgeGroup,@MinDate,@MaxDate
WHILE @@FETCH_STATUS=0 
BEGIN
Insert Into @temp   select 

    MD.DepartmentName,
    Count(PV.PatientVisitId) as VisitCount,
    @AgeGroup+''M'' as AgeGroup
from PAT_Patient    PT
    Inner join PAT_PatientVisits PV ON PT.PatientId=PV.PatientId
    INNER JOIN MST_Department MD On MD.DepartmentId=PV.DepartmentId
Where 
datediff(DAY,DateOfBirth,PV.VisitDate) between @MinDate and @MaxDate and Gender=''Male''
and
CONVERT(date,PV.VisitDate) between Convert(date, '''+CONVERT(NVARCHAR(MAX), @FromDate)+''')     and Convert(date,'''+ CONVERT(NVARCHAR(MAX),@Todate)+''')
and 
pv.DepartmentId=IIF(Convert(int,'+CONVERT(NVARCHAR(3),@departmentId)+')=0,PV.departmentId, Convert(int,'+CONVERT(NVARCHAR(3),@departmentId)+'))
Group By DepartmentName,Gender;
Insert Into @temp 
select 

    MD.DepartmentName,
    Count(PV.PatientVisitId) as VisitCount,
    @AgeGroup+''F'' as AgeGroup
from PAT_Patient    PT
    Inner join PAT_PatientVisits PV ON PT.PatientId=PV.PatientId
    INNER JOIN MST_Department MD On MD.DepartmentId=PV.DepartmentId
Where 
    datediff(DAY,DateOfBirth,PV.VisitDate) between @MinDate and @MaxDate and Gender=''Female''
    and
CONVERT(date,PV.VisitDate) between Convert(date, '''+CONVERT(NVARCHAR(MAX), @FromDate)+''') and Convert(date,'''+ CONVERT(NVARCHAR(MAX),@Todate)+''')
and 
pv.DepartmentId=IIF(Convert(int,'+CONVERT(NVARCHAR(3),@departmentId)+')=0,PV.departmentId, Convert(int,'+CONVERT(NVARCHAR(3),@departmentId)+'))
Group By DepartmentName,Gender;
Fetch next from DepartmentAgeReport into @AgeGroup,@MinDate,@MaxDate
END
close DepartmentAgeReport    
deallocate DepartmentAgeReport
select * from @temp
PIVOT
(
    sum (visitCount)
    for 
    AgeGroup in (' + @cols + N')
)  p '
EXEC sp_executesql @sqlQuery;
END