CREATE PROCEDURE [dbo].[SP_BIL_GetPatientPastBills]  --- SP_BIL_GetPatientPastBills 77235, 15
		
		@PatientId INT=null,
		@maxPastDays INT=null
AS
/*
FileName: exec SP_BIL_GetPatientPastBills
CreatedBy/date: Sud/Anish/2019-06-19
Description: Get patient's Billing Items of Last N days, Exclude Cancelled Items. 
Used in Billing Transaction page (for Checkbox)

Change History
S.No.    UpdatedBy/Date                        Remarks
1.      Sud/Anish/19June'19                     Created.
2.      pratik/Sud: 17 April'20                  Added ItemId and ServiceDepartmentId in select, 
                                               excluded returned items, correction in username(now taking from emp.FullName 
3.      Dev Narayan /1 Oct'21                   Alter procedure so that it will not show the returned bills.
4.		Bibek/Krishna,14thMay'23				Add ServiceItemId in a select query
*/
BEGIN

IF( @maxPastDays IS NULL)
   SET @maxPastDays=7 -- we're taking past 7 days entry for now..

  SELECT 
	itm.CreatedOn,
	txn.InvoiceCode + COnvert(varchar(20), txn.InvoiceNo) 'InvoiceNumber',
	itm.ItemId,
	itm.ServiceDepartmentId,
    itm.ServiceDepartmentName,
	itm.ItemName,
	itm.TotalAmount,
	itm.BillStatus,
	emp.FirstName 'UserFirstName',
	emp.FullName 'User',
	itm.ServiceItemId
  FROM BIL_TXN_BillingTransactionItems itm 
	left join BIL_TXN_BillingTransaction txn
    ON itm.BillingTransactionId=txn.BillingTransactionId
    Join EMP_Employee emp 
    ON itm.CreatedBy=emp.EmployeeId
   WHERE  itm.PatientId=@PatientId
	and itm.BillStatus !='cancel'
	and itm.Quantity!=ISNULL((select sum(RetQuantity) from BIL_TXN_InvoiceReturnItems where BillingTransactionItemId = itm.BillingTransactionItemId),0)
	 and  DATEDIFF(DAY,itm.CreatedOn,getdate())  <= @maxPastDays
  Order by itm.CreatedOn DESC
END -- end of SP