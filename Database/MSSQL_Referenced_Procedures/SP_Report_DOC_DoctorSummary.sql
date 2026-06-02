--Altering SP_Report_DOC_DoctorSummary SP
--changed ProviderId to PerformerId  
CREATE PROCEDURE [dbo].[SP_Report_DOC_DoctorSummary]  
 @FromDate DateTime=null,  
 @ToDate DateTime=null,  
 @PerformerId int=null  
 AS  
/*  
 FileName: SP_Report_DOC_DoctorSummary  
 Created: 05April'18 <Ashim>  
 Description: To Get Doctor's Summary count from different activities.  
 Remarks:   
 Change History  
 S.No.    Date/User              Change          Remarks  
 1.      05April'18               created     
 2.		 Krishna,9thJun'22		 alter			changed ProviderId to PerformerId
*/  
BEGIN  
  
  
  
  IF (@FromDate IS NOT NULL) OR (@ToDate IS NOT NULL)  
 BEGIN  
  
--start: get data from BIL_TXN_BillingTransactionItems and PAT_PatientVisits and store into TempTable---  
CREATE TABLE #TempTable(TxnDate datetime, ItemName varchar(MAX), Quantity int,PerformerId int)  
Insert #TempTable (TxnDate,ItemName,Quantity,PerformerId)  
(SELECT CreatedOn as 'TxnDate',  
 ServiceDepartmentName as 'ItemName',  
 --this is Active Quantity--  
 Quantity-ISNULL(ReturnQuantity,0) 'Quantity',  
 PerformerId   
from BIL_TXN_BillingTransactionItems  
where PerformerId is not null  
and BillStatus !='cancel'  
and Quantity-ISNULL(ReturnQuantity,0) != 0)  
  
Insert #TempTable (TxnDate,ItemName,Quantity,PerformerId)  
(select VisitDate as 'TxnDate', AppointmentType as 'ItemName', 1 as 'Quantity', PerformerId  
from PAT_PatientVisits)  
--end: get data from BIL_TXN_BillingTransactionItems and PAT_PatientVisits and store into TempTable---  
  
  
 SELECT Convert(date,t.TxnDate) 'Date'  
 ,SUM(CASE WHEN t.ItemName='USG' THEN t.Quantity ELSE 0 END) AS 'USG'  
 ,SUM(CASE WHEN t.ItemName='Ortho Procedures' THEN t.Quantity ELSE 0 END) AS 'OrthoProcedures'  
 ,SUM(CASE WHEN t.ItemName='CT Scan' THEN t.Quantity ELSE 0 END) AS 'CT'  
 ,SUM(CASE WHEN t.ItemName='New' THEN t.Quantity ELSE 0 END) AS 'OPD'  
 ,SUM(CASE WHEN t.ItemName='referral' THEN t.Quantity ELSE 0 END) AS 'Referral'  
 ,SUM(CASE WHEN t.ItemName='followup' THEN t.Quantity ELSE 0 END) AS 'FollowUp'  
 ,SUM(CASE WHEN t.ItemName='General Surgery Charges' THEN t.Quantity ELSE 0 END) AS 'GeneralSurgery'  
 ,SUM(CASE WHEN t.ItemName='OBS/GYN Surgery' THEN t.Quantity ELSE 0 END) AS 'GynSurgery'  
 ,SUM(CASE WHEN t.ItemName='ENT Operation' THEN t.Quantity ELSE 0 END) AS 'ENT'  
 ,SUM(CASE WHEN t.ItemName='Dental' THEN t.Quantity ELSE 0 END) AS 'Dental'  
 ,SUM(CASE WHEN t.ItemName='OT' THEN t.Quantity ELSE 0 END) AS 'OT'  
 FROM #TempTable t  
 WHERE  t.TxnDate between  @FromDate and @ToDate+1   
  AND t.PerformerId =@PerformerId  
     
 GROUP BY Convert(date,t.TxnDate)  
 ORDER BY DATE  
 DROP TABLE #TempTable  
  End--end of IF  
End--end of SP