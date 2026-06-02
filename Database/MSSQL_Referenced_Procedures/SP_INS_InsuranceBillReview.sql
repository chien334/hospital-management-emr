CREATE PROCEDURE [dbo].[SP_INS_InsuranceBillReview]
	 @FromDate DATE
	,@ToDate DATE
	,@CreditOrganizationId INT
AS
-- =============================================
--Change History
/*SN.                Auther/DateTime                   Description
1                    DevN/9th March 23                 Initail Draft.
2					 Sanjeev/9thMay 23				   Change Colummn 'NetCreditAmount' to 'NetReceivableAmount'
*/
-- exec SP_INS_InsuranceBillReview '2023-01-01','2023-02-11',16
-- =============================================
BEGIN
	SELECT *
	FROM (
		SELECT creditBill.BillingCreditBillStatusId AS 'CreditStatusId'
			,creditBill.ClaimCode
			,creditBill.BillingTransactionId AS 'InvoiceRefId'
			,creditBill.FiscalYearId
			,patient.PatientCode AS 'HospitalNo'
			,patient.ShortName AS 'PatientName'
			,patient.PatientId
			,patient.Age + '/' + SUBSTRING(patient.Gender, 1, 1) AS 'AgeSex'
			,creditBill.MemberNo
			,creditBill.InvoiceNoFormatted AS 'InvoiceNo'
			,creditBill.InvoiceDate
			,scheme.SchemeName
			,scheme.SchemeId
			,ISNULL(creditBill.SalesTotalBillAmount - creditBill.ReturnTotalBillAmount,0) AS 'TotalAmount'
			,creditBill.NetReceivableAmount AS 'NetCreditAmount'
			,creditBill.NonClaimableAmount AS 'NonClaimableAmount'
			,creditBill.SettlementStatus AS 'ClaimStatus'
			,visit.VisitType
			,admission.AdmissionDate
			,admission.DischargeDate
			,'billing' AS 'CreditModule'
			,creditBill.IsClaimable
			,creditBill.CreditOrganizationId
		FROM BIL_TXN_CreditBillStatus creditBill
		JOIN PAT_Patient patient ON creditBill.PatientId = patient.PatientId
		JOIN PAT_PatientVisits visit ON creditBill.PatientVisitId = visit.PatientVisitId
		JOIN BIL_CFG_Scheme scheme ON creditBill.SchemeId = scheme.SchemeId
		LEFT JOIN ADT_PatientAdmission admission ON creditBill.PatientVisitId = admission.PatientVisitId
		WHERE creditBill.InvoiceDate >= @FromDate
			AND creditBill.InvoiceDate <= @ToDate
			AND creditBill.CreditOrganizationId = @CreditOrganizationId
			AND creditBill.SettlementStatus = 'pending'
		
		UNION ALL
		
		SELECT creditBill.PhrmCreditBillStatusId AS 'CreditStatusId'
			,creditBill.ClaimCode
			,creditBill.InvoiceId AS 'InvoiceRefId'
			,creditBill.FiscalYearId
			,patient.PatientCode AS 'HospitalNo'
			,patient.ShortName AS 'PatientName'
			,patient.PatientId
			,patient.Age + '/' + SUBSTRING(patient.Gender, 1, 1) AS 'AgeSex'
			,creditBill.MemberNo
			,creditBill.InvoiceNoFormatted AS 'InvoiceNo'
			,creditBill.InvoiceDate
			,scheme.SchemeName
			,scheme.SchemeId
			,ISNULL(creditBill.SalesTotalBillAmount - creditBill.ReturnTotalBillAmount,0) AS 'TotalAmount'
			,creditBill.NetReceivableAmount AS 'NetCreditAmount'
			,creditBill.NonClaimableAmount AS 'NonClaimableAmount'
			,creditBill.SettlementStatus AS 'ClaimStatus'
			,visit.VisitType
			,admission.AdmissionDate
			,admission.DischargeDate
			,'pharmacy' AS 'CreditModule'
			,creditBill.IsClaimable
			,creditBill.CreditOrganizationId
		FROM PHRM_TXN_CreditBillStatus creditBill
		JOIN PAT_Patient patient ON creditBill.PatientId = patient.PatientId
		JOIN PAT_PatientVisits visit ON creditBill.PatientVisitId = visit.PatientVisitId
		JOIN BIL_CFG_Scheme scheme ON creditBill.SchemeId = scheme.SchemeId
		LEFT JOIN ADT_PatientAdmission admission ON creditBill.PatientVisitId = admission.PatientVisitId
		WHERE creditBill.InvoiceDate >= @FromDate
			AND creditBill.InvoiceDate <= @ToDate
			AND creditBill.CreditOrganizationId = @CreditOrganizationId
			AND creditBill.SettlementStatus = 'pending'
		) result
	ORDER BY result.PatientId,result.InvoiceDate DESC
END