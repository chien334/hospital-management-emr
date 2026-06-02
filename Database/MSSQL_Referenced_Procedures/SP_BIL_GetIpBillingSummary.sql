CREATE PROCEDURE SP_BIL_GetIpBillingSummary
				@PatientId INT = null,
				@PatientVisitId INT = null,
				@BillStatus VARCHAR(20) = null
AS

/*
FileName: [SP_BIL_GetIpBillingSummary]
CreatedBy/date: Krishna/10thAug'23
Description: To get the summary of IpBilling 
			 
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Krishna/10thAug'23                     created the script
*/

BEGIN
	SELECT
	grp.GroupName,
	grp.SubTotal,
	grp.DiscountAmount,
	grp.TotalAmount
FROM (
SELECT 
	itms.ServiceDepartmentName AS 'GroupName', 
	CONVERT(DECIMAL(16,4),SUM(ISNULL(itms.SubTotal, 0))) AS 'SubTotal',
	CONVERT(DECIMAL(16,4),SUM(ISNULL(itms.DiscountAmount, 0))) AS 'DiscountAmount', 
	CONVERt(DECIMAL(16,4),SUM(ISNULL(itms.TotalAmount, 0))) AS 'TotalAmount' 
FROM 
		(SELECT ServiceDepartmentId, ServiceDepartmentName,BillingTransactionItemId,
			  SubTotal, DiscountAmount, TotalAmount FROM BIL_TXN_BillingTransactionItems 
		 WHERE PatientId = @PatientId AND PatientVisitId = @PatientVisitId AND BillStatus = @BillStatus) itms
		 INNER JOIN BIL_MST_ServiceDepartment servDep ON itms.ServiceDepartmentId = servDep.ServiceDepartmentId
		 GROUP BY itms.ServiceDepartmentId, itms.ServiceDepartmentName
)grp
END