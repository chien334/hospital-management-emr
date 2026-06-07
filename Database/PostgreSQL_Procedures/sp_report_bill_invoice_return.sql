CREATE OR REPLACE FUNCTION sp_report_bill_invoice_return(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL
)
RETURNS TABLE (
    "Date" TIMESTAMP,
    "BillingTransactionId" INT,
    "RefInvoiceNo" VARCHAR,
    "PatientCode" VARCHAR,
    "PatientName" VARCHAR,
    "BillReturnId" INT,
    "CreditNoteNumber" VARCHAR,
    "SubTotal" DECIMAL,
    "DiscountAmount" INT,
    "TaxableAmount" DECIMAL,
    "TaxTotal" DECIMAL,
    "TotalAmount" DECIMAL,
    "PaymentMode" VARCHAR,
    "Remarks" VARCHAR,
    "CounterName" INT,
    "User" VARCHAR
) AS $$
BEGIN
    /*
    filename: "sp_bill_report_invoice_return"
    createdby/date: ashim/24-07-2017
    description: this sp will give sum of total amount return by each item along with its necesorry details recipt no, hospital no, patient name, service department name,return date, and return remarks
    remarks:   
    change history
    s.no.    updatedby/date                        remarks
    1       ashim/09-05-2017                created the script
    2.      sud:26aug'21                   * Converting the comparision to type=DATE, earlier it was TIMESTAMP
                                           * Taking EmployeeName and PatientName from single column (FullName, ShortName) of respective tables.  
    */
    
            RETURN QUERY SELECT
                    (br.CreatedOn)::DATE AS "Date",
                    br.BillingTransactionId,
                    (br.FiscalYear || '-' || br.invoicecode || (br.refinvoicenum)::varchar ) AS "RefInvoiceNo",
                    p.patientcode,
                    p.shortname AS "PatientName",
    				br.billreturnid,
                    br.creditnotenumber,
                    br.subtotal,
                    br.discountamount,
                    br.taxableamount,
                    br.taxtotal,
                    br.totalamount,
    				br.paymentmode,
                    br.remarks,
    				cntr.countername,
                    emp.fullname  AS "User"
            from    bil_txn_invoicereturn br
            join    pat_patient p on p.patientid=br.patientid
            join    emp_employee emp on emp.employeeid = br.createdby
    		join	bil_cfg_counter cntr on br.counterid = cntr.counterid
            where  (br.createdon)::date
                      between (p_fromdate)::date and (p_todate)::date
            order by  (br.createdon)::date desc;
END;
$$ LANGUAGE plpgsql;