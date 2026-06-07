CREATE OR REPLACE FUNCTION sp_bil_getcreditnotelistbetweendaterange(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL
)
RETURNS TABLE (
    "PatientId" INT,
    "PatientCode" VARCHAR,
    "ShortName" VARCHAR,
    "Gender" VARCHAR,
    "DateOfBirth" TIMESTAMP,
    "PhoneNumber" TIMESTAMP,
    "CRNDate" TIMESTAMP,
    "RefInvoiceNum" VARCHAR,
    "TotalAmount" DECIMAL,
    "InvoiceCode" VARCHAR,
    "FiscalYear" VARCHAR,
    "FiscalYearId" INT,
    "CreditNoteNumber" VARCHAR,
    "Remarks" VARCHAR,
    "BillingTransactionId" INT,
    "BillReturnId" INT
) AS $$
BEGIN
    /*
    filename: sp_bil_getcreditnotelistbetweendaterange
    description: to get list of credit notes for duplicate print.
    
    change history
    s.no.    updatedby/date                        remarks
    1.      sud,pratik/1may'21                 initial draft
    */
    
    RETURN QUERY SELECT  pat.patientid, 
    		pat.patientcode, 
    		pat.shortname, 
    		pat.gender, 
    		pat.dateofbirth,
    		pat.phonenumber,
    		crn.createdon AS "CRNDate",
    		crn.refinvoicenum,
    		crn.totalamount,
    		crn.invoicecode,
    		fy.fiscalyearformatted AS "FiscalYear",
    		crn.fiscalyearid,
    		crn.creditnotenumber,
    		crn.remarks,
    		crn.billingtransactionid,
    		crn.billreturnid
    
    from  bil_txn_invoicereturn crn inner join pat_patient pat
         on crn.patientid=pat.patientid
    inner join bil_cfg_fiscalyears fy
         on crn.fiscalyearid = fy.fiscalyearid
    
    where 
    (crn.createdon)::date between p_fromdate and p_todate 
    order by crn.billreturnid desc;
END;
$$ LANGUAGE plpgsql;