-- =============================================
-- Author:		<Anish Bhattarai>
-- Create date: <18 August>
-- Description:	<Get all the Provisional Items List>
-- =============================================
/*
Change History
S.No.    UpdatedBy/Date					Remarks
1		Anjana/18/05/2021			Applied date filter 
2.		Bibek/5thJuly'23			Change it from InPatients Provisional Items list to Outpatient Only, 
									NOTE: Will rename the SP later
3.		Krishna/9thJuly'23			Rename the SP from SP_InPatient_Provisional_Items_List to SP_OutPatient_Provisional_Items_List
*/
CREATE PROCEDURE SP_Outpatient_Provisional_Items_List (
	@FromDate DATETIME = NULL,
    @ToDate DATETIME = NULL	
) 
AS
BEGIN
	SELECT pat.ShortName,pat.Age,pat.Gender,pat.DateOfBirth,pat.PatientCode,srv.IntegrationName,
	--dep.ReceiptNo,
	item.* FROM BIL_TXN_BillingTransactionItems item
	JOIN PAT_Patient pat on pat.PatientId=item.PatientId
	INNER JOIN BIL_MST_ServiceDepartment srv on srv.ServiceDepartmentId=item.ServiceDepartmentId
	 --JOIN BIL_TXN_Deposit dep on pat.PatientId=dep.PatientId
	WHERE (LOWER(item.VisitType)='outpatient') AND LOWER(BillStatus)='provisional' and Convert(Date, item.CreatedOn) between ISNULL(@FromDate, Convert(Date, GETDATE())) AND ISNULL(@ToDate, Convert(DATE, GETDATE()))
	ORDER BY item.CreatedOn desc
END