CREATE PROCEDURE [dbo].[SP_PHRM_TransferToStoreReport] 
	@FromDate datetime=null,
	@ToDate datetime=null
AS
 /*
FileName: [dbo].[SP_PHRM_TransferToStoreReport] '05/05/2020','05/05/2020'
CreatedBy/date:Shankar/05-01-2020
Description: To get report of stock details transfer to store from dispensary 
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1.
*/
 BEGIN
  IF ((@FromDate IS NOT NULL) and (@ToDate IS NOT NULL)) 
		BEGIN
			select CONVERT(date,stk.CreatedOn) as [Date],ItemName,BatchNo,Quantity,ExpiryDate,TotalAmount,StoreName,emp.FullName
			from PHRM_StoreStock as stk
			join EMP_Employee emp on stk.CreatedBy = emp.EmployeeId
			where CONVERT(date, stk.CreatedOn) BETWEEN ISNULL(@FromDate,GETDATE())  AND ISNULL(@ToDate,GETDATE())+1 AND TransactionType='Sent From Dispensary'
			
	   END
END