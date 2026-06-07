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
    SELECT COALESCE(SUM(COALESCE(bi.Quantity, 0) - COALESCE(bedChrgReturn.RetQuantity, 0)), 0)::INT
    INTO v_total_days
    FROM bil_txn_billingtransactionitems bi
    INNER JOIN adt_patientadmission adm ON bi.PatientVisitId = adm.PatientVisitId
    INNER JOIN bil_mst_servicedepartment srv ON bi.ServiceDepartmentId = srv.ServiceDepartmentId
    LEFT JOIN (
        SELECT retItm.BillingTransactionItemId,
               SUM(retItm.RetQuantity) AS RetQuantity
        FROM bil_txn_invoicereturnitems retItm
        INNER JOIN bil_mst_servicedepartment srv ON retItm.ServiceDepartmentId = srv.ServiceDepartmentId
        WHERE srv.IntegrationName = 'Bed Charges'
        GROUP BY retItm.BillingTransactionItemId
    ) bedChrgReturn ON bi.BillingTransactionItemId = bedChrgReturn.BillingTransactionItemId
    WHERE srv.IntegrationName = 'Bed Charges'
      AND adm.DischargeDate::DATE BETWEEN p_fromdate AND p_todate
      AND adm.AdmissionStatus != 'cancel';

    RETURN v_total_days;
END;
$$;
