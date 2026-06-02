--Altering SP_VISIT_SetNGetQueueNo SP
--changed ProviderId to PerformerId
CREATE PROCEDURE [dbo].[SP_VISIT_SetNGetQueueNo]  
  @VisitId int  
AS  
/*  
 File: SP_VISIT_SetNGetQueueNo -- EXEC SP_VISIT_SetNGetQueueNo 4  
 Description:   
    * To set the QueueNumber for current visit based on Queuelevel parameter   
 * there are 3 available options: department, doctor, hospital (default)  
  
Change History:  
S.No  Author/Date                Remarks  
1.    Sud/Pratik/5Mar'20         Initial Draft  
2.   Anish/Anjana/26Feb'21  Handle case of registration of ER patient before outpatient  
3.    Prem					Queue For the emergency   
4.	 Krishna,9thJun			changed ProviderId to PerformerId
*/  
BEGIN  
   
--Read and set QueueLevel value from parameter  
Declare @QueueLevel varchar(20)=(Select TOP 1 ParameterValue from CORE_CFG_Parameters where ParameterGroupName='Appointment' and ParameterName='QueueLevel')  
  
Declare @DoctorId INT, @DepartmentID INT, @VisitDate DATE  
Declare @LatestQuNum INT=0  
  
--Assign Values of DoctorId, DepartemntId, VisitDate for current visit.  
SELECT @DoctorId=PerformerId, @DepartmentID=DepartmentId , @VisitDate= COnvert(Date,VisitDate)  
from PAT_PatientVisits WHERE PatientVisitId=@VisitId  
  
--case1: if departmentlevel then take max that department for that day of visit  
IF(@QueueLevel='department')  
BEGIN  
   SELECT @LatestQuNum = ISNULL(MAX(ISNULL(QueueNo,0)),0)  
   FROM PAT_PatientVisits  
   WHERE (VisitType='outpatient' OR VisitType='emergency') AND DepartmentId=@DepartmentID   
     AND COnvert(Date,VisitDate)= @VisitDate   
END  
--case2: if doctorlevel then take max that doctor for that day of visit  
ELSE IF (@QueueLevel='doctor')  
BEGIN  
   SELECT @LatestQuNum = ISNULL(MAX(ISNULL(QueueNo,0)),0)  
   FROM PAT_PatientVisits  
   WHERE (VisitType='outpatient' OR VisitType='emergency') AND PerformerId=@DoctorId   
     AND COnvert(Date,VisitDate)= @VisitDate   
END  
ELSE--case3: by default it'll be hospital level, in this case take max of that day's visit  
BEGIN  
   SELECT @LatestQuNum = ISNULL(MAX(ISNULL(QueueNo,0)),0)  
   FROM PAT_PatientVisits  
   WHERE (VisitType='outpatient' OR VisitType='emergency') AND COnvert(Date,VisitDate)= @VisitDate   
END  
  
--Update the queue numebr of given visit and return the same to the caller---  
SET @LatestQuNum=@LatestQuNum+1  
UPDATE PAT_PatientVisits  
SET QueueNo=@LatestQuNum  
WHERE PatientVisitId=@VisitId  
SELECT @LatestQuNum AS 'QueueNo'  
  
END