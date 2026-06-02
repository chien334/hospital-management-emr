CREATE PROCEDURE [dbo].[SP_PHRM_GetAllInvoiceOfPatientForSettlement]
 @PatientId INT = 0,
 @OrganizationId INT = NULL
AS  

/*
FileName: SP_PHRM_GetAllInvoiceOfPatientForSettlement
Description: To get all the invoices of patiend for settlement by patientID
Remarks: We're returning 4 tables from this StoredProc.
1. patient info
2. Credit Invoices and there Return Information
3. Deposit Information
4. Provisional Information

Change History
S.No. 	UpdatedBy/Date 				Remarks
1. 		Rohit/1,DEC'21 				Created SP to get the settlement details for settlement receipt.
2.      Dev Narayan 7,June'22       Added Credit Organization Filter.
3.		Rohit/10May'23				Pharmacy Deposit Table References changes to Billing Deposit
*/
BEGIN  
	SELECT
		PatientId,
		PatientCode,
		ShortName as PatientName,
		FirstName,
		MiddleName,
		LastName,
		Gender,
		DateOfBirth,
		Address,
		PhoneNumber
	FROM PAT_Patient
	WHERE PatientId=@PatientId

	SELECT 
		PatientId, inv.InvoiceId,
		inv.InvoicePrintId as InvoiceNo,
		Convert(Date,inv.CreateOn) 'InvoiceDate',
		ISNULL(inv.TotalAmount,0) 'SalesAmount', ISNULL(ret.ReturnAmount,0) 'ReturnAmount',
		ISNULL(inv.TotalAmount,0) - ISNULL(ret.ReturnAmount,0) 'NetAmount',
		PHRMReturnIdsCSV

	FROM PHRM_TXN_Invoice inv
	LEFT JOIN (Select InvoiceId, SUM(TotalAmount) 'ReturnAmount',
	STRING_AGG(InvoiceReturnId, ',') 'PHRMReturnIdsCSV'
	FROM PHRM_TXN_InvoiceReturn
	WHERE PatientId=@PatientId
	GROUP BY InvoiceId) ret
	ON inv.InvoiceId=ret.InvoiceId
	WHERE
		inv.PatientId=@PatientId AND
	    inv.OrganizationId = @OrganizationId
		AND
		inv.PaymentMode='credit' AND inv.BilStatus != 'paid'

SELECT 
ISNULL(SUM(ISNULL(Deposit_In,0)),0) Deposit_In,
ISNULL(SUM(ISNULL(Deposit_Out,0)),0) Deposit_Out,
ISNULL(SUM(ISNULL(Deposit_In,0)),0)-ISNULL(SUM(ISNULL(Deposit_Out,0)),0) 'Deposit_Balance'
FROM
(
SELECT PatientId, TransactionType,
CASE WHEN TransactionType='Deposit' THEN InAmount
ELSE 0 END AS 'Deposit_In',
CASE WHEN TransactionType IN('ReturnDeposit','depositdeduct') THEN OutAmount
ELSE 0 END AS 'Deposit_Out'
FROM BIL_TXN_Deposit
WHERE PatientId=@PatientId
) a

SELECT PatientId,
Sum(ISNULL(TotalAmount,0)) 'ProvisionalTotal'
FROM PHRM_TXN_InvoiceItems
WHERE BilItemStatus='provisional'
AND PatientId = @PatientId
GROUP BY PatientId
END