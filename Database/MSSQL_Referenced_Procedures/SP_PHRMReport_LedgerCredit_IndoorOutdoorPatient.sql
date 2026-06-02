CREATE PROCEDURE [dbo].[SP_PHRMReport_LedgerCredit_IndoorOutdoorPatient] 
		@FromDate datetime=null,
		@ToDate datetime=null,
        @IsInOutPat bit
AS
/*
FileName: [SP_PHRMReport_LedgerCredit_IndoorOutdoorPatient]
CreatedBy/date: Umed/2018-02-21
Description: To get Patient Sale Credit Details Based on Patient Type
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Umed/2018-02-21	                 created the script
                                        i.e. To get Patient Sale Credit Details Based on Patient Type
2		Rusha/2019-05-03				Recreated the script to get Patient Sale Credit Details Based on Patient Type
3       Shankar/2020-06-01				Added organization name and remark
*/
BEGIN
	IF (@FromDate IS NOT NULL AND @ToDate IS NOT NULL AND @IsInOutPat=1)
			BEGIN
				SELECT CONVERT(date,inv.CreateOn) AS [Date],inv.InvoicePrintId AS InvoiceNum,pat.PatientCode, ISNULL(cr.OrganizationName,'N/A') as 'OrganizationName', inv.Remark,
				CONCAT_WS(' ',pat.FirstName,pat.MiddleName,pat.LastName) AS PatientName,pat.Address,inv.PaidAmount,inv.VisitType 
				FROM PHRM_TXN_Invoice AS inv
				LEFT JOIN PHRM_MST_Credit_Organization AS cr ON inv.OrganizationId = cr.OrganizationId
				JOIN PAT_Patient AS pat ON pat.PatientId = inv.PatientId
				WHERE inv.VisitType='outpatient' AND  inv.PaymentMode='credit' and CONVERT(date, inv.CreateOn) BETWEEN ISNULL(@FromDate,GETDATE())  AND ISNULL(@ToDate,GETDATE())+1
				GROUP BY CONVERT(date,inv.CreateOn),pat.FirstName,pat.MiddleName,pat.LastName,pat.PatientCode,inv.PaidAmount,inv.VisitType, inv.InvoicePrintId,pat.Address, OrganizationName, inv.Remark
			END
			ELSE IF (@IsInOutPat=0)
			BEGIN
				select CONVERT(date,inv.CreateOn) AS [Date],inv.InvoicePrintId AS InvoiceNum,pat.PatientCode, ISNULL(cr.OrganizationName,'N/A') as 'OrganizationName', inv.Remark,
				CONCAT_WS(' ',pat.FirstName,pat.MiddleName,pat.LastName) as PatientName,pat.Address,inv.PaidAmount,inv.VisitType 
				from PHRM_TXN_Invoice AS inv
				LEFT JOIN PHRM_MST_Credit_Organization AS cr ON inv.OrganizationId = cr.OrganizationId
				join PAT_Patient AS pat ON pat.PatientId = inv.PatientId
				where inv.VisitType='inpatient' AND  inv.PaymentMode='credit'and CONVERT(date,inv.CreateOn) BETWEEN ISNULL(@FromDate,GETDATE())  AND ISNULL(@ToDate,GETDATE())+1
				group by CONVERT(date,inv.CreateOn),pat.FirstName,pat.MiddleName,pat.LastName,pat.PatientCode,inv.PaidAmount,inv.VisitType, inv.InvoicePrintId,pat.Address, OrganizationName, inv.Remark
			END
END