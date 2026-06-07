CREATE OR REPLACE FUNCTION sp_get_phrm_settlement_details_by_settlementid(
    p_settlementid INT DEFAULT 0
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
    ref3 refcursor := 'cursor3';
    ref4 refcursor := 'cursor4';
    ref5 refcursor := 'cursor5';
    ref6 refcursor := 'cursor6';
    v_patientid INT := 0;
BEGIN
    /*
    filename: sp_get_phrm_settlement_details_by_settlementid
    description: to get the settlement details by settlementid for duplicate prints and settlement receipt
    remarks: we're returning 6 tables from this StoredProc.
    1. patient info
    2. settlement info
    3. sales info against current settlement
    4. sales return info against current settlement
    5. cash discount return against current settlement
    6. Deposit info against current settlementChange History
    
    Change History
    S.No.      UpdatedBy/Date                          Remarks
    1.         Rohit/2nd,DEC'21             created sp to get the settlement details for settlement receipt.
    2.		   rohit/11apr'22				SP modified, SettlementId NULL value shoud not be taken as 0.
    3.		   Rohit/10May'23				pharmacy deposit and settlement table references changes to billing deposit and settlement
    4.		   sanjeev/31st-may'23		    Change DepositType to TransactionType in deposit info
    */
    BEGIN
    
    
    
    
    --setting value to v_patientid--
    SELECT PatientId INTO v_patientid FROM
    BIL_TXN_Settlements
    WHERE
    SettlementId = p_settlementid;
    
    
    
    --table-1: patient info--
    OPEN ref1 FOR SELECT
    PatientId,
    ShortName AS "PatientName",
    PatientCode,
    PhoneNumber,
    Gender,
    DateOfBirth,
    "Address"
    FROM
    PAT_Patient
    WHERE
    PatientId = v_patientid;
        RETURN NEXT ref1;
    
    
    
    --table-2: settlement info--
    OPEN ref2 FOR SELECT
    SettlementId,
    SettlementReceiptNo,
    SettlementDate,
    PaymentMode,
    CreatedBy,
    COALESCE(DiscountAmount, 0) AS "CashDiscountGiven"
    FROM
    BIL_TXN_Settlements
    WHERE
    SettlementId = p_settlementid;
        RETURN NEXT ref2;
    
    
    
    --table-3: sales--
    OPEN ref3 FOR SELECT
    txn.InvoicePrintId AS "ReceiptNo",
    txn.CreateOn AS "ReceiptDate",
    txn.TotalAmount AS "Amount"
    FROM
    PHRM_TXN_Invoice txn
    WHERE
    txn.SettlementId = p_settlementid;
        RETURN NEXT ref3;
    
    --table-4: sales return--
    OPEN ref4 FOR SELECT
    InvoiceReturnId,
    CreditNoteID AS "ReceiptNo",
    (CreatedOn)::DATE AS "ReceiptDate",
    invRet.TotalAmount AS "Amount"
    FROM
    PHRM_TXN_InvoiceReturn invRet
    INNER JOIN PHRM_TXN_Invoice inv ON invRet.InvoiceId= inv.InvoiceId
    WHERE inv.SettlementId= p_settlementid;
        RETURN NEXT ref4;
    
    --table-5: cash discount return--
    OPEN ref5 FOR SELECT
    'cr-' || (ret.CreditNoteID)::VARCHAR AS "ReceiptNo",
    ret.CreatedOn AS "ReceiptDate",
    sett.DiscountReturnAmount AS "CashDiscountReceived"
    FROM
    BIL_TXN_Settlements sett
    LEFT JOIN PHRM_TXN_InvoiceReturn ret ON sett.SettlementId = ret.SettlementId
    WHERE sett.SettlementId= p_settlementid
    and COALESCE(sett.DiscountReturnAmount, 0)!= 0;
        RETURN NEXT ref5;
    
    --table-6: Deposit info--
    OPEN ref6 FOR SELECT
    'dr-' || (ReceiptNo)::VARCHAR AS "ReceiptNo",
    CASE WHEN dep.TransactionType = 'depositdeduct' THEN 'deposit deducted'
    WHEN dep.TransactionType = 'returndeposit' THEN 'deposit returned'
    When dep.TransactionType = 'deposit' THEN 'deposit received' END AS TransactionType,
    dep.OutAmount AS "DepositAmount",
    dep.CreatedOn AS "ReceiptDate"
    FROM
    BIL_TXN_Deposit dep
    WHERE
    dep.SettlementId = p_settlementid
    AND TransactionType IN (
    'depositdeduct', 'returndeposit'
    )
    order by
    dep.settlementid;
        return next ref6; 
    end;
END;
$$ LANGUAGE plpgsql;