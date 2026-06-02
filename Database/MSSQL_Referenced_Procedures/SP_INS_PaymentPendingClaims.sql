-- =============================================
--Change History
/*SN.                Auther/DateTime                   Description
1                    DevN/14th March 23                 Initail Draft.
*/
-- exec SP_INS_PaymentPendingClaims 20
-- =============================================
CREATE PROCEDURE [dbo].[SP_INS_PaymentPendingClaims] @CreditOrganizationId INT
AS
BEGIN
	SELECT claim.ClaimSubmissionId
		,claim.ClaimCode
		,patient.PatientCode AS 'HospitalNo'
		,patient.ShortName AS 'PatientName'
		,patient.PatientId
		,patient.Age + '/' + SUBSTRING(patient.Gender, 1, 1) AS 'AgeSex'
		,claim.MemberNumber
		,claim.TotalBillAmount
		,claim.NonClaimableAmount
		,claim.ClaimableAmount
		,claim.ClaimedAmount
		,claim.ApprovedAmount
		,claim.RejectedAmount
		,submittedBy.FullName AS 'ClaimSubmittedBy'
		,claim.ClaimSubmittedOn
		,ISNULL(Payment.ReceivedAmount,0) AS 'TotalReceivedAmount'
		,ISNULL(Payment.ServiceCommissionAmount,0) AS 'ServiceCommissionAmount'
		,ISNULL(claim.ApprovedAmount,0) - ISNULL(Payment.ReceivedAmount,0) AS 'PendingAmount'
		,claim.CreditOrganizationId
	FROM INS_TXN_InsuranceClaim claim
	JOIN PAT_Patient patient ON claim.PatientId = patient.PatientId
	JOIN EMP_Employee submittedBy ON claim.ClaimSubmittedBy = submittedBy.EmployeeId
	JOIN BIL_CFG_Scheme scheme ON scheme.SchemeId = claim.SchemeId
	LEFT JOIN (
		SELECT SUM(ISNULL(ReceivedAmount, 0)) AS 'ReceivedAmount'
			,SUM(ISNULL(ServiceCommission, 0)) AS 'ServiceCommissionAmount'
			,ClaimSubmissionId
		FROM INS_TXN_ClaimPayment
		GROUP BY ClaimSubmissionId
		) AS Payment ON claim.ClaimSubmissionId = Payment.ClaimSubmissionId
	WHERE claim.CreditOrganizationId = @CreditOrganizationId
		AND claim.ClaimStatus = 'payment-pending'
		OR claim.ClaimStatus = 'partially-paid'
END