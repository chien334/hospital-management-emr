CREATE PROCEDURE [dbo].[SP_PHRM_GetSettlementDetailReportOfSelectedPatient] 
    @FromDate DATE,
    @ToDate DATE,
    @PatientId INT = NULL
AS
/*
 FileName: [SP_PHRM_GetSettlementDetailReportOfSelectedPatient] '2021-12-01', '2021-12-07', 31445
 Created: 6Dec'21/Rohit
 Description: To get all the settlement details of a patient.
 Remarks: We need to use this procedure to get all the settlement details of the patient.
 Change History
 S.No.    Date/User              Change          Remarks
 1.	     6Dec'21/Rohit		                   created SP
*/
BEGIN

    --Table 1: PATIENT INFORMATION--
    SELECT
        PatientId,
        ShortName 'PatientName',
        PatientCode,
        Gender,
        DateOfBirth
    FROM
        PAT_Patient
    WHERE
	PatientId = @PatientId

    --Table 2: COLLECTION FROM RECEIVABLE--
    SELECT
        sett.PatientId,
        CONVERT(DATE, sett.SettlementDate) 'SettlementDate',
        sett.SettlementReceiptNo,
        mstStore.Name AS CrdtSettledStoreName,
        s.Name AS CrdtStoreName,
        txn.InvoiceId,
        txn.InvoicePrintId,
        CONVERT(DATE, txn.CreateOn) 'InvoiceDate',
        ISNULL(txn.TotalAmount, 0) 'SalesAmount',
        ISNULL(ret.RetTotalAmount, 0) 'ReturnTotalAmount',
        ISNULL(txn.TotalAmount, 0) - ISNULL(ret.RetTotalAmount, 0) 'Receivable',
        ISNULL(sett.DiscountAmount, 0) 'CashDiscount'
    FROM
        PHRM_TXN_Settlement sett
        INNER JOIN PAT_Patient pat ON sett.PatientId = pat.PatientId
        INNER JOIN PHRM_MST_Store mstStore ON sett.StoreId= mstStore.StoreId
        LEFT JOIN PHRM_TXN_Invoice txn ON sett.SettlementId = txn.SettlementId
        LEFT JOIN PHRM_MST_Store s ON txn.StoreId=s.StoreId
        LEFT JOIN (
	SELECT
            SettlementId,
            InvoiceId,
            SUM(ISNULL(TotalAmount, 0)) 'RetTotalAmount'
        FROM
            PHRM_TXN_InvoiceReturn
        WHERE
	SettlementId IS NOT NULL
        GROUP BY
	SettlementId,
	InvoiceId
	            ) ret ON sett.SettlementId = ret.SettlementId
            AND txn.InvoiceId = ret.InvoiceId
    WHERE
	CONVERT(DATE, sett.CreatedOn) BETWEEN @FromDate AND @ToDate
        AND sett.PatientId = @PatientId
        AND ISNULL(sett.CollectionFromReceivable, 0) !=0
    -- need only settlement


    --Table 3: RETURN TO RECEIVABLE--
    SELECT
        sett.SettlementReceiptNo,
        CONVERT(DATE, sett.CreatedOn) 'SettlementDate',
        ret.CreditNoteID,
        CONVERT(DATE, ret.CreatedOn) 'ReturnDate',
        ISNULL(ret.TotalAmount, 0) 'ReturnTotalAmount',
        ret.ReferenceInvoiceNo,
        ret.InvoiceId,
        ISNULL(sett.DiscountReturnAmount,0) 'DiscountReturnAmount'
    FROM
        PHRM_TXN_Settlement sett
        INNER JOIN PHRM_TXN_InvoiceReturn ret ON sett.SettlementId = ret.SettlementId
        --INNER JOIN PHRM_TXN_Invoice inv ON ret.SettlementId = inv.SettlementId
        --  AND ret.InvoiceId = inv.InvoiceId
    WHERE
	CONVERT(DATE, sett.CreatedOn) BETWEEN @FromDate
	AND @ToDate
        AND sett.PatientId = @PatientId AND sett.CollectionFromReceivable IS NULL AND sett.RefundableAmount IS NULL
       -- AND LOWER(inv.BilStatus) = 'paid'
    -- need only returns done after settlement

    --Table 4: GET CASH DISCOUNT--
    SELECT
        SUM(ISNULL(DiscountAmount, 0)) 'CashDiscount'
    FROM
        PHRM_TXN_Settlement
    WHERE
	CONVERT(DATE, CreatedOn) BETWEEN @FromDate AND @ToDate
        AND PatientId = @PatientId
        AND ISNULL(CollectionFromReceivable, 0) != 0

END