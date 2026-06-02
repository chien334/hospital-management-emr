CREATE PROCEDURE [dbo].[SP_PHRMReport_DrugCategoryWiseReport] 
	@FromDate DateTime=null,
	@ToDate DateTime=null,
	@Category nvarchar(100)=null

AS
/*
FileName: [SP_PHRMReport_DrugCategoryWiseReport]
CreatedBy/date: Rusha/2019-05-12
Description: .
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1        Rusha/2019-05-12                     created of the script for displaying report according to drug category
2.		 Naveed/2019-12-13				      updated script for exclude zero quantity Items from Report
*/

BEGIN
  IF ((@FromDate IS NOT NULL) and (@ToDate IS NOT NULL) and (@Category IS NOT NULL))
	BEGIN
		SELECT CONVERT(DATE,invitm.CreatedOn) AS [Date],cat.CategoryName,invitm.ItemName, CONCAT_WS(' ',pat.FirstName,pat.MiddleName,pat.LastName) AS PatientName,
		--CONCAT_WS(' ',emp.FirstName,emp.MiddleName,emp.LastName) AS ProviderName,		
		invitm.BatchNo,invitm.Quantity,invitm.Price,invitm.TotalAmount 
		FROM PHRM_TXN_InvoiceItems AS invitm
		join PHRM_TXN_Invoice AS inv ON inv.PatientId = invitm.PatientId
		--join EMP_Employee AS emp ON inv.ProviderId = emp.EmployeeId
		join PHRM_MST_Item AS itm ON invitm.ItemId = itm.ItemId
		join PHRM_MST_Generic AS gen ON itm.GenericId = gen.GenericId
		join PHRM_MST_Category AS cat ON gen.CategoryId = cat.CategoryId
		join PAT_Patient AS pat ON invitm.PatientId = pat.PatientId
		WHERE CONVERT(DATE,invitm.CreatedOn) BETWEEN ISNULL(@FromDate,GETDATE())  AND ISNULL(@ToDate,GETDATE())+1 and cat.CategoryName = @Category AND invitm.Quantity>0
	END
END