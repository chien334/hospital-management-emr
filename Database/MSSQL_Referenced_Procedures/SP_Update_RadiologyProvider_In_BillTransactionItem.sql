--Altering SP_Update_RadiologyProvider_In_BillTransactionItem SP
--changed ProviderId to PerformerId and ProviderName to PerformerName
-- =============================================  
-- Author:  <Anish>  
-- Create date: <18 Sept>  
-- Description: <Update Provider detail for Radiology Item in BillTransactionItem Table>  
--Modified: Krishna,9thJun'22 -- changed ProviderId to PerformerId and ProviderName to PerformerName
--Modifeid: Dev Narayan, 23thJun'22 --Changed sp to update PrescriberId in BillingtransactionItem table
-- =============================================  
CREATE PROCEDURE [dbo].[SP_Update_RadiologyProvider_In_BillTransactionItem] (  
 @RequisitionId INT,  
 @PrescriberId INT NULL,  
 @PrescriberName varchar(100),
 @PerformerId INT NULL,
 @PerformerName varchar(100)
)    
AS  
BEGIN  
 Update BIL_TXN_BillingTransactionItems set PrescriberId=@PrescriberId,
 PerformerId = @PerformerId,
 PerformerName = @PerformerName where BillingTransactionItemId =(  
 Select item.BillingTransactionItemId from BIL_TXN_BillingTransactionItems item  
 Join BIL_MST_ServiceDepartment srvDept on srvDept.ServiceDepartmentId=item.ServiceDepartmentId  
 where LOWER(srvDept.IntegrationName)='radiology' and item.RequisitionId=@RequisitionId  
 )    
END  
--END : Dev , 23th June'22, Change SP for PPR