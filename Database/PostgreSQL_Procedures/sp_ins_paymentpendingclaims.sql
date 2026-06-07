CREATE OR REPLACE FUNCTION sp_ins_paymentpendingclaims(
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
    "TotalBillAmount" DECIMAL,
    "NonClaimableAmount" TIMESTAMP,
    "ClaimableAmount" DECIMAL,
    "ClaimedAmount" DECIMAL,
    "ApprovedAmount" DECIMAL,
    "RejectedAmount" DECIMAL,
    "ClaimSubmittedBy" VARCHAR,
    "ClaimSubmittedOn" TIMESTAMP,
    "TotalReceivedAmount" DECIMAL,
    "ServiceCommissionAmount" TIMESTAMP,
    "PendingAmount" DECIMAL,
    "CreditOrganizationId" INT
) AS $$
BEGIN
    
    	RETURN QUERY SELECT claim.claimsubmissionid
    		,claim.claimcode
    		,patient.patientcode AS "HospitalNo"
    		,patient.shortname AS "PatientName"
    		,patient.patientid
    		,patient.age || '/' || substring(patient.gender, 1, 1) AS "AgeSex"
    		,claim.membernumber
    		,claim.totalbillamount
    		,claim.nonclaimableamount
    		,claim.claimableamount
    		,claim.claimedamount
    		,claim.approvedamount
    		,claim.rejectedamount
    		,submittedby.fullname AS "ClaimSubmittedBy"
    		,claim.claimsubmittedon
    		,coalesce(payment.receivedamount,0) AS "TotalReceivedAmount"
    		,coalesce(payment.servicecommissionamount,0) AS "ServiceCommissionAmount"
    		,coalesce(claim.approvedamount,0) - coalesce(payment.receivedamount,0) AS "PendingAmount"
    		,claim.creditorganizationid
    	from ins_txn_insuranceclaim claim
    	join pat_patient patient on claim.patientid = patient.patientid
    	join emp_employee submittedby on claim.claimsubmittedby = submittedby.employeeid
    	join bil_cfg_scheme scheme on scheme.schemeid = claim.schemeid
    	left join (
    		select sum(coalesce(receivedamount, 0)) as "receivedamount"
    			,sum(coalesce(servicecommission, 0)) AS "ServiceCommissionAmount"
    			,claimsubmissionid
    		from ins_txn_claimpayment
    		group by claimsubmissionid
    		) as payment on claim.claimsubmissionid = payment.claimsubmissionid
    	where claim.creditorganizationid = p_creditorganizationid
    		and claim.claimstatus = 'payment-pending'
    		or claim.claimstatus = 'partially-paid';
END;
$$ LANGUAGE plpgsql;