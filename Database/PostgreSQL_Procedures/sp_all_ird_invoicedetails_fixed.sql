DROP FUNCTION IF EXISTS sp_all_ird_invoicedetails(timestamp, timestamp) CASCADE;
CREATE OR REPLACE FUNCTION sp_all_ird_invoicedetails(
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
    "VAT_Refund_Amount" DOUBLE PRECISION,
    "ItemNameAndQuantity" TEXT
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
            irddetails.VAT_Refund_Amount::double precision,
            irddetails.itemnameandquantity::text
        FROM (
            (
                select 
                    fiscyr."FiscalYearFormatted" as Fiscal_Year,
                    (ret."CreditNoteNumber")::varchar as Bill_No,
                    pats."ShortName" as Customer_name,
                    pats."PANNumber" as PANNumber,
                    (ret."ReturnedOn")::timestamp as BillDate,
                    ret."ReturnSubTotal" as Amount,
                    ret."ReturnDiscountAmount" as DiscountAmount,
                    (0.00)::double precision as Taxable_Amount,
                    (0.00)::double precision as Tax_Amount,
                    ret."ReturnTotalAmount" as Total_Amount,
                    txnitms.itemnameandquantity,
                    case when ret."IsReturnSyncedWithIRD" = true then 'Yes' else 'No' end as SyncedWithIRD,
                    case when biltxn."PrintCount" > 0 then 'Yes' else 'No' end as Is_Printed,
                    to_char((ret."ReturnedOn")::time, 'YYYY-MM-DD') as Printed_Time,
                    ret."ReturnedBy" as Entered_By,
                    ret."ReturnedBy" as Printed_by,
                    case when coalesce(ret."IsReturnRealTime", false) = true then 'Yes' else 'No' end as Is_Realtime,
                    'True' as Is_Bill_Active,
                    ret."ReturnPaymentMethod" as Payment_Method,
                    'N/A'::varchar as TransactionId,
                    (0.00)::double precision as VAT_Refund_Amount
                from "BIL_TXN_BillingTransaction" biltxn
                inner join (
                    select "BillingTransactionId" as billingtransactionid,
                        (
                            (select json_agg(t) from (
                                select "ItemName" as "itemname",
                                    (- "RetQuantity")::int as "quantity"
                                from "BIL_TXN_InvoiceReturnItems" as inneritms
                                where inneritms."BillingTransactionId" = outeritems."BillingTransactionId"
                            ) as "t")::text
                        ) as itemnameandquantity
                    from "BIL_TXN_BillingTransactionItems" as outeritems
                    group by "BillingTransactionId"
                ) txnitms on biltxn."BillingTransactionId" = txnitms.billingtransactionid
                inner join "EMP_Employee" emp on emp."EmployeeId" = biltxn."CreatedBy"
                inner join "PAT_Patient" pats on pats."PatientId" = biltxn."PatientId"
                inner join "BIL_CFG_FiscalYears" fiscyr on biltxn."FiscalYearId" = fiscyr."FiscalYearId"
                inner join (
                    select "BillingTransactionId" as "returntxnid",
                        'CRN' || ("CreditNoteNumber")::varchar as "CreditNoteNumber",
                        - "SubTotal" as "ReturnSubTotal",
                        - "DiscountAmount" as "ReturnDiscountAmount",
                        - "TotalAmount" as "ReturnTotalAmount",
                        "IsRemoteSynced" as "IsReturnSyncedWithIRD",
                        1 as returnprintcount,
                        0 as "ReturnVATRefundAmount",
                        e."FullName" as "ReturnedBy",
                        r."CreatedOn" as "ReturnedOn",
                        "PaymentMode" as "ReturnPaymentMethod",
                        "IsRealtime" as "IsReturnRealTime"
                    from "BIL_TXN_InvoiceReturn" r
                    join "EMP_Employee" e on r."CreatedBy" = e."EmployeeId"
                    where r."IsActive" = true
                ) ret on biltxn."BillingTransactionId" = ret."returntxnid"
                where (biltxn."CreatedOn")::date between (p_fromdate)::date and (p_todate)::date
            )
            union all
            (
                select 
                    fiscyr."FiscalYearFormatted" as Fiscal_Year,
                    coalesce(biltxn."InvoiceCode", 'BL') || (biltxn."InvoiceNo")::varchar as Bill_No,
                    pats."ShortName" as Customer_name,
                    pats."PANNumber" as PANNumber,
                    (biltxn."CreatedOn")::TIMESTAMP AS BillDate,
                    biltxn."SubTotal" AS Amount,
                    biltxn."DiscountAmount" AS DiscountAmount,
                    (0.00)::double precision AS Taxable_Amount,
                    (0.00)::double precision AS Tax_Amount,
                    biltxn."TotalAmount" AS Total_Amount,
                    txnItms.itemnameandquantity,
                    CASE WHEN biltxn."IsRemoteSynced" = true THEN 'Yes' ELSE 'No' END AS SyncedWithIRD,
                    CASE WHEN biltxn."PrintCount" > 0 THEN 'Yes' ELSE 'No' END AS Is_Printed,
                    to_char((biltxn."CreatedOn")::TIME, 'yyyy-mm-dd') AS Printed_Time,
                    emp."FullName" AS Entered_By,
                    emp."FullName" AS Printed_by,
                    CASE WHEN COALESCE(biltxn."IsRealtime", false) = true THEN 'Yes' ELSE 'No' END AS Is_Realtime,
                    'True' AS Is_Bill_Active,
                    biltxn."PaymentMode" AS Payment_Method,
                    'N/A'::varchar AS TransactionId,
                    (0.00)::double precision AS VAT_Refund_Amount
                FROM "BIL_TXN_BillingTransaction" biltxn
                INNER JOIN (
                    SELECT "BillingTransactionId" as billingtransactionid,
                        (
                            (SELECT json_agg(t) FROM (
                                SELECT "ItemName" AS "ItemName",
                                    ("Quantity")::INT AS "Quantity"
                                FROM "BIL_TXN_BillingTransactionItems" AS innerItms
                                WHERE innerItms."BillingTransactionId" = outerItems."BillingTransactionId"
                            ) AS "t")::text
                        ) AS itemnameandquantity
                    FROM "BIL_TXN_BillingTransactionItems" AS outerItems
                    GROUP BY "BillingTransactionId"
                ) txnItms ON biltxn."BillingTransactionId" = txnItms.billingtransactionid
                INNER JOIN "EMP_Employee" emp ON emp."EmployeeId" = biltxn."CreatedBy"
                INNER JOIN "PAT_Patient" pats ON pats."PatientId" = biltxn."PatientId"
                INNER JOIN "BIL_CFG_FiscalYears" fiscYr ON biltxn."FiscalYearId" = fiscYr."FiscalYearId"
                WHERE (biltxn."CreatedOn")::DATE BETWEEN (p_fromdate)::DATE AND (p_todate)::DATE
            )
            UNION ALL
            (
                SELECT 
                    fisc."FiscalYearFormatted" AS Fiscal_Year,
                    ret."CreditNoteNumber" AS Bill_No,
                    pat."ShortName" AS Customer_name,
                    pat."PANNumber" as PANNumber,
                    (ret."ReturnedOn")::TIMESTAMP AS BillDate,
                    ret."ReturnSubTotal" AS Amount,
                    ret."ReturnDiscountAmount" AS DiscountAmount,
                    (0.00)::double precision AS Taxable_Amount,
                    (0.00)::double precision AS Tax_Amount,
                    ret."ReturnTotalAmount" AS Total_Amount,
                    txnItms.itemnameandquantity,
                    CASE WHEN ret."IsReturnSyncedWithIRD" = true THEN 'Yes' ELSE 'No' END AS SyncedWithIRD,
                    CASE WHEN inv."PrintCount" > 0 THEN 'Yes' ELSE 'No' END AS Is_Printed,
                    to_char((ret."ReturnedOn")::TIME, 'yyyy-mm-dd') AS Printed_Time,
                    ret."ReturnedBy" AS Entered_By,
                    ret."ReturnedBy" AS Printed_by,
                    CASE WHEN COALESCE(ret."IsReturnRealTime", false) = true THEN 'Yes' ELSE 'No' END AS Is_Realtime,
                    'True' AS Is_Bill_Active,
                    ret."ReturnPaymentMethod" AS Payment_Method,
                    'N/A'::varchar AS TransactionId,
                    (0.00)::double precision AS VAT_Refund_Amount
                FROM "PHRM_TXN_Invoice" inv
                INNER JOIN (
                    SELECT "InvoiceId" as invoiceid,
                        (
                            (SELECT json_agg(t) FROM (
                                SELECT invItem."ItemName" AS "ItemName",
                                    (- "ReturnedQty")::INT AS "Quantity",
                                    (uom."UOMName") AS "UOM"
                                FROM "PHRM_TXN_InvoiceReturnItems" AS innerItms
                                INNER JOIN "PHRM_TXN_InvoiceItems" invItem ON innerItms."InvoiceItemId" = invItem."InvoiceItemId"
                                INNER JOIN "PHRM_MST_Item" mstItem ON mstItem."ItemId" = invItem."ItemId"
                                INNER JOIN "PHRM_MST_UnitOfMeasurement" uom ON uom."UOMId" = mstItem."UOMId"
                                WHERE innerItms."InvoiceId" = outerItems."InvoiceId"
                            ) AS "t")::text
                        ) AS itemnameandquantity
                    FROM "PHRM_TXN_InvoiceItems" AS outerItems
                    GROUP BY "InvoiceId"
                ) txnItms ON inv."InvoiceId" = txnItms.invoiceid
                INNER JOIN "EMP_Employee" emp ON emp."EmployeeId" = inv."CreatedBy"
                INNER JOIN "PAT_Patient" pat ON pat."PatientId" = inv."PatientId"
                INNER JOIN "BIL_CFG_FiscalYears" fisc ON inv."FiscalYearId" = fisc."FiscalYearId"
                INNER JOIN (
                    SELECT "InvoiceId" AS "ReturnTxnId",
                        'cr-ph' || ("CreditNoteID")::VARCHAR AS "CreditNoteNumber",
                        - "SubTotal" AS "ReturnSubTotal",
                        - "DiscountAmount" as "ReturnDiscountAmount",
                        - "TotalAmount" as "ReturnTotalAmount",
                        "IsRemoteSynced" as "IsReturnSyncedWithIRD",
                        1 AS ReturnPrintCount,
                        0 AS "ReturnVATRefundAmount",
                        e."FullName" AS "ReturnedBy",
                        invRet."CreatedOn" AS "ReturnedOn",
                        "PaymentMode" AS "ReturnPaymentMethod",
                        "IsRealtime" AS "IsReturnRealTime"
                    FROM "PHRM_TXN_InvoiceReturn" invRet
                    JOIN "EMP_Employee" e ON invRet."CreatedBy" = e."EmployeeId"
                    JOIN "PHRM_CFG_FiscalYears" fisc ON invRet."FiscalYearId" = fisc."FiscalYearId"
                ) ret ON inv."InvoiceId" = ret."ReturnTxnId"
                WHERE ((inv."CreateOn")::DATE BETWEEN (p_fromdate)::DATE AND (p_todate)::DATE)
            )
            UNION ALL
            (
                SELECT 
                    fiscYr."FiscalYearFormatted" AS Fiscal_Year,
                    'ph' || (inv."InvoicePrintId")::VARCHAR AS Bill_No,
                    pats."ShortName" AS Customer_name,
                    pats."PANNumber" as PANNumber,
                    (inv."CreateOn")::TIMESTAMP AS BillDate,
                    inv."SubTotal" AS Amount,
                    inv."DiscountAmount" AS DiscountAmount,
                    (0.00)::double precision AS Taxable_Amount,
                    (0.00)::double precision AS Tax_Amount,
                    inv."TotalAmount" AS Total_Amount,
                    txnItms.itemnameandquantity,
                    CASE WHEN inv."IsRemoteSynced" = true THEN 'Yes' ELSE 'No' END AS SyncedWithIRD,
                    CASE WHEN inv."PrintCount" > 0 THEN 'Yes' ELSE 'No' END AS Is_Printed,
                    to_char((inv."CreateOn")::TIME, 'yyyy-mm-dd') AS Printed_Time,
                    emp."FullName" AS Entered_By,
                    emp."FullName" AS Printed_by,
                    CASE WHEN COALESCE(inv."IsRealtime", false) = true THEN 'Yes' ELSE 'No' END AS Is_Realtime,
                    'True' AS Is_Bill_Active,
                    inv."PaymentMode" AS Payment_Method,
                    'n/a'::varchar as transactionid,
                    (0.00)::double precision as vat_refund_amount
                from "PHRM_TXN_Invoice" inv
                inner join (
                    select "InvoiceId" as invoiceid,
                        (
                            (select json_agg(t) from (
                                select inneritms."ItemName" as "itemname",
                                    ("Quantity")::int as "quantity",
                                    uom."UOMName" as "uom"
                                from "PHRM_TXN_InvoiceItems" as inneritms
                                inner join "PHRM_MST_Item" as mstitem on mstitem."ItemId" = inneritms."ItemId"
                                inner join "PHRM_MST_UnitOfMeasurement" as uom on uom."UOMId" = mstitem."UOMId"
                                where inneritms."InvoiceId" = outeritems."InvoiceId"
                            ) as "t")::text
                        ) as itemnameandquantity
                    from "PHRM_TXN_InvoiceItems" as outeritems
                    group by "InvoiceId"
                ) txnitms on inv."InvoiceId" = txnitms.invoiceid
                inner join "EMP_Employee" emp on emp."EmployeeId" = inv."CreatedBy"
                inner join "PAT_Patient" pats on pats."PatientId" = inv."PatientId"
                inner join "BIL_CFG_FiscalYears" fiscyr on inv."FiscalYearId" = fiscyr."FiscalYearId"
                where (inv."CreateOn")::date between (p_fromdate)::date and (p_todate)::date
            )
        ) as irddetails
        order by irddetails.BillDate desc;
    END IF;
END;
$$ LANGUAGE plpgsql;
