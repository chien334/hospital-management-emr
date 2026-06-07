DROP FUNCTION IF EXISTS public.fn_mr_hospsummary_gettotalinpatientdays(DATE, DATE) CASCADE;

CREATE OR REPLACE FUNCTION public.fn_mr_hospsummary_gettotalinpatientdays(
    p_fromdate DATE,
    p_todate DATE
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_days INT;
BEGIN
    SELECT COALESCE(SUM(COALESCE(bi."Quantity", 0) - COALESCE(bedChrgReturn."RetQuantity", 0)), 0)::INT
    INTO v_total_days
    FROM "BIL_TXN_BillingTransactionItems" bi
    INNER JOIN "ADT_PatientAdmission" adm ON bi."PatientVisitId" = adm."PatientVisitId"
    INNER JOIN "BIL_MST_ServiceDepartment" srv ON bi."ServiceDepartmentId" = srv."ServiceDepartmentId"
    LEFT JOIN (
        SELECT retItm."BillingTransactionItemId",
               SUM(retItm."RetQuantity") AS "RetQuantity"
        FROM "BIL_TXN_InvoiceReturnItems" retItm
        INNER JOIN "BIL_MST_ServiceDepartment" srv ON retItm."ServiceDepartmentId" = srv."ServiceDepartmentId"
        WHERE srv."IntegrationName" = 'Bed Charges'
        GROUP BY retItm."BillingTransactionItemId"
    ) bedChrgReturn ON bi."BillingTransactionItemId" = bedChrgReturn."BillingTransactionItemId"
    WHERE srv."IntegrationName" = 'Bed Charges'
      AND adm."DischargeDate"::DATE BETWEEN p_fromdate AND p_todate
      AND adm."AdmissionStatus" != 'cancel';

    RETURN v_total_days;
END;
$$;
