CREATE OR REPLACE FUNCTION sp_acc_bankreconcilationdetail(
    p_fromdate TIMESTAMP,
    p_todate TIMESTAMP,
    p_ledgerid INT,
    p_vouchertypeid INT,
    p_status INT
) RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'ref1';
    ref2 refcursor := 'ref2';
BEGIN
    -- Table 1: Reconciliation Data
    OPEN ref1 FOR
    SELECT txn.VoucherNumber
        ,txn.SectionId
        ,txn.TransactionDate
        ,txn.FiscalYearId
        ,item.LedgerId AS PartyLedgerId
        ,ledger.LedgerName AS PartyLedgerName
        ,subLedgerTxn.SubLedgerId AS PartySubLedgerId
        ,subLedger.SubLedgerName AS PartySubLedgerName
        ,voucher.VoucherName
        ,txn.ChequeNumber
        ,txn.ChequeDate
        ,CASE 
            WHEN COALESCE(item.DrCr, FALSE) = FALSE
                THEN item.Amount
            ELSE 0
            END AS LedgerCr
        ,CASE 
            WHEN COALESCE(item.DrCr, FALSE) = FALSE
                THEN 0
            ELSE item.Amount
            END AS LedgerDr
        ,item.DrCr
        ,txn.VoucherId AS VoucherTypeId
        ,reconsile.BankTransactionDate
        ,item.Amount AS BankBalance
        ,CASE 
            WHEN reconsile.Id IS NULL
                THEN 'open'
            ELSE 'close'
            END AS Status
        ,txn.Remarks AS Remark
        ,txn.TransactionId
        ,txn.HospitalId
        ,reconsile.BankRefNumber
        ,reconsile.VoucherTypeId AS RecVoucherTypeId
        ,p_ledgerid AS LedgerId
        ,0 AS IsVerified
    FROM ACC_TransactionItems item
    JOIN ACC_Transactions txn ON item.TransactionId = txn.TransactionId
    JOIN ACC_TXN_SubledgerRecords subLedgerTxn ON item.TransactionItemId = subLedgerTxn.TransactionItemId AND item.LedgerId = subLedgerTxn.LedgerId
    JOIN ACC_Ledger ledger ON item.LedgerId = ledger.LedgerId
    JOIN ACC_MST_SubLedger subLedger ON subLedgerTxn.SubLedgerId = subLedger.SubLedgerId
    JOIN ACC_MST_Vouchers voucher ON txn.VoucherId = voucher.VoucherId
    LEFT JOIN ACC_TXN_Bank_Reconciliation reconsile ON txn.TransactionId = reconsile.TransactionId
        AND item.LedgerId = reconsile.PartyLedgerId
    WHERE txn.TransactionDate::DATE BETWEEN p_fromdate::DATE AND p_todate::DATE
        AND COALESCE(txn.IsVoucherReversed, FALSE) = FALSE
        AND txn.TransactionId IN (
            SELECT TransactionId
            FROM ACC_TransactionItems
            WHERE LedgerId = p_ledgerid
            )
        AND item.LedgerId <> p_ledgerid
        AND txn.IsVerified = TRUE
        AND (
            txn.VoucherId = p_vouchertypeid
            OR p_vouchertypeid = 0
            )
        AND (
            (
                CASE 
                    WHEN reconsile.BankTransactionDate IS NULL
                        THEN 1
                    ELSE 2
                    END
                ) = p_status
            OR p_status = 0
            );
    RETURN NEXT ref1;

    -- Table 2: Reconciliation Opening Balance
    OPEN ref2 FOR
    SELECT COALESCE(SUM(CASE 
                    WHEN DrCr = TRUE
                        THEN BankBalance
                    ELSE - BankBalance
                    END), 0)::DECIMAL AS ReconcileOpeningBalance
    FROM ACC_TXN_Bank_Reconciliation
    WHERE LedgerId = p_ledgerid;
    RETURN NEXT ref2;
END;
$$ LANGUAGE plpgsql;
