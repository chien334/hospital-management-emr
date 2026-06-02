CREATE PROCEDURE [dbo].[SP_Get_PHRM_Settlement_Details_By_SettlementId] 
@SettlementId INT = 0 
AS
/*
FileName: SP_Get_PHRM_Settlement_Details_By_SettlementId
Description: To get the Settlement Details by settlementId for Duplicate Prints and settlement receipt
Remarks: We're returning 6 tables from this StoredProc.
1. patient info
2. settlement info
3. sales info against current settlement
4. sales return info against current settlement
5. cash discount return against current settlement
6. Deposit info against current settlementChange History

Change History
S.No.      UpdatedBy/Date                          Remarks
1.         Rohit/2nd,DEC'21             Created SP to get the settlement details for settlement receipt.
2.		   Rohit/11Apr'22				SP modified, SettlementId NULL value shoud not be taken as 0.
3.		   Rohit/10May'23				Pharmacy Deposit and Settlement table references changes to Billing Deposit and settlement
4.		   Sanjeev/31st-May'23		    Change DepositType to TransactionType in deposit info
*/
BEGIN
DECLARE @PatientId INT = 0;



--setting value to @PatientId--
SELECT
@PatientId = PatientId
FROM
BIL_TXN_Settlements
WHERE
SettlementId = @SettlementId;



--table-1: patient info--
SELECT
PatientId,
ShortName 'PatientName',
PatientCode,
PhoneNumber,
Gender,
DateOfBirth,
[Address]
FROM
PAT_Patient
WHERE
PatientId = @PatientId;



--table-2: settlement info--
SELECT
SettlementId,
SettlementReceiptNo,
SettlementDate,
PaymentMode,
CreatedBy,
ISNULL(DiscountAmount, 0) 'CashDiscountGiven'
FROM
BIL_TXN_Settlements
WHERE
SettlementId = @SettlementId;



--table-3: sales--
SELECT
txn.InvoicePrintId 'ReceiptNo',
txn.CreateOn 'ReceiptDate',
txn.TotalAmount 'Amount'
FROM
PHRM_TXN_Invoice txn
WHERE
txn.SettlementId = @SettlementId

--table-4: sales return--
SELECT
InvoiceReturnId,
CreditNoteID 'ReceiptNo',
CONVERT(DATE, CreatedOn) 'ReceiptDate',
invRet.TotalAmount 'Amount'
FROM
PHRM_TXN_InvoiceReturn invRet
INNER JOIN PHRM_TXN_Invoice inv ON invRet.InvoiceId= inv.InvoiceId
WHERE inv.SettlementId= @SettlementId

--table-5: cash discount return--
SELECT
'CR-' + CONVERT(
VARCHAR(20),
ret.CreditNoteID
) 'ReceiptNo',
ret.CreatedOn 'ReceiptDate',
sett.DiscountReturnAmount 'CashDiscountReceived'
FROM
BIL_TXN_Settlements sett
LEFT JOIN PHRM_TXN_InvoiceReturn ret ON sett.SettlementId = ret.SettlementId
WHERE sett.SettlementId= @SettlementId
and ISNULL(sett.DiscountReturnAmount, 0)!= 0

--table-6: Deposit info--
SELECT
'DR-' + CONVERT(
VARCHAR(20),
ReceiptNo
) 'ReceiptNo',
CASE WHEN dep.TransactionType = 'depositdeduct' THEN 'Deposit Deducted'
WHEN dep.TransactionType = 'ReturnDeposit' THEN 'Deposit Returned'
When dep.TransactionType = 'Deposit' THEN 'Deposit Received' END AS TransactionType,
dep.OutAmount 'DepositAmount',
dep.CreatedOn 'ReceiptDate'
FROM
BIL_TXN_Deposit dep
WHERE
dep.SettlementId = @SettlementId
AND TransactionType IN (
'depositdeduct', 'ReturnDeposit'
)
ORDER BY
dep.SettlementId 
END