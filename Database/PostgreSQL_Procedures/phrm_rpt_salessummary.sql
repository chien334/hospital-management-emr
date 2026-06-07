CREATE OR REPLACE FUNCTION phrm_rpt_salessummary(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL
)
RETURNS TABLE (
    "StoreName" VARCHAR,
    "CashSales" VARCHAR,
    "CashSalesRefund" VARCHAR,
    "TotalCashSales" DECIMAL,
    "CashInHand" VARCHAR,
    "CreditSales" VARCHAR,
    "CreditSalesRefund" VARCHAR,
    "TotalCreditSales" DECIMAL,
    "NetTotalSales" DECIMAL
) AS $$
BEGIN
    -- =============================================
    -- author:		sanjit
    -- create date: 18/06/2021
    -- description: generated sales analysis report
    -- =============================================
    /* change history
    s.no.    updatedby/date                        remarks
    1.		sanjit/ramesh/28jul21		total summation mismatch issue fixed
    2.      ramesh/rohit/12dec'21       altered as per user collection report
    3.		rohit/18Jul'22			    createdon date is converted as date before predicate check
    4.		rohit/2nov'22				Added  'convert(date,i.createdon)' in table view 'creditsales' 
    */
    
        -- body of the stored procedure
        RETURN QUERY SELECT X.StoreName, X.CashSales, X.CashSalesRefund, X.TotalCashSales, X.CashInHand, X.CreditSales, X.CreditSalesRefund, X.TotalCreditSales, X.TotalCashSales || X.TotalCreditSales AS "NetTotalSales"
        FROM
            (
                SELECT store.StoreId, store.Name AS "StoreName", COALESCE(SUM(cashsales.TotalCashSales),0) AS "CashSales", COALESCE(SUM(cashsalesRefund.TotalCashRefund),0) AS "CashSalesRefund",
                    COALESCE(SUM(cashsales.TotalCashSales),0) - COALESCE(SUM(cashsalesRefund.TotalCashRefund),0) AS "TotalCashSales",
                    COALESCE(SUM(cashsales.TotalCashSales),0) - COALESCE(SUM(cashsalesRefund.TotalCashRefund),0) AS "CashInHand",
                    COALESCE(SUM(creditsales.TotalCreditSales),0) AS "CreditSales", COALESCE(SUM(creditsalesRefund.TotalCreditRefund),0) AS "CreditSalesRefund",
                    COALESCE(SUM(creditsales.TotalCreditSales),0) - COALESCE(SUM(creditsalesRefund.TotalCreditRefund),0) AS "TotalCreditSales",
                    0 AS orderFilter
    
                FROM PHRM_MST_Store store
                    LEFT JOIN (
                        SELECT I.StoreId, SUM(I.TotalAmount) AS "TotalCashSales"
                        FROM PHRM_TXN_Invoice I
                        WHERE I.PaymentMode = 'cash' AND I.BilStatus = 'paid' AND COALESCE(I.IsReturn,0) != 1
                            AND (I.CreateOn)::Date BETWEEN p_fromdate AND p_todate
                        GROUP BY I.StoreId
                    ) cashsales
                    ON store.StoreId = cashSales.StoreId
                    LEFT JOIN (
                        SELECT IR.StoreId, SUM(IR.TotalAmount) AS "TotalCashRefund"
                        FROM PHRM_TXN_InvoiceReturn IR
                        WHERE IR.PaymentMode = 'cash'
                            AND (IR.CreatedOn)::Date BETWEEN p_fromdate AND p_todate
                        GROUP BY IR.StoreId
                    ) cashsalesRefund
                    ON store.StoreId = cashsalesRefund.StoreId
                    LEFT JOIN (
                        SELECT I.StoreId, SUM(I.TotalAmount) AS "TotalCreditSales"
                        FROM PHRM_TXN_Invoice I
                        WHERE I.PaymentMode = 'credit' AND COALESCE(I.IsReturn,0) != 1
                            AND (I.CreateOn)::Date BETWEEN p_fromdate AND p_todate
                        GROUP BY I.StoreId
                    ) creditsales
                    ON store.StoreId = creditsales.StoreId
                    LEFT JOIN (
                        SELECT IR.StoreId, SUM(IR.TotalAmount) AS "TotalCreditRefund"
                        FROM PHRM_TXN_InvoiceReturn IR
                        WHERE IR.PaymentMode = 'credit'
                            AND (IR.CreatedOn)::Date BETWEEN p_fromdate AND p_todate
                        GROUP BY IR.StoreId
                    ) creditsalesRefund
                    ON store.StoreId = creditsalesRefund.StoreId
                WHERE store.Category = 'dispensary'
                GROUP BY store.StoreId, store.Name
    
            UNION
    
                SELECT NULL AS StoreId, 'total' AS "StoreName", COALESCE(SUM(cashsales.TotalCashSales),0) AS "CashSales", COALESCE(SUM(cashsalesRefund.TotalCashRefund),0) AS "CashSalesRefund",
                    COALESCE(SUM(cashsales.TotalCashSales),0) - COALESCE(SUM(cashsalesRefund.TotalCashRefund),0) AS "TotalCashSales",
                    COALESCE(SUM(cashsales.TotalCashSales),0) - COALESCE(SUM(cashsalesRefund.TotalCashRefund),0) AS "CashInHand",
                    COALESCE(SUM(creditsales.TotalCreditSales),0) AS "CreditSales", COALESCE(SUM(creditsalesRefund.TotalCreditRefund),0) AS "CreditSalesRefund",
                    COALESCE(SUM(creditsales.TotalCreditSales),0) - COALESCE(SUM(creditsalesRefund.TotalCreditRefund),0) AS "TotalCreditSales",
                    1 AS orderFilter
                FROM(
                        SELECT SUM(I.TotalAmount) AS "TotalCashSales"
                        FROM PHRM_TXN_Invoice I
                        WHERE I.PaymentMode = 'cash' AND I.BilStatus = 'paid' AND COALESCE(I.IsReturn,0) != 1
                            AND (I.CreateOn)::Date BETWEEN p_fromdate AND p_todate
                    ) cashsales
                    LEFT JOIN (
                        SELECT SUM(IR.TotalAmount) AS "TotalCashRefund"
                        FROM PHRM_TXN_InvoiceReturn IR
                        WHERE IR.PaymentMode = 'cash'
                            AND (IR.CreatedOn)::Date BETWEEN p_fromdate AND p_todate
                    ) cashsalesRefund
                    ON 1 = 1
                    LEFT JOIN
                    (
                        SELECT SUM(I.TotalAmount) AS "TotalCreditSales"
                        FROM PHRM_TXN_Invoice I
                        WHERE I.PaymentMode = 'credit'  AND COALESCE(I.IsReturn,0) != 1
                            AND (I.CreateOn)::DATE BETWEEN p_fromdate AND p_todate
                    ) creditsales
                    ON 1=1
                    LEFT JOIN (
                        SELECT SUM(IR.TotalAmount) AS "TotalCreditRefund"
                        FROM PHRM_TXN_InvoiceReturn IR
                        WHERE IR.PaymentMode = 'credit'
                            and (ir.createdon)::date between p_fromdate and p_todate
                    ) creditsalesrefund
                    on 1 = 1  
                ) x
        order by x.orderfilter;
END;
$$ LANGUAGE plpgsql;