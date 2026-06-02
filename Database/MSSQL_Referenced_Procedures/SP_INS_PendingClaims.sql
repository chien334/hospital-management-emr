CREATE PROCEDURE [dbo].[SP_INS_PendingClaims]
	@CreditOrganizationId INT
AS
/*
FileName: SP_INS_PendingClaims
Description: This SP gives Pending Claims of specific CreditOrganziation (Insurance)
Example exec SP_INS_PendingClaims 20

Change History:
SN.						Author/DateTime                   Description
1.						DevN/12th March 23                Initial Draft.
2.						Sanjeev/25th-April'23			  Add ClaimedAmount in select

*/
BEGIN
	SELECT 
	     claim.ClaimSubmissionId
		,claim.ClaimCode
		,patient.PatientCode AS 'HospitalNo'
		,patient.ShortName AS 'PatientName'
		,patient.PatientId
		,patient.Age + '/' + SUBSTRING(patient.Gender, 1, 1) AS 'AgeSex'
		,claim.MemberNumber
		,scheme.SchemeName
		,claim.TotalBillAmount
		,claim.NonClaimableAmount
		,claim.ClaimableAmount
		,claim.ClaimedAmount
	FROM INS_TXN_InsuranceClaim claim
	JOIN PAT_Patient patient ON claim.PatientId = patient.PatientId
	JOIN BIL_CFG_Scheme scheme ON scheme.SchemeId = claim.SchemeId
	WHERE claim.CreditOrganizationId = @CreditOrganizationId
		  AND (claim.ClaimStatus = 'initiated' OR claim.ClaimStatus = 'in-review')
END