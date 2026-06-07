CREATE OR REPLACE FUNCTION sp_ins_insurancebillreview(
    p_fromdate DATE,
    p_todate DATE,
    p_creditorganizationid INT
)
RETURNS TABLE (
    "CreditStatusId" INT,
    "ClaimCode" VARCHAR,
    "InvoiceRefId" INT,
    "FiscalYearId" INT,
    "HospitalNo" VARCHAR,
    "PatientName" VARCHAR,
    "PatientId" INT,
    "AgeSex" VARCHAR,
    "MemberNo" VARCHAR,
    "InvoiceNo" VARCHAR,
    "InvoiceDate" TIMESTAMP,
    "SchemeName" VARCHAR,
    "SchemeId" INT,
    "TotalAmount" DECIMAL,
    "NetCreditAmount" DECIMAL,
    "NonClaimableAmount" TIMESTAMP,
    "ClaimStatus" VARCHAR,
    "VisitType" VARCHAR,
    "AdmissionDate" TIMESTAMP,
    "DischargeDate" TIMESTAMP,
    "CreditModule" VARCHAR,
    "IsClaimable" BOOLEAN,
    "CreditOrganizationId" INT
) AS $$
BEGIN
    -- =============================================
    --change history
    /*sn.                auther/timestamp                   description
    1                    devn/9th march 23                 initail draft.
    2					 sanjeev/9thmay 23				   change colummn 'NetCreditAmount' to 'NetReceivableAmount'
    */
    -- exec sp_ins_insurancebillreview '2023-01-01','2023-02-11',16
    -- =============================================
    
    	RETURN QUERY SELECT *
    	from (
    		select creditbill.billingcreditbillstatusid AS "CreditStatusId"
    			,creditbill.claimcode
    			,creditbill.billingtransactionid AS "InvoiceRefId"
    			,creditbill.fiscalyearid
    			,patient.patientcode AS "HospitalNo"
    			,patient.shortname AS "PatientName"
    			,patient.patientid
    			,patient.age || '/' || substring(patient.gender, 1, 1) AS "AgeSex"
    			,creditbill.memberno
    			,creditbill.invoicenoformatted AS "InvoiceNo"
    			,creditbill.invoicedate
    			,scheme.schemename
    			,scheme.schemeid
    			,coalesce(creditbill.salestotalbillamount - creditbill.returntotalbillamount,0) AS "TotalAmount"
    			,creditbill.netreceivableamount AS "NetCreditAmount"
    			,creditbill.nonclaimableamount AS "NonClaimableAmount"
    			,creditbill.settlementstatus AS "ClaimStatus"
    			,visit.visittype
    			,admission.admissiondate
    			,admission.dischargedate
    			,'billing' AS "CreditModule"
    			,creditbill.isclaimable
    			,creditbill.creditorganizationid
    		from bil_txn_creditbillstatus creditbill
    		join pat_patient patient on creditbill.patientid = patient.patientid
    		join pat_patientvisits visit on creditbill.patientvisitid = visit.patientvisitid
    		join bil_cfg_scheme scheme on creditbill.schemeid = scheme.schemeid
    		left join adt_patientadmission admission on creditbill.patientvisitid = admission.patientvisitid
    		where creditbill.invoicedate >= p_fromdate
    			and creditbill.invoicedate <= p_todate
    			and creditbill.creditorganizationid = p_creditorganizationid
    			and creditbill.settlementstatus = 'pending'
    		
    		union all
    		
    		select creditbill.phrmcreditbillstatusid AS "CreditStatusId"
    			,creditbill.claimcode
    			,creditbill.invoiceid AS "InvoiceRefId"
    			,creditbill.fiscalyearid
    			,patient.patientcode AS "HospitalNo"
    			,patient.shortname AS "PatientName"
    			,patient.patientid
    			,patient.age || '/' || substring(patient.gender, 1, 1) AS "AgeSex"
    			,creditbill.memberno
    			,creditbill.invoicenoformatted AS "InvoiceNo"
    			,creditbill.invoicedate
    			,scheme.schemename
    			,scheme.schemeid
    			,coalesce(creditbill.salestotalbillamount - creditbill.returntotalbillamount,0) AS "TotalAmount"
    			,creditbill.netreceivableamount AS "NetCreditAmount"
    			,creditbill.nonclaimableamount AS "NonClaimableAmount"
    			,creditbill.settlementstatus AS "ClaimStatus"
    			,visit.visittype
    			,admission.admissiondate
    			,admission.dischargedate
    			,'pharmacy' AS "CreditModule"
    			,creditbill.isclaimable
    			,creditbill.creditorganizationid
    		from phrm_txn_creditbillstatus creditbill
    		join pat_patient patient on creditbill.patientid = patient.patientid
    		join pat_patientvisits visit on creditbill.patientvisitid = visit.patientvisitid
    		join bil_cfg_scheme scheme on creditbill.schemeid = scheme.schemeid
    		left join adt_patientadmission admission on creditbill.patientvisitid = admission.patientvisitid
    		where creditbill.invoicedate >= p_fromdate
    			and creditbill.invoicedate <= p_todate
    			and creditbill.creditorganizationid = p_creditorganizationid
    			and creditbill.settlementstatus = 'pending'
    		) result
    	order by result.patientid,result.invoicedate desc;
END;
$$ LANGUAGE plpgsql;