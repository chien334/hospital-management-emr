CREATE OR REPLACE FUNCTION sp_ins_pendingclaims(
    p_creditorganizationid INT
)
RETURNS TABLE (
    "ClaimSubmissionId" INT,
    "ClaimCode" VARCHAR,
    "HospitalNo" VARCHAR,
    "PatientName" VARCHAR,
    "PatientId" INT,
    "AgeSex" VARCHAR,
    "MemberNumber" VARCHAR,
    "SchemeName" VARCHAR,
    "TotalBillAmount" DECIMAL,
    "NonClaimableAmount" TIMESTAMP,
    "ClaimableAmount" DECIMAL,
    "ClaimedAmount" DECIMAL
) AS $$
BEGIN
    /*
    filename: sp_ins_pendingclaims
    description: this sp gives pending claims of specific creditorganziation (insurance)
    example exec sp_ins_pendingclaims 20
    
    change history:
    sn.						author/timestamp                   description
    1.						devn/12th march 23                initial draft.
    2.						sanjeev/25th-april'23			  Add ClaimedAmount in select
    
    */
    
    	RETURN QUERY SELECT 
    	     claim.ClaimSubmissionId
    		,claim.ClaimCode
    		,patient.PatientCode AS "HospitalNo"
    		,patient.ShortName AS "PatientName"
    		,patient.PatientId
    		,patient.Age || '/' || SUBSTRING(patient.Gender, 1, 1) AS "AgeSex"
    		,claim.MemberNumber
    		,scheme.SchemeName
    		,claim.TotalBillAmount
    		,claim.NonClaimableAmount
    		,claim.ClaimableAmount
    		,claim.ClaimedAmount
    	FROM INS_TXN_InsuranceClaim claim
    	JOIN PAT_Patient patient ON claim.PatientId = patient.PatientId
    	JOIN BIL_CFG_Scheme scheme ON scheme.SchemeId = claim.SchemeId
    	WHERE claim.CreditOrganizationId = p_creditorganizationid
    		  AND (claim.ClaimStatus = 'initiated' OR claim.ClaimStatus = 'in-review');
END;
$$ LANGUAGE plpgsql;