DROP FUNCTION IF EXISTS sp_ird_phrm_invoicedetails(timestamp, timestamp) CASCADE;
CREATE OR REPLACE FUNCTION sp_ird_phrm_invoicedetails(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL
)
RETURNS TABLE (
    "Fiscal_Year" TEXT,
    "Bill_No" TEXT,
    "Customer_name" TEXT,
    "PANNumber" TEXT,
    "BillDate" TEXT,
    "BillType" TEXT,
    "Amount" DECIMAL,
    "DiscountAmount" INT,
    "Total_Amount" DECIMAL,
    "Tax_Amount" DECIMAL,
    "Taxable_Amount" DECIMAL,
    "NonTaxable_Amount" DECIMAL,
    "SyncedWithIRD" TEXT,
    "Is_Printed" TEXT,
    "Printed_Time" TEXT,
    "Entered_by" TEXT,
    "Printed_by" TEXT,
    "Print_Count" INT,
    "Is_Realtime" TEXT,
    "Is_Bill_Active" TEXT,
    "Payment_Method" TEXT,
    "TransactionId" TEXT,
    "VAT_Refund_Amount" DECIMAL
) AS $$
#variable_conflict use_column
BEGIN
    IF (p_fromdate IS NOT NULL) OR (p_todate IS NOT NULL) THEN
        RETURN QUERY SELECT 
            fisc."FiscalYearFormatted"::text AS "Fiscal_Year",
            (inv."InvoicePrintId")::text AS "Bill_No",
            pat."ShortName"::text AS "Customer_name",	
            pat."PANNumber"::text AS "PANNumber",		
            to_char(inv."CreateOn", 'YYYY-MM-DD')::text AS "BillDate",
            'ItemTransaction'::text AS "BillType",
            inv."SubTotal"::decimal AS "Amount",
            inv."DiscountAmount"::int AS "DiscountAmount",
            ((inv."SubTotal"-inv."DiscountAmount")+inv."VATAmount")::decimal AS "Total_Amount",
            (inv."VATAmount")::decimal AS "Tax_Amount",
            (case when inv."VATAmount" > 0 or inv."VATAmount" is null then inv."SubTotal"-inv."DiscountAmount" else 0 end)::decimal AS "Taxable_Amount",
            (case when inv."VATAmount" <= 0 or inv."VATAmount" is null then inv."SubTotal"-inv."DiscountAmount" else 0 end)::decimal AS "NonTaxable_Amount",
            case when inv."IsRemoteSynced"=true then 'Yes'::text else 'No'::text end AS "SyncedWithIRD",
            case when inv."PrintCount" > 0 then 'Yes'::text else 'No'::text end AS "Is_Printed",	
            case when inv."PrintCount" > 0 then to_char((inv."CreateOn")::time, 'YYYY-MM-DD')::text else ''::text end AS "Printed_Time",
            emp."FullName"::text AS "Entered_by",				   
            emp."FullName"::text AS "Printed_by",
            inv."PrintCount"::int AS "Print_Count",
            case when coalesce(inv."IsRealtime", false)=true then 'Yes'::text else 'No'::text end AS "Is_Realtime",		
            case
                when coalesce(ret.returninvoiceid, 0) = 0 then 'True'::text
                else 'False'::text 
            end AS "Is_Bill_Active",
            inv."PaymentMode"::text AS "Payment_Method",
            inv."InvoiceId"::text AS "TransactionId",
            0.00::decimal AS "VAT_Refund_Amount"
        from "PHRM_TXN_Invoice" inv 
            inner join "EMP_Employee" emp on emp."EmployeeId" = inv."CreatedBy"
            inner join "PAT_Patient" pat on pat."PatientId" = inv."PatientId"
            inner join "BIL_CFG_FiscalYears" fisc on inv."FiscalYearId" = fisc."FiscalYearId"
            left join (
                select distinct "InvoiceId" as "returninvoiceid" from "PHRM_TXN_InvoiceReturn"
            ) ret on inv."InvoiceId" = ret.returninvoiceid
        where (
            (inv."CreateOn")::date between (p_fromdate)::date and (p_todate)::date 
        ); 
    end if;
end;
$$ LANGUAGE plpgsql;
