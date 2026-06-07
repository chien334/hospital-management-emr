CREATE OR REPLACE FUNCTION sp_report_bil_patientcreditsummary(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL
)
RETURNS TABLE (
    "SN" VARCHAR,
    "CreatedOn" TIMESTAMP,
    "PatientId" INT,
    "PatientCode" VARCHAR,
    "PatientName" VARCHAR,
    "InvoiceNo" VARCHAR,
    "Remarks" VARCHAR,
    "OrganizationName" TIMESTAMP,
    "DiscountAmount" INT,
    "SubTotal" DECIMAL,
    "TotalAmount" DECIMAL
) AS $$
BEGIN
    /*
    filename: "sp_report_bil_patientcreditsummary" '2018-01-01', '2019-03-05'
    createdby/date: umed/20-07-2017
    description: to get sum of total amount collected of each patient between given dates 
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1       umed/20-07-2017	                   created the script
    2        umed/25-07-2017                   added lasttxndate and done sum of totalamt and added sn
    3.		ramavtar/05june'18				changed whole script for Credit Summary -- still need review and changes in this report
    4.		Dinesh/21st Feb'19					date filter added includng date, remarks and invoice no
    5.      shankar/13th feb'20                Added subtotal, discount amount and credit organization.
    */
    BEGIN
    If(p_fromdate IS NOT NULL OR p_todate IS NOT NULL)
    	THEN 
        
    RETURN QUERY SELECT
      (CAST(ROW_NUMBER() OVER (ORDER BY pat.PatientCode) AS int)) AS "SN",
      txn.CreatedOn,
      txn.PatientId,
      pat.PatientCode,
      pat.FirstName || ' ' || COALESCE(pat.MiddleName || ' ', '') || pat.LastName AS "PatientName",
      txn.InvoiceNo,
      txn.Remarks,
      org.OrganizationName,
      txn.DiscountAmount,
      txn.SubTotal,
      SUM(txn.TotalAmount) AS "TotalAmount"
    FROM BIL_TXN_BillingTransaction txn
    JOIN BIL_MST_Credit_Organization org
      ON txn.OrganizationId = org.OrganizationId
    JOIN PAT_Patient pat
      ON txn.PatientId = pat.PatientId
    WHERE txn.BillStatus = 'unpaid'
    and coalesce(txn.returnstatus, 0) != 1 and (txn.createdon)::date between p_fromdate and p_todate
    group by txn.patientid,
             pat.patientcode,
             pat.firstname,
             pat.lastname,
             pat.middlename,
    		 txn.invoiceno,
    		 txn.remarks,
    		 txn.createdon,
    		 org.organizationname,
    		 txn.discountamount,
    		 txn.subtotal;
    		 
    end if;
    end;
END;
$$ LANGUAGE plpgsql;