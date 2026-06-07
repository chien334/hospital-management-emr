CREATE OR REPLACE FUNCTION sp_report_bill_schemedetailinvoice(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_memberships VARCHAR DEFAULT NULL,
    p_ranks VARCHAR DEFAULT NULL,
    p_users VARCHAR DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
BEGIN
    /*  
    filename: "sp_report_bill_schemedetailinvoice"  
    execute: exec sp_report_bill_schemedetailinvoice '2022-09-01', '2022-12-06', '7,6,5,9,8,4','CON,SI,HC,AHC,SHC,ASI','1,51,66,45,47,46,44'
    createdby/date: krishna/6thdec
    description: scheme wise detail invoice level report
    remarks:      
    change history  
    s.no.    updatedby/date               remarks  
    1.       krishna/6thdec'22           initital draft
    */
    
    
       OPEN ref1 FOR SELECT * FROM (
    SELECT
        txn.CreatedOn AS "Date",
        NULL AS "ReferenceReceiptNo",
        CONCAT(txn.InvoiceCode,'-',txn.InvoiceNo) AS "ReceiptNo",
        Case WHEN txn.PaymentMode ='credit' THEN 'creditsales'
        ELSE 'cashsales' END AS "BillingType",
        txn.TransactionType AS "VisitType",
        pat.PatientCode AS "HospitalNo",
        pat.ShortName AS "PatientName",
        pat.Rank AS "Rank",
        mem.MembershipTypeName AS "Membership",
        txn.SubTotal AS "SubTotal",
        txn.DiscountAmount AS "Discount",
        txn.TotalAmount AS "Total",
        emp.FullName AS "User",
        txn.Remarks AS "Remarks"
    FROM BIL_TXN_BillingTransaction txn
    INNER JOIN pat_patient pat
                  ON txn.patientid = pat.patientid
          INNER JOIN emp_employee emp
                  ON txn.createdby = emp.employeeid
          INNER JOIN pat_cfg_membershiptype mem
                  ON pat.membershiptypeid = mem.membershiptypeid
          INNER JOIN (SELECT value AS "MembershipTypeId"
                      FROM   String_split(p_memberships, ',')) membership
                  ON mem.membershiptypeid = membership.membershiptypeid
          INNER JOIN (SELECT value AS "Ranks"
                      FROM   String_split(p_ranks, ',')) ran
                  ON pat.rank = ran.ranks
          INNER JOIN (SELECT value AS "UserId"
                      FROM   String_split(p_users, ',')) us
                  ON us.userid = txn.createdby
    WHERE  (txn.createdon)::DATE BETWEEN p_fromdate AND p_todate
    
    UNION ALL 
    
    SELECT
    	ret.CreatedOn AS "Date",
        CONCAT(txn.InvoiceCode,'-',txn.InvoiceNo) AS "ReferenceReceiptNo",
        CONCAT('cr','-',ret.CreditNoteNumber) AS "ReceiptNo",
        Case WHEN txn.PaymentMode ='credit' THEN 'returncreditsales'
        ELSE 'returncashsales' END AS "BillingType",
        txn.TransactionType AS "VisitType",
        pat.PatientCode AS "HospitalNo",
        pat.ShortName AS "PatientName",
        pat.Rank AS "Rank",
        mem.MembershipTypeName AS "Membership",
        ret.SubTotal AS "SubTotal",
        ret.DiscountAmount AS "Discount",
        ret.TotalAmount AS "Total",
        emp.FullName AS "User",
        ret.Remarks AS "Remarks"
    FROM BIL_TXN_InvoiceReturn ret
    	INNER JOIN BIL_TXN_BillingTransaction txn
    			  ON ret.BillingTransactionId = txn.BillingTransactionId
    	INNER JOIN pat_patient pat
                  ON ret.patientid = pat.patientid
        INNER JOIN emp_employee emp
                ON ret.createdby = emp.employeeid
        INNER JOIN pat_cfg_membershiptype mem
                ON pat.membershiptypeid = mem.membershiptypeid
        INNER JOIN (SELECT value AS "MembershipTypeId"
                    FROM   String_split(p_memberships, ',')) membership
                ON pat.membershiptypeid = membership.membershiptypeid
        INNER JOIN (SELECT value AS "Ranks"
                    FROM   String_split(p_ranks, ',')) ran
                ON pat.Rank = ran.ranks
        INNER JOIN (SELECT value AS "UserId"
                    FROM   String_split(p_users, ',')) us
                  on us.userid = ret.createdby
    where  (ret.createdon)::date between p_fromdate and p_todate
    
    ) tbl
    order by tbl.date desc;
        return next ref1;
END;
$$ LANGUAGE plpgsql;