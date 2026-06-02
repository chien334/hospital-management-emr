CREATE PROCEDURE [dbo].[SP_BIL_GetItems_ForIPBillingReceipt] 
	 @PatientId INT
	,@BillTxnId INT = NULL
	,@BillStatus VARCHAR(50) = NULL
AS
/*
FileName: [SP_BIL_GetItems_ForIPBillingReceipt]
CreatedBy/date: sud/14Sept'18
Description: 
Remarks:  Need to handle provisional etc carefully, else number of items could be more.. 
Change History
S.No.    UpdatedBy/Date                        Remarks
1       sud/14Sept'18            Initial draft
2       sud/13Mar'19             Adding Salutation in DoctorName
3		Nagesh/04 June 2019  	 Getting correct bed quantity for estimated bill of adt patient
4		Nagesh/15 Aug 2019		Get quantity if manually added any bed charges item
5		Krishna,2Jun'22			changed ProviderId to PerformerId
6.		Rohit/24Apr'22			ItemCode and Service Department Name is fetched
7.		Krishna/4thJuly'23		Complete Rewrite of Stored Procedure, removing the grouping logic from here, will do from client side itself
*/
BEGIN
SELECT * FROM(
	SELECT 
	Convert(DATE, itm.CreatedOn) 'BillDate'
	,itm.ServiceDepartmentId,
	itm.ServiceDepartmentName
	,itm.ServiceItemId
	,itm.ItemName
	,emp.EmployeeId 'DoctorId'
	,emp.FullName 'DoctorName'
	,itm.Price
	,ISNULL(itm.Quantity,0) - ISNULL(retItms.RetQty,0) AS 'Quantity'
	,ISNULL(itm.SubTotal,0) - ISNULL(retItms.RetSubTotal,0) AS 'SubTotal'
	,ISNULL(itm.DiscountAmount,0) - ISNULL(retItms.RetDiscountAmount,0) AS 'DiscountAmount'
	,itm.Tax
	,ISNULL(itm.TotalAmount,0) - ISNULL(retItms.RetTotalAmount,0) AS 'TotalAmount'
	,servitm.ItemCode
	,servitm.ServiceCategoryId
	,servCat.ServiceCategoryCode
	,servCat.ServiceCategoryName
	,itm.IntegrationItemId
	,servDep.IntegrationName
FROM BIL_TXN_BillingTransactionItems itm
LEFT JOIN (select BillingTransactionItemId,SUM(ISNULL(RetSubTotal,0)) AS 'RetSubTotal', 
			SUM(ISNULL(RetTotalAmount,0)) AS 'RetTotalAmount', SUM(ISNULL(RetDiscountAmount,0)) AS 'RetDiscountAmount',
			SUM(ISNULL(RetQuantity,0)) AS 'RetQty'
			from BIL_TXN_InvoiceReturnItems group by BillingTransactionItemId) retItms 
			on itm.BillingTransactionItemId = retItms.BillingTransactionItemId
INNER JOIN BIL_MST_ServiceItem servitm on itm.ServiceItemId = servitm.ServiceItemId
INNER JOIN BIL_MST_ServiceDepartment servDep on itm.ServiceDepartmentId = servDep.ServiceDepartmentId
LEFT JOIN BIL_MST_ServiceCategory servCat on servitm.ServiceCategoryId = servCat.ServiceCategoryId
LEFT JOIN EMP_Employee emp ON itm.PerformerId = emp.EmployeeId
WHERE PatientId = @PatientId
AND ISNULL(itm.BillingTransactionId, 0) = ISNULL(@BillTxnId, ISNULL(itm.BillingTransactionId, 0))
AND itm.BillStatus = ISNULL(@BillStatus, itm.BillStatus)
)tbl where tbl.Quantity > 0
END