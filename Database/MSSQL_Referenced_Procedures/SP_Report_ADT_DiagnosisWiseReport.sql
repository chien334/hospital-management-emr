Create PROCEDURE [dbo].[SP_Report_ADT_DiagnosisWiseReport] 
	@FromDate Date=null ,
	@ToDate Date=null,
	@Diagnosis varchar(max) = null
AS
/*
FileName: [SP_Report_ADT_DiagnosisWiseReport]   '2019-09-29','2019-09-29', 'typhoid'
CreatedBy/date: Dinesh/2019-09-29
Description: to get the no of patient's count diagnosis wise
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Dinesh 2019-09-29					to get the no of patient's count diagnosis wise
*/
BEGIN
		If(@FromDate IS NOT NULL OR @ToDate IS NOT NULL or LEN(@FromDate)>=0 OR LEN(@ToDate)>=0 AND (@Diagnosis IS NOT NULL)
        OR (LEN(@Diagnosis) > 0 ))
	BEGIN 
			select convert(date,x.[Date]) as 'Date',x.PatientCode as 'PatientCode',x.PatientName as 'PatientName', x.PhoneNumber, x.Diagnosis
			
			 from (
select pt.FirstName +' '+ Isnull(pt.MiddleName,'') + ' '+pt.LastName as 'PatientName',discharge.Diagnosis as 'Diagnosis'
,pt.PatientCode,pt.PhoneNumber,discharge.CreatedOn as 'Date' from 
ADT_DischargeSummary discharge join PAT_PatientVisits visit on discharge.PatientVisitId=visit.PatientVisitId 
inner join PAT_Patient  pt on pt.PatientId=visit.PatientId
where discharge.Diagnosis LIKE '%' + ISNULL(@Diagnosis, '') + '%' and 
CONVERT(date, discharge.createdOn) BETWEEN @FromDate AND @ToDate
  )as x
  group by x.Diagnosis, x.PatientName,x. PatientCode,PhoneNumber,[Date]
  order by Diagnosis asc
	END	
END