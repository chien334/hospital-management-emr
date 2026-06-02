CREATE PROCEDURE [dbo].[PHRM_RPT_SalesSummary]
    @FromDate DATETIME = null,
    @ToDate DATETIME = null
AS
-- =============================================
-- Author:		Sanjit
-- Create date: 18/06/2021
-- Description: generated sales analysis report
-- =============================================
/* Change History
S.No.    UpdatedBy/Date                        Remarks
1.		sanjit/ramesh/28Jul21		total summation mismatch issue fixed
2.      ramesh/rohit/12Dec'21       altered as per user collection report
3.		rohit/18Jul'22			    CreatedOn Date is Converted As Date before predicate check
4.		Rohit/2Nov'22				Added  'Convert(Date,I.CreatedOn)' in table view 'creditsales' 
*/
BEGIN
    -- body of the stored procedure
    SELECT X.StoreName, X.CashSales, X.CashSalesRefund, X.TotalCashSales, X.CashInHand, X.CreditSales, X.CreditSalesRefund, X.TotalCreditSales, X.TotalCashSales + X.TotalCreditSales 'NetTotalSales'
    FROM
        (
            SELECT store.StoreId, store.Name 'StoreName', ISNULL(SUM(cashsales.TotalCashSales),0) 'CashSales', ISNULL(SUM(cashsalesRefund.TotalCashRefund),0) 'CashSalesRefund',
                ISNULL(SUM(cashsales.TotalCashSales),0) - ISNULL(SUM(cashsalesRefund.TotalCashRefund),0) 'TotalCashSales',
                ISNULL(SUM(cashsales.TotalCashSales),0) - ISNULL(SUM(cashsalesRefund.TotalCashRefund),0) 'CashInHand',
                ISNULL(SUM(creditsales.TotalCreditSales),0) 'CreditSales', ISNULL(SUM(creditsalesRefund.TotalCreditRefund),0) 'CreditSalesRefund',
                ISNULL(SUM(creditsales.TotalCreditSales),0) - ISNULL(SUM(creditsalesRefund.TotalCreditRefund),0) 'TotalCreditSales',
                0 AS orderFilter

            FROM PHRM_MST_Store store
                LEFT JOIN (
                    SELECT I.StoreId, SUM(I.TotalAmount) 'TotalCashSales'
                    FROM PHRM_TXN_Invoice I
                    WHERE I.PaymentMode = 'cash' AND I.BilStatus = 'paid' AND ISNULL(I.IsReturn,0) != 1
                        AND Convert(Date,I.CreateOn) BETWEEN @FromDate AND @ToDate
                    GROUP BY I.StoreId
                ) cashsales
                ON store.StoreId = cashSales.StoreId
                LEFT JOIN (
                    SELECT IR.StoreId, SUM(IR.TotalAmount) 'TotalCashRefund'
                    FROM PHRM_TXN_InvoiceReturn IR
                    WHERE IR.PaymentMode = 'cash'
                        AND Convert(Date,IR.CreatedOn) BETWEEN @FromDate AND @ToDate
                    GROUP BY IR.StoreId
                ) cashsalesRefund
                ON store.StoreId = cashsalesRefund.StoreId
                LEFT JOIN (
                    SELECT I.StoreId, SUM(I.TotalAmount) 'TotalCreditSales'
                    FROM PHRM_TXN_Invoice I
                    WHERE I.PaymentMode = 'credit' AND ISNULL(I.IsReturn,0) != 1
                        AND Convert(Date,I.CreateOn) BETWEEN @FromDate AND @ToDate
                    GROUP BY I.StoreId
                ) creditsales
                ON store.StoreId = creditsales.StoreId
                LEFT JOIN (
                    SELECT IR.StoreId, SUM(IR.TotalAmount) 'TotalCreditRefund'
                    FROM PHRM_TXN_InvoiceReturn IR
                    WHERE IR.PaymentMode = 'credit'
                        AND Convert(Date,IR.CreatedOn) BETWEEN @FromDate AND @ToDate
                    GROUP BY IR.StoreId
                ) creditsalesRefund
                ON store.StoreId = creditsalesRefund.StoreId
            WHERE store.Category = 'dispensary'
            GROUP BY store.StoreId, store.Name

        UNION

            SELECT NULL AS StoreId, 'Total' AS StoreName, ISNULL(SUM(cashsales.TotalCashSales),0) 'CashSales', ISNULL(SUM(cashsalesRefund.TotalCashRefund),0) 'CashSalesRefund',
                ISNULL(SUM(cashsales.TotalCashSales),0) - ISNULL(SUM(cashsalesRefund.TotalCashRefund),0) 'TotalCashSales',
                ISNULL(SUM(cashsales.TotalCashSales),0) - ISNULL(SUM(cashsalesRefund.TotalCashRefund),0) 'CashInHand',
                ISNULL(SUM(creditsales.TotalCreditSales),0) 'CreditSales', ISNULL(SUM(creditsalesRefund.TotalCreditRefund),0) 'CreditSalesRefund',
                ISNULL(SUM(creditsales.TotalCreditSales),0) - ISNULL(SUM(creditsalesRefund.TotalCreditRefund),0) 'TotalCreditSales',
                1 AS orderFilter
            FROM(
                    SELECT SUM(I.TotalAmount) 'TotalCashSales'
                    FROM PHRM_TXN_Invoice I
                    WHERE I.PaymentMode = 'cash' AND I.BilStatus = 'paid' AND ISNULL(I.IsReturn,0) != 1
                        AND Convert(Date,I.CreateOn) BETWEEN @FromDate AND @ToDate
                ) cashsales
                LEFT JOIN (
                    SELECT SUM(IR.TotalAmount) 'TotalCashRefund'
                    FROM PHRM_TXN_InvoiceReturn IR
                    WHERE IR.PaymentMode = 'cash'
                        AND Convert(Date,IR.CreatedOn) BETWEEN @FromDate AND @ToDate
                ) cashsalesRefund
                ON 1 = 1
                LEFT JOIN
                (
                    SELECT SUM(I.TotalAmount) 'TotalCreditSales'
                    FROM PHRM_TXN_Invoice I
                    WHERE I.PaymentMode = 'credit'  AND ISNULL(I.IsReturn,0) != 1
                        AND CONVERT(DATE,I.CreateOn) BETWEEN @FromDate AND @ToDate
                ) creditsales
                ON 1=1
                LEFT JOIN (
                    SELECT SUM(IR.TotalAmount) 'TotalCreditRefund'
                    FROM PHRM_TXN_InvoiceReturn IR
                    WHERE IR.PaymentMode = 'credit'
                        AND Convert(Date,IR.CreatedOn) BETWEEN @FromDate AND @ToDate
                ) creditsalesRefund
                ON 1 = 1  
            ) X
    ORDER BY X.orderFilter
END