CREATE PROCEDURE [dbo].[SP_BIL_GetAllBillingInfoOfPatientForSettlement] 
	@PatientId INT = 0,
	@OrganizationId INT = NULL
		
AS
/*
FileName: [SP_BIL_GetAllBillingInfoOfPatientForSettlement]
CreatedBy/date: KRISHNA/2021-11-17
Description: To get the billing information of patient for settlement like (credit,deposit,provisional.....)
Change History
S.No.    UpdatedBy/Date                        Remarks
1.		Krishna/2021-11-17					created SP to get the billing information for settlement.
2.		Krishna/2022-02-03					Added Credit Organization Parameter to get organization wise data..
3.		Krishna/2023-04-21					Change DepositType to TransactionType
4.		Krishna/2023-04-24					Add PharmacyCredit Invoices in this list
*/
BEGIN

	SELECT
		PatientID,
		PatientCode AS HospitalNo,
		ShortName AS PatientName,
		Gender,
		DateOfBirth

	FROM PAT_Patient
	WHERE PatientId=@PatientId


	SELECT 
		PatientId, 
		inv.BillingTransactionId AS 'TransactionId',
		inv.InvoiceNo,
		inv.InvoiceCode,
		Convert(Date,inv.CreatedOn) 'InvoiceDate',
		ISNULL(inv.TotalAmount,0) 'SalesAmount', ISNULL(ret.ReturnAmount,0) 'ReturnAmount',
		ISNULL(inv.TotalAmount,0) - ISNULL(ret.ReturnAmount,0) 'NetAmount',
		BillReturnIdsCSV,
		'Billing' AS 'InvoiceOf'

	FROM 
		BIL_TXN_BillingTransaction inv  WITH(NOLOCK)
	LEFT JOIN 
		(SELECT BillingTransactionId, 
		SUM(TotalAmount) 'ReturnAmount',
		STRING_AGG(BillReturnId, ',') 'BillReturnIdsCSV'
	FROM 
		BIL_TXN_InvoiceReturn WITH(NOLOCK)
	WHERE PatientId=@PatientId
	GROUP BY 
		BillingTransactionId) ret ON inv.BillingTransactionId=ret.BillingTransactionId
	WHERE
		inv.OrganizationId = @OrganizationId AND
		inv.PatientId=@PatientId AND
		inv.PaymentMode='credit' and inv.BillStatus != 'paid' 
		and ISNULL(inv.IsInsuranceBilling,0) = 0 --excluding insurances invoices.
	
	UNION ALL

	SELECT 
		PatientId, 
		inv.InvoiceId AS 'TransactionId',
		inv.InvoicePrintId 'InvoiceNo',
		'PH' AS 'InvoiceCode',
		Convert(Date,inv.CreateOn) 'InvoiceDate',
		ISNULL(inv.TotalAmount,0) 'SalesAmount', ISNULL(ret.ReturnAmount,0) 'ReturnAmount',
		ISNULL(inv.TotalAmount,0) - ISNULL(ret.ReturnAmount,0) 'NetAmount',
		BillReturnIdsCSV,
		'Pharmacy' AS 'InvoiceOf'

	FROM 
		PHRM_TXN_Invoice inv WITH(NOLOCK)
	LEFT JOIN 
		(SELECT InvoiceId, 
		SUM(TotalAmount) 'ReturnAmount',
		STRING_AGG(InvoiceReturnId, ',') 'BillReturnIdsCSV'
	FROM 
		PHRM_TXN_InvoiceReturn
	WHERE PatientId=@PatientId
	GROUP BY 
		InvoiceId) ret ON inv.InvoiceId=ret.InvoiceId
	WHERE
		inv.OrganizationId = @OrganizationId AND
		inv.PatientId=@PatientId AND
		inv.PaymentMode='credit' and inv.BilStatus != 'paid' 

	SELECT 
		SUM(ISNULL(Deposit_In,0)) Deposit_In,
		SUM(ISNULL(Deposit_Out,0)) Deposit_Out,
		SUM(ISNULL(Deposit_In,0))-SUM(ISNULL(Deposit_Out,0)) 'Deposit_Balance'
	FROM
	(
		SELECT PatientId, TransactionType,
		CASE WHEN TransactionType='Deposit' THEN InAmount
		ELSE 0 END AS 'Deposit_In',
		CASE WHEN TransactionType IN ('ReturnDeposit','depositdeduct') THEN OutAmount
		ELSE 0 END AS 'Deposit_Out'
		FROM BIL_TXN_Deposit
		WHERE PatientId=@PatientId AND OrganizationOrPatient = 'patient'
	) a

	SELECT 
		PatientId,
		SUM(ISNULL(TotalAmount,0)) 'ProvisionalTotal'
	FROM 
		BIL_TXN_BillingTransactionItems WITH(NOLOCK)
	WHERE LOWER(BillStatus)='provisional'
		AND ISNULL(IsInsurance,0)=0
		AND LOWER(BillingType) != 'inpatient'
		AND PatientId = @PatientId
	GROUP BY PatientId
	END