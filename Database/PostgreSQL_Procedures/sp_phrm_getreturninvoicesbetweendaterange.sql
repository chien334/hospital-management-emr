CREATE OR REPLACE FUNCTION sp_phrm_getreturninvoicesbetweendaterange(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_storeid INT DEFAULT NULL
)
RETURNS TABLE (
    "InvoiceId" INT,
    "InvoiceReturnId" INT,
    "InvoicePrintId" INT,
    "ReferenceInvoiceNo" VARCHAR,
    "PatientName" VARCHAR,
    "Address" VARCHAR,
    "ContactNumber" TIMESTAMP,
    "PatientCode" VARCHAR,
    "DateOfBirth" TIMESTAMP,
    "Gender" VARCHAR,
    "DiscountAmount" INT,
    "IsOutdoorPat" BOOLEAN,
    "SubTotal" DECIMAL,
    "TotalAmount" DECIMAL,
    "DiscountAmount_1" INT,
    "VATAmount" DECIMAL,
    "PaidAmount" INT,
    "PaymentMode" VARCHAR,
    "CreateOn" TIMESTAMP,
    "CreatedBy" VARCHAR,
    "CreditNoteID" INT,
    "Remarks" VARCHAR,
    "PrintCount" INT,
    "PatientType" VARCHAR,
    "FiscalYear" VARCHAR,
    "UserName" VARCHAR,
    "NSHINumber" VARCHAR,
    "ClaimCode" VARCHAR
) AS $$
BEGIN
    /*
    filename:"sp_phrm_getreturninvoicesbetweendaterange" 
    createdby/date:  ramesh/16thdec'21
    Description:  Get Invoice Return Details for Pharmacy-> Duplicate Print
    Change History
    S.No.    UpdatedBy/Date                        Remarks
    1.      Ramesh/26Apr'21                   initial draft
    2.		rohit/15feb'21					  Fetched InvoiceReferenceNo for Multiple Invoice Return
    */
    BEGIN
      RETURN QUERY SELECT inv.InvoiceId, invret.InvoiceReturnId, inv.InvoicePrintId, invret.ReferenceInvoiceNo, pat.FirstName || COALESCE(' ' || pat.MiddleName, '') || ' ' || pat.LastName AS "PatientName", pat.Address, pat.PhoneNumber AS "ContactNumber", pat.PatientCode, pat.DateOfBirth, pat.Gender, invret.DiscountAmount, pat.IsOutdoorPat, invret.SubTotal, invret.TotalAmount, invret.DiscountAmount AS "DiscountAmount_1", invret.VATAmount, invret.PaidAmount, invret.PaymentMode, invret.CreatedOn AS "CreateOn", invret.CreatedBy, invret.CreditNoteID, invret.Remarks, invret.PrintCount, CASE WHEN COALESCE(pat.IsOutdoorPat, 0) = 0 THEN 'indoor' ELSE 'outdoor' end AS "PatientType", fy.fiscalyearformatted AS "FiscalYear", usr.username, pat.ins_nshinumber AS "NSHINumber", invret.claimcode AS "ClaimCode" from
        phrm_txn_invoicereturn invret
        left join phrm_txn_invoice inv on inv.invoiceid = invret.invoiceid
        inner join pat_patient pat on pat.patientid = invret.patientid
        inner join bil_cfg_fiscalyears fy on invret.fiscalyearid = fy.fiscalyearid
        inner join rbac_user usr on invret.createdby = usr.employeeid
      where
      (invret.createdon)::date between p_fromdate and p_todate
        and invret.storeid = p_storeid
      order by invret.createdon desc;
    end;
END;
$$ LANGUAGE plpgsql;