DROP FUNCTION IF EXISTS sp_ird_invoicedetails(timestamp, timestamp) CASCADE;
CREATE OR REPLACE FUNCTION sp_ird_invoicedetails(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL
)
RETURNS TABLE (
    "Fiscal_Year" TEXT,
    "Bill_No" TEXT,
    "Customer_name" TEXT,
    "PANNumber" TEXT,
    "BillDate" TIMESTAMP,
    "Amount" DOUBLE PRECISION,
    "DiscountAmount" DOUBLE PRECISION,
    "Taxable_Amount" DOUBLE PRECISION,
    "Tax_Amount" DOUBLE PRECISION,
    "Total_Amount" DOUBLE PRECISION,
    "SyncedWithIRD" TEXT,
    "Is_Printed" TEXT,
    "Printed_Time" TEXT,
    "Entered_by" TEXT,
    "Printed_by" TEXT,
    "Is_Realtime" TEXT,
    "Is_Bill_Active" TEXT,
    "Payment_Method" TEXT,
    "TransactionId" TEXT,
    "VAT_Refund_Amount" DOUBLE PRECISION
) AS $$
#variable_conflict use_column
BEGIN
    IF (p_fromdate IS NOT NULL) OR (p_todate IS NOT NULL) THEN
        RETURN QUERY 
        SELECT
            irddetails.Fiscal_Year::text,
            irddetails.Bill_No::text,
            irddetails.Customer_name::text,
            irddetails.PANNumber::text,
            irddetails.BillDate,
            irddetails.Amount::double precision,
            irddetails.DiscountAmount::double precision,
            irddetails.Taxable_Amount::double precision,
            irddetails.Tax_Amount::double precision,
            irddetails.Total_Amount::double precision,
            irddetails.SyncedWithIRD::text,
            irddetails.Is_Printed::text,
            irddetails.Printed_Time::text,
            irddetails.Entered_By::text,
            irddetails.Printed_by::text,
            irddetails.Is_Realtime::text,
            irddetails.Is_Bill_Active::text,
            irddetails.Payment_Method::text,
            irddetails.TransactionId::text,
            irddetails.VAT_Refund_Amount::double precision
        FROM (
            (
                SELECT
                    fiscYr."FiscalYearFormatted" AS Fiscal_Year,
                    (ret."CreditNoteNumber")::VARCHAR AS Bill_No,
                    pats."ShortName" AS Customer_name,
                    pats."PANNumber" AS PANNumber,
                    (ret."ReturnedOn")::timestamp as BillDate,
                    ret."ReturnSubTotal" as Amount,
                    ret."ReturnDiscountAmount" as DiscountAmount,
                    (0.00)::double precision as Taxable_Amount,
                    (0.00)::double precision as Tax_Amount,
                    ret."ReturnTotalAmount" as Total_Amount,
                    CASE WHEN ret."IsReturnSyncedWithIRD" = true THEN 'Yes' ELSE 'No' END as SyncedWithIRD,
                    CASE WHEN biltxn."PrintCount" > 0 THEN 'Yes' ELSE 'No' END as Is_Printed,
                    to_char((ret."ReturnedOn")::time, 'YYYY-MM-DD') as Printed_Time,
                    ret."ReturnedBy" as Entered_By,
                    ret."ReturnedBy" as Printed_by,
                    CASE WHEN COALESCE(ret."IsReturnRealTime", false) = true THEN 'Yes' ELSE 'No' END AS Is_Realtime,
                    'True' AS Is_Bill_Active,
                    ret."ReturnPaymentMethod" AS Payment_Method,
                    'n/a'::varchar as TransactionId,
                    (0.00)::double precision as VAT_Refund_Amount
                FROM
                    "BIL_TXN_BillingTransaction" biltxn
                    INNER JOIN "EMP_Employee" emp ON emp."EmployeeId" = biltxn."CreatedBy"
                    INNER JOIN "PAT_Patient" pats ON pats."PatientId" = biltxn."PatientId"
                    INNER JOIN "BIL_CFG_FiscalYears" fiscYr ON biltxn."FiscalYearId" = fiscYr."FiscalYearId"
                    INNER JOIN (
                        Select
                            "BillingTransactionId" AS "ReturnTxnId",
                            'crn' || ("CreditNoteNumber")::VARCHAR AS "CreditNoteNumber",
                            -"SubTotal" AS "ReturnSubTotal",
                            -"DiscountAmount" AS "ReturnDiscountAmount",
                            -"TotalAmount" AS "ReturnTotalAmount",
                            "IsRemoteSynced" AS "IsReturnSyncedWithIRD",
                            1 as returnprintcount,
                            0 AS "ReturnVATRefundAmount",
                            e."FullName" AS "ReturnedBy",
                            r."CreatedOn" AS "ReturnedOn",
                            "PaymentMode" AS "ReturnPaymentMethod",
                            "IsRealtime" AS "IsReturnRealTime"
                        from
                            "BIL_TXN_InvoiceReturn" r
                            join "EMP_Employee" e on r."CreatedBy" = e."EmployeeId"
                        Where
                            r."IsActive" = true
                    ) ret ON biltxn."BillingTransactionId" = ret."ReturnTxnId"
                WHERE
                    (biltxn."CreatedOn")::date BETWEEN (p_fromdate)::date AND (p_todate)::date
            )
            UNION ALL
            (
                SELECT
                    fiscYr."FiscalYearFormatted" AS Fiscal_Year,
                    COALESCE(biltxn."InvoiceCode", 'bl') || (biltxn."InvoiceNo")::VARCHAR AS Bill_No,
                    pats."ShortName" AS Customer_name,
                    pats."PANNumber" AS PANNumber,
                    (biltxn."CreatedOn")::timestamp as BillDate,
                    biltxn."SubTotal" as Amount,
                    biltxn."DiscountAmount" as DiscountAmount,
                    (0.00)::double precision as Taxable_Amount,
                    (0.00)::double precision as Tax_Amount,
                    biltxn."TotalAmount" as Total_Amount,
                    case when biltxn."IsRemoteSynced" = true then 'Yes' else 'No' end as SyncedWithIRD,
                    case when biltxn."PrintCount" > 0 then 'Yes' else 'No' end as Is_Printed,
                    to_char((biltxn."CreatedOn")::time, 'YYYY-MM-DD')as Printed_Time,
                    emp."FullName" as Entered_By,
                    emp."FullName" as Printed_by,
                    CASE WHEN COALESCE(biltxn."IsRealtime", false) = true THEN 'Yes' ELSE 'No' END AS Is_Realtime,
                    'True' AS Is_Bill_Active,
                    biltxn."PaymentMode" as Payment_Method,
                    'n/a'::varchar as TransactionId,
                    (0.00)::double precision as VAT_Refund_Amount
                FROM
                    "BIL_TXN_BillingTransaction" biltxn
                    INNER JOIN "EMP_Employee" emp ON emp."EmployeeId" = biltxn."CreatedBy"
                    INNER JOIN "PAT_Patient" pats ON pats."PatientId" = biltxn."PatientId"
                    INNER JOIN "BIL_CFG_FiscalYears" fiscYr ON biltxn."FiscalYearId" = fiscYr."FiscalYearId"
                WHERE
                    (biltxn."CreatedOn")::date BETWEEN (p_fromdate)::date AND (p_todate)::date 
            )
            UNION ALL
            (
                SELECT
                    fisc."FiscalYearFormatted" AS Fiscal_Year,
                    ret."CreditNoteNumber" AS Bill_No,
                    pat."ShortName" AS Customer_name,
                    pat."PANNumber" AS PANNumber,
                    (ret."ReturnedOn")::TIMESTAMP AS BillDate,
                    ret."ReturnSubTotal" AS Amount,
                    ret."ReturnDiscountAmount" AS DiscountAmount,
                    (0.00)::double precision AS Taxable_Amount,
                    (0.00)::double precision AS Tax_Amount,
                    ret."ReturnTotalAmount" AS Total_Amount,
                    CASE WHEN ret."IsReturnSyncedWithIRD" = true THEN 'Yes' ELSE 'No' END AS SyncedWithIRD,
                    CASE WHEN inv."PrintCount" > 0 THEN 'Yes' ELSE 'No' END AS Is_Printed,
                    to_char((ret."ReturnedOn")::time, 'yyyy-mm-dd')AS Printed_Time,
                    ret."ReturnedBy" AS Entered_By,
                    ret."ReturnedBy" AS Printed_by,
                    case when coalesce(ret."IsReturnRealTime", false) = true then 'Yes' else 'No' end as Is_Realtime,
                    'True' as Is_Bill_Active,
                    ret."ReturnPaymentMethod" as Payment_Method,
                    'N/A'::varchar as TransactionId,
                    (0.00)::double precision as VAT_Refund_Amount
                from "PHRM_TXN_Invoice" inv
                    inner join "EMP_Employee" emp on emp."EmployeeId" = inv."CreatedBy"
                    inner join "PAT_Patient" pat on pat."PatientId" = inv."PatientId"
                    inner join "BIL_CFG_FiscalYears" fisc on inv."FiscalYearId" = fisc."FiscalYearId"
                    inner join (
                        select
                            "InvoiceId" as "returntxnid",
                            'CR-PH' || ("CreditNoteID")::varchar as "CreditNoteNumber",
                            -"SubTotal" as "ReturnSubTotal",
                            -"DiscountAmount" as "ReturnDiscountAmount",
                            -"TotalAmount" as "ReturnTotalAmount",
                            "IsRemoteSynced" as "IsReturnSyncedWithIRD",
                            1 as returnprintcount,
                            0 as "ReturnVATRefundAmount",
                            e."FullName" as "ReturnedBy",
                            invret."CreatedOn" as "ReturnedOn",
                            "PaymentMode" as "ReturnPaymentMethod",
                            "IsRealtime" as "IsReturnRealTime"
                        from
                            "PHRM_TXN_InvoiceReturn" invret
                            join "EMP_Employee" e on invret."CreatedBy" = e."EmployeeId"
                            join "PHRM_CFG_FiscalYears" fisc on invret."FiscalYearId" = fisc."FiscalYearId"
                    ) ret on inv."InvoiceId" = ret."returntxnid"
                where ((inv."CreateOn")::date between (p_fromdate)::date and (p_todate)::date)
            )
            UNION ALL
            (
                select
                    fiscyr."FiscalYearFormatted" as Fiscal_Year,
                    'PH' || (inv."InvoicePrintId")::varchar as Bill_No,
                    pats."ShortName" as Customer_name,
                    pats."PANNumber" AS PANNumber,
                    (inv."CreateOn")::TIMESTAMP AS BillDate,
                    inv."SubTotal" AS Amount,
                    inv."DiscountAmount" AS DiscountAmount,
                    (0.00)::double precision AS Taxable_Amount,
                    (0.00)::double precision AS Tax_Amount,
                    inv."TotalAmount" AS Total_Amount,
                    CASE WHEN inv."IsRemoteSynced" = true THEN 'Yes' ELSE 'No' END AS SyncedWithIRD,
                    CASE WHEN inv."PrintCount" > 0 THEN 'Yes' ELSE 'No' END AS Is_Printed,
                    to_char((inv."CreateOn")::time, 'yyyy-mm-dd')AS Printed_Time,
                    emp."FullName" AS Entered_By,
                    emp."FullName" AS Printed_by,
                    case when coalesce(inv."IsRealtime", false) = true then 'Yes' else 'No' end as Is_Realtime,
                    'True' as Is_Bill_Active,
                    inv."PaymentMode" as Payment_Method,
                    'N/A'::varchar as TransactionId,
                    (0.00)::double precision as VAT_Refund_Amount
                from
                    "PHRM_TXN_Invoice" inv
                    inner join "EMP_Employee" emp on emp."EmployeeId" = inv."CreatedBy"
                    inner join "PAT_Patient" pats on pats."PatientId" = inv."PatientId"
                    inner join "BIL_CFG_FiscalYears" fiscyr on inv."FiscalYearId" = fiscyr."FiscalYearId"
                where
                    (inv."CreateOn")::date between (p_fromdate)::date and (p_todate)::date
            )
        ) as irddetails
        order by irddetails.BillDate desc;
    END IF;
END;
$$ LANGUAGE plpgsql;
