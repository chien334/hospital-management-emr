CREATE PROCEDURE [dbo].[SP_ACC_GetPharmacyTransactions]
    @TransactionDate DATE, @HospitalId INT
AS
/************************************************************************
FileName: [SP_ACC_GetPharmacyTransactions]
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Ajay/07Jul'19                       getting GrDiscountAmount,GrVATAmount,GrCOGSAmount
2.      Vikas 11th Aug 2020                 replaced parameter @FromDate and @ToDate into @TransactionDate
3.      Dev Narayan 24th May 2022           Added deposit and settlement scenerio
4.      Dev Narayan 27th May 2022           Added Pharmacy stock adjustment scenerio.
5.      DevN/19th May 23                    Get Data from BIL_TXN_Deposit Table for pharmacy deposit transactions.
*************************************************************************/
BEGIN
    --IF(@FromDate IS NOT NULL AND @ToDate IS NOT NULL) 
    BEGIN
        --Table1: CashInvoice
        SELECT InvoiceId
            ,PatientId
            ,ISNULL(SubTotal, 0) as 'SubTotal'
            ,ISNULL(DiscountAmount, 0) as 'DiscountAmount'
            ,ISNULL(VATAmount, 0) as 'VATAmount'
            ,ISNULL(TotalAmount, 0) as 'TotalAmount'
            ,PaymentMode
            ,OrganizationId
            ,CreateOn
        FROM PHRM_TXN_Invoice 
        WHERE ISNULL(IsTransferredToACC,0) = 0
            AND CONVERT(DATE, CreateOn) = CONVERT(DATE, @TransactionDate)
        --Table2: CashInvoiceReturn
        SELECT InvoiceReturnId
            ,PatientId
            ,ISNULL(SubTotal, 0) as 'SubTotal'
            ,ISNULL(DiscountAmount, 0) as 'DiscountAmount'
            ,ISNULL(VATAmount, 0) as 'VATAmount'
            ,ISNULL(TotalAmount, 0) as 'TotalAmount'
            ,CreatedOn
            ,PaymentMode
            ,OrganizationId
        FROM PHRM_TXN_InvoiceReturn 
        WHERE ISNULL(IsTransferredToACC,0) = 0
            AND CONVERT(DATE, CreatedOn) = CONVERT(DATE, @TransactionDate)
        --Table3: goodsReceipt
        SELECT CreatedOn
            ,SupplierId
            ,TransactionType
            ,ISNULL(TotalAmount,0) as 'TotalAmount'
            ,ISNULL(SubTotal,0) as 'SubTotal'
            ,ISNULL(VATAmount,0) as 'VATAmount'
            ,ISNULL(DiscountAmount, 0) as 'DiscountAmount'
            ,GoodReceiptId
        FROM PHRM_GoodsReceipt 
        WHERE ISNULL(IsTransferredToACC,0) = 0
            AND IsCancel = 0
            AND CONVERT(DATE, CreatedOn) = CONVERT(DATE, @TransactionDate)
        --Table4: writeoff
        SELECT WriteOffId
        ,ISNULL(SubTotal,0) as 'SubTotal'
        ,ISNULL(DiscountAmount,0) as 'DiscountAmount'
        ,ISNULL(VATAmount,0) as 'VATAmount'
        ,ISNULL(TotalAmount,0) as 'TotalAmount'
        ,CreatedOn
        FROM PHRM_WriteOff
        WHERE ISNULL(IsTransferredToACC,0) = 0
            AND CONVERT(DATE, CreatedOn) = CONVERT(DATE, @TransactionDate)
        --Table5: dispatchToDept && dispatchToDeptRet
        SELECT StockTxnItemId
        ,TransactionType
        ,CreatedOn
        ,ISNULL(TotalAmount,0) as 'TotalAmount'
        ,ISNULL(SubTotal,0) as 'SubTotal'
        FROM PHRM_StockTxnItems 
        WHERE ISNULL(IsTransferredToACC,0) = 0
            AND CONVERT(DATE, CreatedOn) = CONVERT(DATE, @TransactionDate)
        --Table6: GrDiscountAmount,GrVATAmount,GrCOGSAmount
        SELECT invoice1.InvoiceId
            ,CASE 
                WHEN invoice1.DiscountAmount IS NULL
                    THEN 0
                ELSE CONVERT(DECIMAL(16, 4), invoice1.DiscountAmount)
                END AS GrDiscountAmount
            ,CASE 
                WHEN invoice1.VATAmount IS NULL
                    THEN 0
                ELSE CONVERT(DECIMAL(16, 4), invoice1.VATAmount)
                END AS GrVATAmount
            ,CASE 
                WHEN invoice1.GrCOGS IS NULL
                    THEN 0
                ELSE CONVERT(DECIMAL(16, 4), invoice1.GrCOGS)
                END AS GrCOGSAmount
        FROM (
            SELECT invitem.invid AS InvoiceId
                ,SUM(invitem.GrItemDisAmt) AS DiscountAmount
                ,SUM(invitem.GrItemVATAmt) AS VATAmount
                ,SUM(GrItemTotalAmount) - SUM(invitem.GrItemDisAmt) AS GrCOGS
            FROM (
                SELECT invitm.InvoiceId AS invid
                    ,gri.GrPerItemDisAmt * invitm.Quantity AS GrItemDisAmt
                    ,gri.GrPerItemVATAmt * invitm.Quantity AS GrItemVATAmt
                    ,invitm.GrItemPrice * invitm.Quantity AS GrItemTotalAmount
                FROM PHRM_TXN_InvoiceItems invitm
                JOIN PHRM_GoodsReceiptItems gri ON invitm.GrItemId = gri.GoodReceiptItemId
                ) AS invitem
            JOIN PHRM_TXN_Invoice inv ON invitem.invid = inv.InvoiceId
            WHERE inv.IsTransferredToACC IS NULL
                AND CONVERT(DATE, inv.CreateOn) = CONVERT(DATE, @TransactionDate)
            GROUP BY invid
            ) AS invoice1
        --Table7: Deposit ADD && Deposit Return
        SELECT CreatedOn
        ,TransactionType
        ,DepositId
        ,PatientId
        ,CASE WHEN TransactionType = 'ReturnDeposit' THEN ISNULL(OutAmount,0)
			  ELSE ISNULL(InAmount,0) END AS 'DepositAmount'
        FROM BIL_TXN_Deposit 
        WHERE ISNULL(IsDepositSync,0) = 0 AND CONVERT(DATE, CreatedOn) = CONVERT(DATE, @TransactionDate)
		AND ModuleName = 'Pharmacy'
        --Table8: Credit bill paid
        SELECT SettlementId
            ,SettlementDate
            ,SettlementReceiptNo
            ,ISNULL(CollectionFromReceivable,0) as 'CollectionFromReceivable'
            ,ISNULL(DiscountAmount,0) as 'DiscountAmount'
            ,OrganizationId
            ,ISNULL(PaidAmount,0) as 'PaidAmount'
            ,PatientId
        FROM PHRM_TXN_Settlement 
        WHERE ISNULL(IsTransferredToACC,0) = 0 AND CONVERT(DATE, SettlementDate) = CONVERT(DATE, @TransactionDate)
        SELECT StockTransactionId
        ,ISNULL(CostPrice,0) as 'CostPrice'
        ,ISNULL(InQty,0) as 'InQty'
        ,ISNULL(OutQty,0) as 'OutQty'
        ,CreatedOn
        FROM PHRM_TXN_StockTransaction
        WHERE TransactionType = 'stock-managed-item'
            AND ISNULL(IsTransferedToACC, 0) = 0
            AND CONVERT(DATE, TransactionDate) = CONVERT(DATE, @TransactionDate)
    END
END