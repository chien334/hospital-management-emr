CREATE OR REPLACE FUNCTION sp_ird_invoicedetails(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL
)
RETURNS TABLE (
    "*" VARCHAR
) AS $$
BEGIN
    /*
        filename: "sp_ird_invoicedetails" 
        createdby/date: umed/2017-09-294
        description: to get the invoice details as per ird requirements 
        change history
        s.no.    updatedby/date         remarks
        1        sud/2018-may-7         revised as per new ird requirements    
        2        ramavtar/07dec         applying filter on createdon instead of paiddate 
        3.       vikas/02 jan 2019      modify patient shortname(firstname and last name) to fullname(first,middle, and lastname)   
        4.       sud/2jul'21            Setting Is_Bill_Active=False if One or more CreditNote generated from current invoice.
                                        Taking Customer_name from Patient>ShortName field
        5.       Shankar/20thSept'21    update for payment_method and transactionid columns(revised as per new ird requirements)
        6.       anish/3 december 2021  getting the data of return as well 
        7.       ramesh/dev 6 dec 2021  merged the billing ird_invoicedetails sp with pharmachy ird_invoicedetails sp
    	8.       ramesh/17th dec'21     Remove CR in pharmacy cash sale invoice
        */
      BEGIN
        IF (p_fromdate IS NOT NULL)
            OR (p_todate IS NOT NULL) 
      THEN
            
            RETURN QUERY SELECT *
            FROM
                (
                                                            (
                                    SELECT
                        fiscYr.FiscalYearFormatted AS Fiscal_Year,
                        (ret.CreditNoteNumber)::VARCHAR AS Bill_No,
                        pats.ShortName AS Customer_name,
                        --sud:2July'21--revised column to take customer_name
                        pats.pannumber,
                        (ret.returnedon)::timestamp as billdate,
                        ret.returnsubtotal as amount,
                        ret.returndiscountamount as discountamount,
                        (0.00)::float as taxable_amount,
                        (0.00)::float as tax_amount,
                        ret.returntotalamount as total_amount,
                        case when ret.isreturnsyncedwithird = 1 then 'Yes' else 'No' end  as syncedwithird,
                        case when biltxn.printcount > 0 then 'Yes' else 'No' end as is_printed,
                        to_char((ret.returnedon)::time, 'YYYY-MM-DD')as printed_time,
                        ret.returnedby as entered_by,
                        ret.returnedby as printed_by,
                        --might need to change logic for isrealtime--: sud:9may'18--  
                        CASE WHEN COALESCE(ret.IsReturnRealTime, 0) = 1 THEN 'yes' ELSE 'no' END AS Is_Realtime,
                        --CASE
                        --  WHEN COALESCE(biltxn.ReturnStatus, 0) = 0 THEN 'true'
                        --  ELSE 'false'
                        --END AS Is_Bill_Active
                        'true' AS Is_Bill_Active,
                        ret.ReturnPaymentMethod AS Payment_Method,
                        'n/a' as TransactionId,
                        (0.00)::float as VAT_Refund_Amount
                    FROM
                        BIL_TXN_BillingTransaction biltxn
                        INNER JOIN EMP_Employee emp ON emp.EmployeeId = biltxn.CreatedBy
                        INNER JOIN PAT_Patient pats ON pats.PatientId = biltxn.PatientId
                        INNER JOIN BIL_CFG_FiscalYears fiscYr ON biltxn.FiscalYearId = fiscYr.FiscalYearId
                        INNER JOIN(
        Select
                            BillingTransactionId AS "ReturnTxnId",
                            'crn' || (CreditNoteNumber)::VARCHAR AS "CreditNoteNumber",
                            -SubTotal AS "ReturnSubTotal",
                            -DiscountAmount AS "ReturnDiscountAmount",
                            -TotalAmount AS "ReturnTotalAmount",
                            IsRemoteSynced AS "IsReturnSyncedWithIRD",
                            1 as ReturnPrintCount,
                            0 AS "ReturnVATRefundAmount",
                            e.FullName AS "ReturnedBy",
                            r.CreatedOn AS "ReturnedOn",
                            PaymentMode AS "ReturnPaymentMethod",
                            IsRealtime AS "IsReturnRealTime"
                        from
                            BIL_TXN_InvoiceReturn r
                            join EMP_Employee e on r.CreatedBy=e.EmployeeId
                        Where
          r.IsActive = 1
      ) ret ON biltxn.BillingTransactionId = ret.ReturnTxnId
                    WHERE
      (biltxn.CreatedOn)::date BETWEEN (p_fromdate)::date 
      AND (p_todate)::date
                    )
                UNION ALL
                    (
                    SELECT
                        fiscYr.FiscalYearFormatted AS Fiscal_Year,
                        COALESCE(biltxn.InvoiceCode, 'bl') || (biltxn.InvoiceNo)::VARCHAR AS Bill_No,
                        pats.ShortName AS Customer_name,
                        --sud:2July'21--revised column to take customer_name
                        pats.pannumber,
                        (biltxn.createdon)::timestamp as billdate,
                        biltxn.subtotal as amount,
                        biltxn.discountamount as discountamount,
                        (0.00)::float as taxable_amount,
                        (0.00)::float as tax_amount,
                        biltxn.totalamount as total_amount,
                        case when biltxn.isremotesynced = 1 then 'Yes' else 'No' end as syncedwithird,
                        case when biltxn.printcount > 0 then 'Yes' else 'No' end as is_printed,
                        to_char((biltxn.createdon)::time, 'YYYY-MM-DD')as printed_time,
                        emp.fullname as entered_by,
                        emp.fullname as printed_by,
                        --might need to change logic for isrealtime--: sud:9may'18--  
                        CASE WHEN COALESCE(biltxn.IsRealtime, 0) = 1 THEN 'yes' ELSE 'no' END AS Is_Realtime,
                        --CASE
                        --  WHEN COALESCE(biltxn.ReturnStatus, 0) = 0 THEN 'true'
                        --  ELSE 'false'
                        --END AS Is_Bill_Active
                        'true' AS Is_Bill_Active,
                        biltxn.PaymentMode as Payment_Method,
                        'n/a' as TransactionId,
                        (0.00)::float as VAT_Refund_Amount
                    FROM
                        BIL_TXN_BillingTransaction biltxn
                        INNER JOIN EMP_Employee emp ON emp.EmployeeId = biltxn.CreatedBy
                        INNER JOIN PAT_Patient pats ON pats.PatientId = biltxn.PatientId
                        INNER JOIN BIL_CFG_FiscalYears fiscYr ON biltxn.FiscalYearId = fiscYr.FiscalYearId
                    WHERE
      (biltxn.CreatedOn)::date BETWEEN (p_fromdate)::date 
      AND (p_todate)::date 
      )
                UNION ALL
                (
                                SELECT
                        fisc.FiscalYearFormatted AS Fiscal_Year,
                        ret.CreditNoteNumber AS Bill_No,
                        pat.ShortName AS Customer_name,
                        pat.PANNumber,
                        (ret.ReturnedOn)::TIMESTAMP AS BillDate,
                        --ret.ReturnedOn AS BillDate,
                        ret.ReturnSubTotal AS Amount,
                        ret.ReturnDiscountAmount AS DiscountAmount,
                        (0.00)::float AS Taxable_Amount,
                        (0.00)::float AS Tax_Amount,
                        ret.ReturnTotalAmount AS Total_Amount,
                        CASE WHEN ret.IsReturnSyncedWithIRD = 1 THEN 'yes' ELSE 'no' END  AS SyncedWithIRD,
                        CASE WHEN inv.PrintCount > 0 THEN 'yes' ELSE 'no' END AS Is_Printed,
                        to_char((ret.ReturnedOn)::time, 'yyyy-mm-dd')AS Printed_Time,
                        ret.ReturnedBy  AS Entered_By,
                        ret.ReturnedBy AS Printed_by,
                        --might need to change logic for isrealtime--: sud:9May'18--  
                        case when coalesce(ret.isreturnrealtime, 0) = 1 then 'Yes' else 'No' end as is_realtime,
                        'True' as is_bill_active,
                        ret.returnpaymentmethod as payment_method,
                        'N/A' as transactionid,
                        (0.00)::float as vat_refund_amount
                    from phrm_txn_invoice inv
                        inner join emp_employee emp on emp.employeeid=inv.createdby
                        inner join pat_patient pat on pat.patientid=inv.patientid
                        inner join bil_cfg_fiscalyears fisc on inv.fiscalyearid=fisc.fiscalyearid
                        inner join(
            select
                            invoiceid as "returntxnid",
                            'CR-PH' || (creditnoteid)::varchar as "creditnotenumber",
                            -subtotal as "returnsubtotal",
                            -discountamount as "returndiscountamount",
                            -totalamount as "returntotalamount",
                            isremotesynced as "isreturnsyncedwithird",
                            1 as returnprintcount,
                            0 as "returnvatrefundamount",
                            e.fullname as "returnedby",
                            invret.createdon as "returnedon",
                            paymentmode as "returnpaymentmethod",
                            isrealtime as "isreturnrealtime"
                        from
                            phrm_txn_invoicereturn invret
                            join emp_employee e on invret.createdby=e.employeeid
                            join phrm_cfg_fiscalyears fisc on invret.fiscalyearid = fisc.fiscalyearid
         ) ret
                        on inv.invoiceid = ret.returntxnid
                    where ((inv.createon)::date between (p_fromdate)::date and (p_todate)::date)
                union all
                    (
                    select
                        fiscyr.fiscalyearformatted as fiscal_year,
                        'PH' || (inv.invoiceprintid)::varchar as bill_no,
                        pats.shortname as customer_name,
                        --sud:2july'21--revised column to take Customer_name
                        pats.PANNumber,
                        (inv.CreateOn)::TIMESTAMP AS BillDate,
                        inv.SubTotal AS Amount,
                        inv.DiscountAmount AS DiscountAmount,
                        (0.00)::float AS Taxable_Amount,
                        (0.00)::float AS Tax_Amount,
                        inv.TotalAmount AS Total_Amount,
                        CASE WHEN inv.IsRemoteSynced = 1 THEN 'yes' ELSE 'no' END  AS SyncedWithIRD,
                        CASE WHEN inv.PrintCount > 0 THEN 'yes' ELSE 'no' END AS Is_Printed,
                        to_char((inv.CreateOn)::time, 'yyyy-mm-dd')AS Printed_Time,
                        emp.FullName AS Entered_By,
                        emp.FullName AS Printed_by,
                        --might need to change logic for isrealtime--: sud:9May'18--  
                        case when coalesce(inv.isrealtime, 0) = 1 then 'Yes' else 'No' end as is_realtime,
                        'True' as is_bill_active,
                        inv.paymentmode as payment_method,
                        'N/A' as transactionid,
                        (0.00)::float as vat_refund_amount
                    from
                        phrm_txn_invoice inv
                        inner join emp_employee emp on emp.employeeid = inv.createdby
                        inner join pat_patient pats on pats.patientid = inv.patientid
                        inner join bil_cfg_fiscalyears fiscyr on inv.fiscalyearid = fiscyr.fiscalyearid
                    where
      (inv.createon)::date between (p_fromdate)::date and (p_todate)::date)
      )
      )
      as irddetails
            order by irddetails.billdate desc;
        end if;
    end;
END;
$$ LANGUAGE plpgsql;