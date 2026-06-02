CREATE PROCEDURE [dbo].[SP_Get_Settlement_Details_By_SettlementId] @SettlementId INT = 0
AS
/*
FileName: SP_Get_Settlement_Details_By_SettlementId 
Description: To get the Settlement Details by settlementId for Duplicate Prints and settlement receipt
Remarks: We're returning 6 tables from this StoredProc.
1. patient info
2. settlement info
3. sales info against current settlement
4. sales return info against current settlement
5. cash discount return against current settlement
6. Deposit info against current settlementChange History
	
Change History
S.No.    UpdatedBy/Date                        Remarks
1.      Krishna/25th,NOV'21                    Created SP to get the settlement details for settlement receipt.   
2.      Dev Narayan/18th,Jan'22                Changed SP to get paidAmount in Table-2 : Settlement Info
3.		Sanjeev/21st,Feb'23					   Add CountryName, CountrySubDivisionName, MunicipalityName, WardNumber in
											   table-1: 
											   patient info
4.		Sanjeev/24th,Feb'23					   Add memebrshipTypeName, SSFPolicyNo (PolicyNo of SSF Patient), PolicyNo
											   (PolicyNo of
											   ECHS Patient)in --table-1: patient info--
											   Add CreditOrganizationName in --table-2: settlement info--
5.      Krishna/21stApril'23				   Remove unnecessary Joins and Selections, Change Deposit Type to 
											   Transaction Type and Amount to InAmount and OutAmount
6.		Krishna/25thApril'23				   Add Pharmacy sales and Returns selection query
7.	    Krishna/15thMay'23					   Remove Inner JOIN BIL_CFG_Scheme On the basis of MembershipTypeId in PAT_Patient table
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
		pat.PatientId,
		pat.ShortName 'PatientName',
		pat.PatientCode 'HospitalNo',
		pat.PhoneNumber 'ContactNo',
		pat.Gender 'Gender',
		pat.DateOfBirth 'DateOfBirth',
		pat.Address 'Address',
		cnty.CountryName 'CountryName',
		subDiv.CountrySubDivisionName 'CountrySubDivisionName',
		munc.MunicipalityName 'MunicipalityName',
		pat.WardNumber 'WardNumber'
		
	FROM 
		PAT_Patient  pat WITH(NOLOCK) 
		--INNER JOIN BIL_CFG_Scheme scheme ON pat.MembershipTypeId = scheme.SchemeId
		INNER JOIN MST_CountrySubDivision subDiv ON pat.CountrySubDivisionId = subDiv.CountrySubDivisionId  
		INNER JOIN MST_Country cnty ON subDiv.CountryId = cnty.CountryId
        LEFT JOIN MST_Municipality munc ON pat.MunicipalityId = munc.MunicipalityId
	WHERE 
		pat.PatientId = @PatientId;

	--table-2: settlement info--
	SELECT
		txn.SettlementId,
		txn.SettlementReceiptNo,
		txn.SettlementDate,
		txn.PaymentMode,
		txn.CreatedBy,
		PaidAmount,
		ISNULL(DiscountAmount,0) 'CashDiscountGiven', --> Change this to 'CashDiscountGiven'
		crOrg.OrganizationName 'CreditOrganizationName'
	FROM 
		BIL_TXN_Settlements txn WITH(NOLOCK)
		LEFT JOIN BIL_MST_Credit_Organization crOrg   
		ON txn.OrganizationId = crOrg.OrganizationId
	WHERE 
		SettlementId = @SettlementId;

	
--table-3: sales--
	SELECT
		CONCAT(txn.InvoiceCode + '-', txn.InvoiceNo) 'ReceiptNo',
		txn.CreatedOn 'ReceiptDate',
		txn.TotalAmount 'Amount'
	FROM 
		BIL_TXN_BillingTransaction txn WITH(NOLOCK)
	WHERE 
		txn.SettlementId = @SettlementId

	UNION ALL

	SELECT
		CONCAT('PH' , txn.InvoicePrintId) 'ReceiptNo',
		txn.CreateOn 'ReceiptDate',
		txn.TotalAmount 'Amount'
	FROM 
		PHRM_TXN_Invoice txn
	WHERE 
		txn.SettlementId = @SettlementId
	
	--table-4: sales return--
	SELECT
		BillReturnId,
		'CR-'+CONVERT(VARCHAR(20),CreditNoteNumber) 'ReceiptNo',
		CONVERT(DATE,CreatedOn) 'ReceiptDate',
		TotalAmount 'Amount'
	FROM 
		BIL_TXN_InvoiceReturn WITH(NOLOCK)
	WHERE 
		ISNULL(SettlementId,0) = @SettlementId 

	UNION ALL

	SELECT
		InvoiceReturnId AS 'BillReturnId',
		'CR-PH'+CONVERT(VARCHAR(20),CreditNoteID) 'ReceiptNo',
		CONVERT(DATE,CreatedOn) 'ReceiptDate',
		TotalAmount 'Amount'
	FROM 
		PHRM_TXN_InvoiceReturn WITH(NOLOCK)
	WHERE 
		ISNULL(SettlementId,0) = @SettlementId 

	--table-5: cash discount return--
	SELECT
		'CR-'+ CONVERT(VARCHAR(20),ret.CreditNoteNumber) 'ReceiptNo',
		ret.CreatedOn 'ReceiptDate',
		sett.DiscountReturnAmount 'CashDiscountReceived' ---> Change this to 'CashDiscountReceived'
	FROM 
		BIL_TXN_Settlements sett WITH(NOLOCK)
		LEFT JOIN BIL_TXN_InvoiceReturn ret WITH(NOLOCK) 
		     ON sett.SettlementId = ret.SettlementId
	WHERE 
		ISNULL(sett.SettlementId,0) = @SettlementId AND 
		ISNULL(sett.DiscountReturnAmount,0)!=0 

	--table-6: Deposit info--
	SELECT
		'DR-'+CONVERT(VARCHAR(20),ReceiptNo) 'ReceiptNo',
		CASE 
			WHEN dep.TransactionType='depositdeduct' THEN 'Deposit Deducted'
			WHEN dep.TransactionType='ReturnDeposit' THEN 'Deposit Returned'
			When dep.TransactionType='Deposit' THEN 'Deposit Received' 
		END AS TransactionType,
		dep.InAmount,
		dep.OutAmount,
		dep.CreatedOn 'ReceiptDate'
	FROM 
		BIL_TXN_Deposit dep
	WHERE 
		dep.SettlementId=@SettlementId
		AND LOWER(TransactionType) IN ('depositdeduct','returndeposit')
	ORDER BY dep.SettlementId
END