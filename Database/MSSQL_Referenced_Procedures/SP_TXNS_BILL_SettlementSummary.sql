CREATE PROCEDURE [dbo].[SP_TXNS_BILL_SettlementSummary] @OrganizationId INT NULL 
AS
/*
FileName: SP_TXNS_BILL_SettlementSummary
CreatedBy/date: Deepak,Sud: 24March'20
Description: to get Deposit, Provisional, Credit Total for Settlement Details.
Remarks: 

Change History
S.No.    UpdatedBy/Date                        Remarks
1.        Deepak,Sud/24Apr'20                Provisional issue, EMR-1989
2.		  Krishna 28thNOV'21				 Returned bill populating issue resolved (EMR:4365)
3.		  Krishna 03,Feb,22					 Added OrganizationId Parameter to get the grid data organization wise
4.        sud/Krishna:26Jul'22               OrganizationId check in Return As well.
5.		  Krishna/21stApril'23				 Bring Credit Invoices from BIL_TXN_CreditBillStatus Table
6.		  Krishna/24thApril'23				 Fetch Pharmacy Credits and Provisional Amounts
*/

BEGIN 
	SELECT 
		pat.PatientId, pat.PatientCode, 
		pat.FirstName+' '+ISNULL(pat.MiddleName+' ','')+ pat.LastName 'PatientName', 
		pat.DateOfBirth,
		pat.Gender,		
		(ISNULL(credit.BillCreditTotal,0) + IsNULL(phrmCredits.PhrmCreditTotal, 0)) 'CreditTotal', 
		(CAST(ROUND(ISNULL(prov.BillProvisionalTotal,0),2) as numeric(16,2)) + CAST(ROUND(ISNULL(phrmProv.PhrmProvisionalTotal,0),2) as numeric(16,2)))  'ProvisionalTotal', 
		CAST(ROUND((ISNULL(dep.TotalDeposit,0)- ISNULL(dep.DepositDeduction,0) - ISNULL(dep.DepositReturn,0)),2) as numeric(16,2)) 'DepositBalance',

	CASE WHEN ISNULL(Dep_CreatedOn,'2010-01-01') > ISNULL(Bill_Prov_CreatedOn,'2010-01-01') 
			AND  ISNULL(Dep_CreatedOn,'2010-01-01') > ISNULL(Bill_Inv_CreatedOn,'2010-01-01')
			AND ISNULL(Dep_CreatedOn, '2010-01-01') > ISNULL(Phrm_Inv_CreatedOn, '2010-01-01') 
			AND ISNULL(Dep_CreatedOn,'2010-01-01') > ISNULL(Bill_Prov_CreatedOn,'2010-01-01')  THEN Dep_CreatedOn
		WHEN ISNULL(Bill_Prov_CreatedOn,'2010-01-01') > ISNULL(Dep_CreatedOn,'2010-01-01')  
			AND ISNULL(Bill_Prov_CreatedOn,'2010-01-01') >ISNULL(Bill_Inv_CreatedOn,'2010-01-01')
			AND ISNULL(Bill_Prov_CreatedOn,'2010-01-01') >ISNULL(Phrm_Inv_CreatedOn,'2010-01-01')
			AND ISNULL(Bill_Prov_CreatedOn,'2010-01-01') >ISNULL(Phrm_Prov_CreatedOn,'2010-01-01') THEN Bill_Prov_CreatedOn
		WHEN ISNULL(Phrm_Prov_CreatedOn,'2010-01-01') > ISNULL(Dep_CreatedOn,'2010-01-01')  
			AND ISNULL(Phrm_Prov_CreatedOn,'2010-01-01') >ISNULL(Bill_Inv_CreatedOn,'2010-01-01')
			AND ISNULL(Phrm_Prov_CreatedOn,'2010-01-01') >ISNULL(Phrm_Inv_CreatedOn,'2010-01-01')
			AND ISNULL(Phrm_Prov_CreatedOn,'2010-01-01') >ISNULL(Bill_Prov_CreatedOn,'2010-01-01') THEN Phrm_Prov_CreatedOn
		WHEN ISNULL(Phrm_Inv_CreatedOn,'2010-01-01') > ISNULL(Dep_CreatedOn,'2010-01-01')  
			AND ISNULL(Phrm_Inv_CreatedOn,'2010-01-01') >ISNULL(Bill_Inv_CreatedOn,'2010-01-01')
			AND ISNULL(Phrm_Inv_CreatedOn,'2010-01-01') >ISNULL(Phrm_Prov_CreatedOn,'2010-01-01')
			AND ISNULL(Phrm_Inv_CreatedOn,'2010-01-01') >ISNULL(Bill_Prov_CreatedOn,'2010-01-01') THEN Phrm_Inv_CreatedOn
	ELSE Bill_Inv_CreatedOn END  
	AS   LastTxnDate

--credit.CreatedOnDate
	FROM PAT_Patient pat

	LEFT JOIN
	(
		SELECT 
			txn.PatientId,
			txn.CreditOrganizationId AS  'OrganizationId',
			MAX(txn.CreatedOn) AS 'BillCreatedOnDate' ,
			SUM(NetReceivableAmount) AS 'BillCreditTotal',  --Need to check calculation for CreditTotal 
			MAX(txn.CreatedOn) 'Bill_Inv_CreatedOn' 
		FROM BIL_TXN_CreditBillStatus txn
		JOIN BIL_MST_Credit_Organization org 
		ON txn.CreditOrganizationId = org.OrganizationId
		WHERE txn.SettlementStatus ='pending' AND org.IsClaimManagementApplicable = 0 --do not take claim management applilcable
			AND ISNULL(txn.CreditOrganizationId,0) = @OrganizationId
		GROUP BY txn.PatientId, txn.CreditOrganizationId
	) credit ON pat.PatientId = credit.PatientId 

	LEFT JOIN
	(
		SELECT 
			txnItm.PatientId, 
			SUM(txnItm.TotalAmount) 'BillProvisionalTotal', 
			MAX(CreatedOn) 'Bill_Prov_CreatedOn'   -- sud
		FROM BIL_TXN_BillingTransactionItems txnItm
		WHERE 
			txnItm.BillStatus ='provisional'  -- this takes only provisional
			AND txnItm.BillingType !='inpatient'
			--and txnItm.BillingTransactionId is not null  -- this takes invoice created
			AND ISNULL(txnItm.ReturnStatus,0) != 1 AND ISNULL(txnItm.IsInsurance,0) != 1 

		GROUP BY txnItm.PatientId
	) prov ON pat.PatientId = prov.PatientId

	LEFT JOIN
	( 
		SELECT 
			dep.PatientId,
			SUM(Case WHEN dep.TransactionType='Deposit' THEN ISNULL(dep.InAmount,0) ELSE 0  END ) AS 'TotalDeposit',
			SUM(Case WHEN dep.TransactionType='depositdeduct' THEN ISNULL(dep.OutAmount,0) ELSE 0  END ) AS 'DepositDeduction',
			SUM(Case WHEN dep.TransactionType='ReturnDeposit' THEN ISNULL(dep.OutAmount,0) ELSE 0  END ) AS 'DepositReturn',
			MAX(dep.CreatedOn) 'Dep_CreatedOn'   -- sud
		FROM BIL_TXN_Deposit dep WHERE dep.OrganizationOrPatient = 'patient'
		GROUP BY dep.PatientId
	) dep ON dep.PatientId = pat.PatientId

	LEFT JOIN
	(
		SELECT 
			phrmCredit.PatientId,
			phrmCredit.CreditOrganizationId AS  'OrganizationId',
			MAX(phrmCredit.CreatedOn) AS 'PhrmCreatedOnDate' ,
			SUM(NetReceivableAmount) AS 'PhrmCreditTotal',  --Need to check calculation for CreditTotal 
			MAX(phrmCredit.CreatedOn) 'Phrm_Inv_CreatedOn' 
		FROM PHRM_TXN_CreditBillStatus phrmCredit
		JOIN BIL_MST_Credit_Organization org 
		ON phrmCredit.CreditOrganizationId = org.OrganizationId
		WHERE phrmCredit.SettlementStatus ='pending' AND org.IsClaimManagementApplicable = 0 --do not take claim management applilcable
			AND ISNULL(phrmCredit.CreditOrganizationId,0) = @OrganizationId
		GROUP BY phrmCredit.PatientId, phrmCredit.CreditOrganizationId
	) phrmCredits ON pat.PatientId = phrmCredits.PatientId 

	LEFT JOIN
	(
		SELECT 
			patCons.PatientId, 
			(SUM(ISNULL(patCons.TotalAmount,0)) - SUM(ISNULL(retPatCons.PhrmReturnTotalAmount,0))) AS 'PhrmProvisionalTotal', 
			MAX(CreatedOn) 'Phrm_Prov_CreatedOn'  
		FROM PHRM_TXN_PatientConsumptionItem patCons
		LEFT JOIN (select PatientConsumptionItemId,SUM(TotalAmount) 'PhrmReturnTotalAmount' from PHRM_TXN_PatientConsumptionReturnItem
		GROUP BY PatientConsumptionItemId) retPatCons
		ON retPatCons.PatientConsumptionItemId = patCons.PatientConsumptionItemId
		WHERE 
			patCons.IsFinalize = 0  -- this takes only provisional
			AND patCons.VisitType !='inpatient'
		GROUP BY patCons.PatientId
	) phrmProv ON pat.PatientId = phrmProv.PatientId

	WHERE credit.OrganizationId = @OrganizationId
		AND (ISNULL(credit.BillCreditTotal,0) > 1 
		OR ISNULL(prov.BillProvisionalTotal,0) > 1  
		OR (dep.TotalDeposit-dep.DepositDeduction - dep.DepositReturn) > 1)
		OR (ISNULL(phrmCredits.PhrmCreditTotal,0)) > 1
		OR (ISNULL(phrmProv.PhrmProvisionalTotal,0) > 1)
	ORDER BY LastTxnDate DESC
END