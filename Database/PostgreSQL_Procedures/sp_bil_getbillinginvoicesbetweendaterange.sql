CREATE OR REPLACE FUNCTION sp_bil_getbillinginvoicesbetweendaterange(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL
)
RETURNS TABLE (
    "PatientId" INT,
    "PatientCode" VARCHAR,
    "ShortName" VARCHAR,
    "Gender" VARCHAR,
    "DateOfBirth" TIMESTAMP,
    "PaidDate" INT,
    "TransactionDate" TIMESTAMP,
    "TotalAmount" DECIMAL,
    "BillingTransactionId" INT,
    "InvoiceNumber" VARCHAR,
    "InvoiceCode" VARCHAR,
    "FiscalYear" VARCHAR,
    "FiscalYearId" INT,
    "InvoiceNumFormatted" VARCHAR,
    "PhoneNumber" TIMESTAMP,
    "IsInsuranceBilling" BOOLEAN,
    "OrganizationId" INT,
    "OrganizationName" TIMESTAMP,
    "PaymentMode" VARCHAR
) AS $$
BEGIN
    /*
    filename: sp_bil_getbillinginvoicesbetweendaterange
    createdby/date: sud/29mar'21
    Description:Get Invoice Details for Billing-> Duplicate Print 
    
    Change History
    S.No.    UpdatedBy/Date                        Remarks
    1.      Sud/29Mar'21                         initial draft
    */
    
    p_fromdate := coalesce(p_fromdate,(current_timestamp)::date);
    p_todate := coalesce(p_todate,(current_timestamp)::date);
    
    RETURN QUERY SELECT  pat.patientid, 
    		pat.patientcode, 
    		pat.shortname, 
    		pat.gender, 
    		pat.dateofbirth,
    		txn.paiddate AS "PaidDate",
    		txn.createdon AS "TransactionDate",
    		txn.totalamount,
    		txn.billingtransactionid,
    		txn.invoiceno AS "InvoiceNumber",
    		txn.invoicecode,
    		fy.fiscalyearformatted AS "FiscalYear",
    		txn.fiscalyearid,
    		txn.invoicecode||(txn.invoiceno)::varchar AS "InvoiceNumFormatted",
    		pat.phonenumber,
    		txn.isinsurancebilling,
    		txn.organizationid,
    		crorg.organizationname,
    		txn.paymentmode
    
    from bil_txn_billingtransaction txn inner join pat_patient pat
         on txn.patientid=pat.patientid
    inner join bil_cfg_fiscalyears fy
         on txn.fiscalyearid = fy.fiscalyearid
    left join bil_mst_credit_organization crorg 
        on txn.organizationid = crorg.organizationid
    
    where 
    (txn.createdon)::date between p_fromdate and p_todate 
    order by txn.fiscalyearid desc, txn.invoiceno desc;
END;
$$ LANGUAGE plpgsql;