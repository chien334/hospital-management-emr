CREATE OR REPLACE FUNCTION sp_acc_getpharmacytransactions(
    p_transactiondate DATE,
    p_hospitalid INT
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
    ref3 refcursor := 'cursor3';
    ref4 refcursor := 'cursor4';
    ref5 refcursor := 'cursor5';
    ref6 refcursor := 'cursor6';
    ref7 refcursor := 'cursor7';
    ref8 refcursor := 'cursor8';
    ref9 refcursor := 'cursor9';
BEGIN
    /************************************************************************
    filename: "sp_acc_getpharmacytransactions"
    change history
    s.no.    updatedby/date                        remarks
    1       ajay/07jul'19                       getting GrDiscountAmount,GrVATAmount,GrCOGSAmount
    2.      Vikas 11th Aug 2020                 replaced parameter v_fromdate and v_todate into p_transactiondate
    3.      Dev Narayan 24th May 2022           Added deposit and settlement scenerio
    4.      Dev Narayan 27th May 2022           Added Pharmacy stock adjustment scenerio.
    5.      DevN/19th May 23                    Get Data from BIL_TXN_Deposit Table for pharmacy deposit transactions.
    *************************************************************************/
    BEGIN
        --IF(v_fromdate IS NOT NULL AND v_todate IS NOT NULL) 
        BEGIN
            --Table1: CashInvoice
            OPEN ref1 FOR SELECT InvoiceId
                ,PatientId
                ,COALESCE(SubTotal, 0) AS "SubTotal"
                ,COALESCE(DiscountAmount, 0) AS "DiscountAmount"
                ,COALESCE(VATAmount, 0) AS "VATAmount"
                ,COALESCE(TotalAmount, 0) AS "TotalAmount"
                ,PaymentMode
                ,OrganizationId
                ,CreateOn
            FROM PHRM_TXN_Invoice 
            WHERE COALESCE(IsTransferredToACC,0) = 0
                AND (CreateOn)::DATE = (p_transactiondate)::DATE;
        RETURN NEXT ref1;
            --Table2: CashInvoiceReturn
            OPEN ref2 FOR SELECT InvoiceReturnId
                ,PatientId
                ,COALESCE(SubTotal, 0) AS "SubTotal"
                ,COALESCE(DiscountAmount, 0) AS "DiscountAmount"
                ,COALESCE(VATAmount, 0) AS "VATAmount"
                ,COALESCE(TotalAmount, 0) AS "TotalAmount"
                ,CreatedOn
                ,PaymentMode
                ,OrganizationId
            FROM PHRM_TXN_InvoiceReturn 
            WHERE COALESCE(IsTransferredToACC,0) = 0
                AND (CreatedOn)::DATE = (p_transactiondate)::DATE;
        RETURN NEXT ref2;
            --Table3: goodsReceipt
            OPEN ref3 FOR SELECT CreatedOn
                ,SupplierId
                ,TransactionType
                ,COALESCE(TotalAmount,0) AS "TotalAmount"
                ,COALESCE(SubTotal,0) AS "SubTotal"
                ,COALESCE(VATAmount,0) AS "VATAmount"
                ,COALESCE(DiscountAmount, 0) AS "DiscountAmount"
                ,GoodReceiptId
            FROM PHRM_GoodsReceipt 
            WHERE COALESCE(IsTransferredToACC,0) = 0
                AND IsCancel = 0
                AND (CreatedOn)::DATE = (p_transactiondate)::DATE;
        RETURN NEXT ref3;
            --Table4: writeoff
            OPEN ref4 FOR SELECT WriteOffId
            ,COALESCE(SubTotal,0) AS "SubTotal"
            ,COALESCE(DiscountAmount,0) AS "DiscountAmount"
            ,COALESCE(VATAmount,0) AS "VATAmount"
            ,COALESCE(TotalAmount,0) AS "TotalAmount"
            ,CreatedOn
            FROM PHRM_WriteOff
            WHERE COALESCE(IsTransferredToACC,0) = 0
                AND (CreatedOn)::DATE = (p_transactiondate)::DATE;
        RETURN NEXT ref4;
            --Table5: dispatchToDept && dispatchToDeptRet
            OPEN ref5 FOR SELECT StockTxnItemId
            ,TransactionType
            ,CreatedOn
            ,COALESCE(TotalAmount,0) AS "TotalAmount"
            ,COALESCE(SubTotal,0) AS "SubTotal"
            FROM PHRM_StockTxnItems 
            WHERE COALESCE(IsTransferredToACC,0) = 0
                AND (CreatedOn)::DATE = (p_transactiondate)::DATE;
        RETURN NEXT ref5;
            --Table6: GrDiscountAmount,GrVATAmount,GrCOGSAmount
            OPEN ref6 FOR SELECT invoice1.InvoiceId
                ,CASE 
                    WHEN invoice1.DiscountAmount IS NULL
                        THEN 0
                    ELSE (invoice1.DiscountAmount)::DECIMAL(16, 4)
                    END AS GrDiscountAmount
                ,CASE 
                    WHEN invoice1.VATAmount IS NULL
                        THEN 0
                    ELSE (invoice1.VATAmount)::DECIMAL(16, 4)
                    END AS GrVATAmount
                ,CASE 
                    WHEN invoice1.GrCOGS IS NULL
                        THEN 0
                    ELSE (invoice1.GrCOGS)::DECIMAL(16, 4)
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
                    AND (inv.CreateOn)::DATE = (p_transactiondate)::DATE
                GROUP BY invid
                ) AS invoice1;
        RETURN NEXT ref6;
            --Table7: Deposit ADD && Deposit Return
            OPEN ref7 FOR SELECT CreatedOn
            ,TransactionType
            ,DepositId
            ,PatientId
            ,CASE WHEN TransactionType = 'returndeposit' THEN COALESCE(OutAmount,0)
    			  ELSE COALESCE(InAmount,0) END AS "DepositAmount"
            FROM BIL_TXN_Deposit 
            WHERE COALESCE(IsDepositSync,0) = 0 AND (CreatedOn)::DATE = (p_transactiondate)::DATE
    		AND ModuleName = 'pharmacy';
        RETURN NEXT ref7;
            --Table8: Credit bill paid
            OPEN ref8 FOR SELECT SettlementId
                ,SettlementDate
                ,SettlementReceiptNo
                ,COALESCE(CollectionFromReceivable,0) AS "CollectionFromReceivable"
                ,COALESCE(DiscountAmount,0) AS "DiscountAmount"
                ,OrganizationId
                ,COALESCE(PaidAmount,0) AS "PaidAmount"
                ,PatientId
            FROM PHRM_TXN_Settlement 
            WHERE COALESCE(IsTransferredToACC,0) = 0 AND (SettlementDate)::DATE = (p_transactiondate)::DATE;
        RETURN NEXT ref8;
            OPEN ref9 FOR SELECT StockTransactionId
            ,COALESCE(CostPrice,0) AS "CostPrice"
            ,COALESCE(InQty,0) AS "InQty"
            ,COALESCE(OutQty,0) AS "OutQty"
            ,CreatedOn
            FROM PHRM_TXN_StockTransaction
            WHERE TransactionType = 'stock-managed-item'
                and coalesce(istransferedtoacc, 0) = 0
                and (transactiondate)::date = (p_transactiondate)::date;
        return next ref9;
        end;
    end;
END;
$$ LANGUAGE plpgsql;