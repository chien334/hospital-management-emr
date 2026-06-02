CREATE PROCEDURE [dbo].[SP_ACC_Bill_GetPharmacyPaymentModeWiseData] @TransactionDate DATE
        ,@HospitalId INT
AS
-- =============================================
-- Author:      <Dev Narayan Chaudhary>
-- Create date: <2022-05-18>
-- Description: <It porvides paymentmode wise cash segregation from pharmacy module>
--exec [dbo].[SP_ACC_Bill_GetPharmacyPaymentModeWiseData] '2022-12-28',3
-- =============================================
--Change History
/*
SN.                Auther/DateTime                   Description
1.                 DevN/19th May 23                  Use BIL_TXN_Deposit Table for PharmacyDeposit Scenerios.
*/
BEGIN
    DECLARE @BillTxnIdsCSV NVARCHAR(MAX)
        ,@DepositIdsCSV NVARCHAR(MAX)
        ,@DepositDeductIdsCSV NVARCHAR(MAX)
        ,@DepositReturnIdsCSV NVARCHAR(MAX)
        ,@SettlementIdsCSV NVARCHAR(MAX)
        ,@SalesReturnIdsCSV NVARCHAR(MAX)
        ,@CashDiscountReturnSettlementIdsCSV NVARCHAR(MAX);
    SET @BillTxnIdsCSV = (
                    SELECT STRING_AGG(CAST(InvoiceId AS NVARCHAR(MAX)), ',')
                    FROM PHRM_TXN_Invoice
                    WHERE ISNULL(IsTransferredToACC, 0) = 0
					AND PaymentMode = 'cash'
                        AND CONVERT(DATE, CreateOn) = CONVERT(DATE, @TransactionDate)
            )
    --Setting DepositIds into @DepositIdsCSV 
    SET @DepositIdsCSV = (
            SELECT STRING_AGG(CAST(DepositId AS NVARCHAR(MAX)), ',')
            FROM BIL_TXN_Deposit
            WHERE TransactionType = 'deposit'
                AND ISNULL(IsDepositSync, 0) = 0
                AND CONVERT(DATE, CreatedOn) = CONVERT(DATE, @TransactionDate)
				AND ModuleName = 'Pharmacy'
            )
    --Setting DepositDeductIds into @DepositDeductIdsCSV 
    SET @DepositDeductIdsCSV = (
            SELECT STRING_AGG(CAST(DepositId AS NVARCHAR(MAX)), ',')
            FROM BIL_TXN_Deposit
            WHERE DepositId IN (
                    SELECT DISTINCT DepositId
                    FROM BIL_TXN_Deposit
                    WHERE TransactionType = 'depositdeduct'
                        AND ISNULL(IsDepositSync, 0) = 0
                        AND CONVERT(DATE, CreatedOn) = CONVERT(DATE, @TransactionDate)
						AND ModuleName = 'Pharmacy'
                    )
            )
    --Setting DepositReturnIds into @DepositReturnIdsCSV 
    SET @DepositReturnIdsCSV = (
            SELECT STRING_AGG(CAST(DepositId AS NVARCHAR(MAX)), ',')
            FROM BIL_TXN_Deposit
            WHERE TransactionType = 'depositreturn'
                AND ISNULL(IsDepositSync, 0) = 0
                AND CONVERT(DATE, CreatedOn) = CONVERT(DATE, @TransactionDate)
				AND ModuleName = 'Pharmacy'
            )
    --Setting SettlementIds into @SettlementIdsCSV 
    SET @SettlementIdsCSV = (
            SELECT STRING_AGG(CAST(SettlementId AS NVARCHAR(MAX)), ',')
            FROM PHRM_TXN_Settlement
            WHERE SettlementId IN (
                    SELECT DISTINCT SettlementId
                    FROM PHRM_TXN_Settlement
                    WHERE ISNULL(IsTransferredToACC, 0) = 0
                        AND ISNULL(CollectionFromReceivable,0)>0
                        AND CONVERT(DATE, CreatedOn) = CONVERT(DATE, @TransactionDate)
                    )
            )
--Setting SettlementIds for  into @CashDiscountReturnSettlementIdsCSV
    SET @CashDiscountReturnSettlementIdsCSV = (
            SELECT STRING_AGG(CAST(SettlementId AS NVARCHAR(MAX)), ',')
            FROM PHRM_TXN_Settlement
            WHERE SettlementId IN (
                    SELECT DISTINCT SettlementId
                    FROM PHRM_TXN_Settlement
                    WHERE ISNULL(IsTransferredToACC, 0) = 0
                        AND ISNULL(CollectionFromReceivable,0)=0
                        AND ISNULL(DiscountReturnAmount,0)>0
                        AND CONVERT(DATE, CreatedOn) = CONVERT(DATE, @TransactionDate)
                    )
            )
    --Setting InvoiceReturnIds into @SalesReturnIdsCSV
    SET @SalesReturnIdsCSV = (
            SELECT STRING_AGG(CAST(InvoiceReturnId AS NVARCHAR(MAX)), ',')
            FROM PHRM_TXN_InvoiceReturn
            WHERE InvoiceReturnId IN (
                    SELECT DISTINCT InvoiceReturnId
                    FROM PHRM_TXN_InvoiceReturn
                    WHERE ISNULL(IsTransferredToACC, 0) = 0
                        AND CONVERT(DATE, CreatedOn) = CONVERT(DATE, @TransactionDate)
                    )
            )
    SELECT modes.PaymentSubCategoryName
        ,'PHRMCashInvoice' as TransactionType
        ,ISNULL(SUM(InAmount),0) 'TotalAmount'
        ,LedgerId
        ,NULL as 'OrganizationId'
		,ISNULL(lm.SubLedgerId,0) AS 'SubLedgerId'
    FROM PHRM_EmployeeCashTransaction cash
    INNER JOIN MST_PaymentModes modes ON cash.PaymentModeSubCategoryId = modes.PaymentSubCategoryId
    LEFT JOIN ACC_Ledger_Mapping lm ON modes.PaymentSubCategoryId = lm.ReferenceId and lm.LedgerType ='paymentmodes' and lm.HospitalId =@HospitalId
    WHERE TransactionType = 'CashSales'
        AND ReferenceNo IN (
            SELECT VALUE
            FROM STRING_SPLIT(@BillTxnIdsCSV, ',')
            )
    GROUP BY modes.PaymentSubCategoryName, lm.LedgerId, lm.SubLedgerId
    UNION ALL
    SELECT modes.PaymentSubCategoryName
        ,'PHRMDepositAdd' as TransactionType
        ,ISNULL(SUM(InAmount),0)  'TotalAmount'
        ,LedgerId
        ,NULL as 'OrganizationId'
		,ISNULL(lm.SubLedgerId,0) AS 'SubLedgerId'
    FROM PHRM_EmployeeCashTransaction cash
    INNER JOIN MST_PaymentModes modes ON cash.PaymentModeSubCategoryId = modes.PaymentSubCategoryId
    LEFT JOIN ACC_Ledger_Mapping lm ON modes.PaymentSubCategoryId = lm.ReferenceId and lm.LedgerType ='paymentmodes' and lm.HospitalId =@HospitalId
    WHERE TransactionType = 'DepositAdd'
        AND ReferenceNo IN (
            SELECT VALUE
            FROM STRING_SPLIT(@DepositIdsCSV, ',')
            )
    GROUP BY modes.PaymentSubCategoryName,lm.LedgerId, lm.SubLedgerId
    UNION ALL
    SELECT modes.PaymentSubCategoryName
        ,'DepositDeduct' as TransactionType
        ,ISNULL(SUM(OutAmount),0)  'TotalAmount'
        , LedgerId
        ,NULL as 'OrganizationId'
		,ISNULL(lm.SubLedgerId,0) AS 'SubLedgerId'
    FROM PHRM_EmployeeCashTransaction cash
    INNER JOIN MST_PaymentModes modes ON cash.PaymentModeSubCategoryId = modes.PaymentSubCategoryId
    LEFT JOIN ACC_Ledger_Mapping lm ON modes.PaymentSubCategoryId = lm.ReferenceId and lm.LedgerType ='paymentmodes' and lm.HospitalId =@HospitalId
    WHERE TransactionType = 'depositdeduct'
        AND ReferenceNo IN (
            SELECT VALUE
            FROM STRING_SPLIT(@DepositDeductIdsCSV, ',')
            )
    GROUP BY modes.PaymentSubCategoryName, lm.LedgerId, lm.SubLedgerId
    UNION ALL
    SELECT modes.PaymentSubCategoryName
        ,'PHRMDepositReturn' as TransactionType
        ,ISNULL(SUM(OutAmount),0)  'TotalAmount'
        ,LedgerId
        ,NULL as 'OrganizationId'
		,ISNULL(lm.SubLedgerId,0) AS 'SubLedgerId'
    FROM PHRM_EmployeeCashTransaction cash
    INNER JOIN MST_PaymentModes modes ON cash.PaymentModeSubCategoryId = modes.PaymentSubCategoryId
    LEFT JOIN ACC_Ledger_Mapping lm ON modes.PaymentSubCategoryId = lm.ReferenceId and lm.LedgerType ='paymentmodes' and lm.HospitalId =@HospitalId
    WHERE TransactionType = 'ReturnDeposit'
        AND ReferenceNo IN (
            SELECT VALUE
            FROM STRING_SPLIT(@DepositReturnIdsCSV, ',')
            )
    GROUP BY modes.PaymentSubCategoryName, lm.LedgerId, lm.SubLedgerId
    UNION ALL
    SELECT modes.PaymentSubCategoryName
        ,'PHRMCreditBillPaid' as TransactionType
        ,ISNULL(SUM(InAmount),0) - ISNULL(SUM(OutAmount),0) 'TotalAmount'
        ,lm.LedgerId
        ,sett.OrganizationId   
		,ISNULL(lm.SubLedgerId,0) AS 'SubLedgerId'
    FROM PHRM_TXN_Settlement sett
    JOIN PHRM_EmployeeCashTransaction cash
    ON sett.SettlementId= cash.ReferenceNo
    INNER JOIN MST_PaymentModes modes ON cash.PaymentModeSubCategoryId = modes.PaymentSubCategoryId
    LEFT JOIN ACC_Ledger_Mapping lm ON modes.PaymentSubCategoryId = lm.ReferenceId and lm.LedgerType ='paymentmodes' and lm.HospitalId =@HospitalId
    WHERE TransactionType in  ('CollectionFromReceivable','CashDiscountGiven')
        AND ReferenceNo IN (
            SELECT VALUE
            FROM STRING_SPLIT(@SettlementIdsCSV, ',') -- settlementId ref
            )
    GROUP BY modes.PaymentSubCategoryName, lm.LedgerId, sett.OrganizationId, lm.SubLedgerId
    UNION ALL
    SELECT modes.PaymentSubCategoryName
        ,'CashBillReturn' as TransactionType
        ,ISNULL(SUM(OutAmount),0)  'TotalAmount'
        ,LedgerId
        ,NULL as 'OrganizationId'
		,ISNULL(lm.SubLedgerId,0) AS 'SubLedgerId'
    FROM PHRM_EmployeeCashTransaction cash
    INNER JOIN MST_PaymentModes modes ON cash.PaymentModeSubCategoryId = modes.PaymentSubCategoryId
    LEFT JOIN ACC_Ledger_Mapping lm ON modes.PaymentSubCategoryId = lm.ReferenceId and lm.LedgerType ='paymentmodes' and lm.HospitalId =@HospitalId
    WHERE TransactionType = 'SalesReturn'
        AND ReferenceNo IN (
            SELECT VALUE
            FROM STRING_SPLIT(@SalesReturnIdsCSV, ',')
            )
    GROUP BY modes.PaymentSubCategoryName, lm.LedgerId, lm.SubLedgerId
    UNION ALL
    SELECT modes.PaymentSubCategoryName
        ,'DiscountReturn' as TransactionType
        ,ISNULL(SUM(InAmount),0)  'TotalAmount'
        , 0 as LedgerId
        ,NULL as 'OrganizationId'
		,0 AS 'SubLedgerId'
    FROM PHRM_EmployeeCashTransaction cash
    INNER JOIN MST_PaymentModes modes ON cash.PaymentModeSubCategoryId = modes.PaymentSubCategoryId
    WHERE TransactionType = 'CashDiscountReceived'
        AND ReferenceNo IN (
            SELECT VALUE
            FROM STRING_SPLIT(@CashDiscountReturnSettlementIdsCSV, ',') -- settlementId ref
            )
    GROUP BY modes.PaymentSubCategoryName
END