--Altering SP_Report_Scheduling_DoctorWisePatientReport SP
--changed ProviderId to PerformerId and ProviderName to PerformerName
CREATE PROCEDURE [dbo].[SP_Report_Scheduling_DoctorWisePatientReport]   
 @FromDate DateTime=null,  
 @ToDate DateTime=null,  
 @PerformerName NVARCHAR(max)=null  
AS  
/*  
FileName: SP_Report_Scheduling_DoctorWisePatientReport  
CreatedBy/date: umed/2017-06-02  
Description: to get count of appointments per doctor between given dates.  
Remarks:    default getdate() for both fromdate and todate.  
Change History  
S.No.    UpdatedBy/Date                        Remarks  
1.       umed/2017-06-02                       created  
2.       Umed/2017-06-08                     Modify the script   
                                           Rename the Script, Formatting and some minor changes  
3.  Rusha/2021-06-30       Show middlename of doctor  
4.	Krishna,9thJun'22		changed ProviderId to PerformerId and ProviderName to PerformerName
*/  
BEGIN  
 IF (@FromDate IS NOT NULL) OR (@ToDate IS NOT NULL) OR (@PerformerName IS NOT NULL) OR (LEN(@PerformerName) > 0)  
 BEGIN  
  DECLARE @DynamicPivotQuery AS NVARCHAR(MAX),  
           @PivotColumnNames AS NVARCHAR(MAX),  
           @PivotSelectColumnNames AS NVARCHAR(MAX)  
      
   SELECT @PivotColumnNames= ISNULL(@PivotColumnNames + ',','')  
   + QUOTENAME(PerformerName)  
   FROM (   
      SELECT DISTINCT E.Salutation+' '+E.FirstName+' '+ ISNULL(E.MiddleName,'')+' '+E.LastName AS PerformerName   
      FROM            EMP_Employee E   
      INNER JOIN     PAT_PatientVisits p   
      ON            p.PerformerId=E.EmployeeId  
      WHERE  p.VisitDate   
      BETWEEN ISNULL(@FromDate,GETDATE()) AND ISNULL(@ToDate,GETDATE())+1  
      AND p.PerformerId like '%'+ ISNULL(@PerformerName,'') + '%'  
     )   AS dep  
       
    --SELECT 'AppointmentDate'+ISNULL(','+@PivotColumnNames,'') as ColumnName  
  
    SELECT 'Appointment Date'+ISNULL(','+REPLACE(REPLACE(@PivotColumnNames,'[',''),']',''),'') as ColumnName  
  
   SET @DynamicPivotQuery = N'SELECT [Appointment Date], ' + @PivotColumnNames + '  
     FROM (  
        SELECT CONVERT(date, a.VisitDate) AS [Appointment Date], E.Salutation+'' ''+E.FirstName+'' ''+ISNULL(E.MiddleName,'''')  
        +'' ''+E.LastName AS PerformerName,   
         COUNT(a.PerformerId) AS TotalAppointment  
        FROM PAT_PatientVisits  a INNER JOIN EMP_Employee E   
        ON  a.PerformerId=E.EmployeeId   
        WHERE a.VisitDate  
        BETWEEN CONVERT(Datetime,'''+ Convert(varchar(20),ISNULL(@FromDate,GETDATE()))  + ''')   
        and CONVERT(DATETIME,'''+Convert(varchar(20),ISNULL(@ToDate,GETDATE()))+''')+1     
        And PerformerName like ''%'+ ISNULL(@PerformerName,'') + '%''   
        GROUP BY E.Salutation+'' ''+E.FirstName+'' ''+ISNULL(E.MiddleName,'''')+'' ''+E.LastName, convert(date, a.VisitDate)  
      ) A  
     PIVOT(sum(TotalAppointment) for PerformerName in (' + @PivotColumnNames + ')) as pvt';  
  
  
   EXEC SP_executesql @DynamicPivotQuery  
  
 END  
END