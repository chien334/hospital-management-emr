CREATE PROCEDURE [dbo].[SP_BIL_DischargeStatement] 
	 @PatientId INT = NULL
	,@DischargeStatementId INT = NULL
	,@PatientVisitId INT = NULL
AS
/*
FileName: [SP_BIL_DischargeStatement]
CreatedBy/date: Rohit/1Mar'23
Description: To get the discharge statement details 
			 Table 1: PatientInformation
			 Table 2: InvoiceInformation
			 Table 3: InvoiceItems
			 Table 4: VisitInformation
			 Table 5: DepositLists
			 Table 6: PharmacyInvoiceItems
			 Table 7: DischargeDetails
			 Table 8: BillingSummaryViewUsingServiceDepartment
			 Table 9: PharmacySummaryView
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Rohit/28Feb'23                        created the script
2		Rohit/24Apr'23						  PAT_MAP_PriceCategory ->PAT_MAP_PatientSchemes, PAT_CFG_MembershipType 
											  Table -> BIL_CFG_Scheme
3		Krishna/27thApril'23				  Change DepositType to TransactionType and Segregate Amount to InAmount
											  And OutAmount
4		Krishna/15thJuly'23					  Read ServiceCategoryName,ServiceCategoryCode and IntegrationItemId 
											  in InvoiceItems
5	    Krishna/9thAug'23				      Read OtherCurrencyDetail
6	    Krishna/10thAug'23				      Add BillingSummary and PharmacySummary tables
7		Krishna/13thOct'23					  Read IsCoPayment for Items
*/
BEGIN
	DECLARE @BillingTransactionId INT = NULL

	SELECT TOP 1 @BillingTransactionId = txnitm.BillingTransactionId
	FROM BIL_TXN_BillingTransaction txn WITH (NOLOCK)
	INNER JOIN BIL_TXN_BillingTransactionItems txnitm ON txn.BillingTransactionId = txnitm.BillingTransactionId
	WHERE txnitm.DischargeStatementId = @DischargeStatementId

--Table 1: PatientInformation
SELECT 
		 pat.PatientId
		,pat.PatientCode
		,ShortName
		,Gender
		,DateOfBirth
		,Age
		,pat.CountryId
		,cont.CountryName
		,pat.CountrySubDivisionId
		,dist.CountrySubDivisionName
		,pat.Address
		,munc.MunicipalityName
		,pat.PhoneNumber
		,memb.SchemeId
		,memb.SchemeName
		,PANNumber
		,PatientNameLocal
		,Ins_NshiNumber
		,patMapScheme.PolicyNo AS 'PolicyNo'
FROM (SELECT PatientId, PatientCode, ShortName, Gender, DateOfBirth, Age, CountryId, CountrySubDivisionId, Address,
			 PhoneNumber, PANNumber, PatientNameLocal, Ins_NshiNumber, MunicipalityId
			FROM PAT_Patient WITH(NOLOCK) WHERE PatientId = @PatientId) pat 
INNER JOIN (SELECT * FROM PAT_PatientVisits WITH(NOLOCK) WHERE PatientVisitId = @PatientVisitId) patVisit 
			ON pat.PatientId = patVisit.PatientId
INNER JOIN BIL_CFG_Scheme memb ON patVisit.SchemeId = memb.SchemeId
INNER JOIN MST_CountrySubDivision dist ON pat.CountrySubDivisionId = dist.CountrySubDivisionId
INNER JOIN MST_Country cont ON dist.CountryId = cont.CountryId
LEFT JOIN MST_Municipality munc ON pat.MunicipalityId = munc.MunicipalityId
LEFT JOIN PAT_MAP_PatientSchemes patMapScheme 
			On patMapScheme.SchemeId = patVisit.SchemeId AND patMapScheme.PatientId = patVisit.PatientId

--Table 2: InvoiceInformation
SELECT txn.InvoiceNo 'InvoiceNumber'
		,txn.InvoiceCode
		,fy.FiscalYearFormatted + '-' + txn.InvoiceCode + Convert(VARCHAR(20), txn.InvoiceNo) AS 'InvoiceNumFormatted'
		,txn.CreatedOn 'TransactionDate'
		,txn.FiscalYearId
		,fy.FiscalYearFormatted AS FiscalYear
		,txn.PaymentMode
		,txn.PaymentDetails
		,txn.BillStatus
		,txn.TransactionType
		,txn.InvoiceType
		,ISNULL(txn.PrintCount, 0) 'PrintCount'
		,txn.SubTotal
		,txn.DiscountAmount
		,txn.TaxableAmount
		,txn.NonTaxableAmount
		,txn.TotalAmount
		,txn.BillingTransactionId
		,txn.PaidDate AS 'PaidDate'
		,txn.Tender
		,txn.Change
		,txn.Remarks
		,ISNULL(txn.IsInsuranceBilling, 0) AS 'IsInsuranceBilling'
		,txn.ClaimCode
		,txn.OrganizationId 'CrOrganizationId'
		,crOrg.OrganizationName 'CrOrganizationName'
		,usr.UserName
		,cntr.CounterId
		,cntr.CounterName
		,txn.LabTypeName
		,ISNULL(txn.ReceivedAmount, 0) AS 'ReceivedAmount'
		,txn.PackageId
		,pkg.BillingPackageName AS 'PackageName'
		,ISNULL(txn.DepositAvailable, 0) AS 'DepositAvailable'
		,ISNULL(txn.DepositUsed, 0) AS 'DepositUsed'
		,ISNULL(txn.DepositReturnAmount, 0) AS 'DepositReturnAmount'
		,ISNULL(txn.DepositBalance, 0) AS 'DepositBalance'
		,txn.OtherCurrencyDetail
FROM (SELECT InvoiceNo, InvoiceCode, CreatedOn, FiscalYearId, PaymentMode, PaymentDetails, BillStatus, TransactionType, InvoiceType,
			 PrintCount, SubTotal, DiscountAmount, TaxableAmount, NonTaxableAmount, TotalAmount, BillingTransactionId, PaidDate, 
			 Tender, Change, Remarks, IsInsuranceBilling, ClaimCode, OrganizationId, LabTypeName, ReceivedAmount, PackageId,
			 DepositAvailable, DepositUsed, DepositReturnAmount, DepositBalance, OtherCurrencyDetail, CreatedBy, CounterId
	  FROM BIL_TXN_BillingTransaction WITH(NOLOCK) WHERE BillingTransactionId = @BillingTransactionId) txn 
INNER JOIN BIL_CFG_FiscalYears fy ON txn.FiscalYearId = fy.FiscalYearId
INNER JOIN RBAC_User usr ON txn.CreatedBy = usr.EmployeeId
INNER JOIN BIL_CFG_Counter cntr ON txn.CounterId = cntr.CounterId
LEFT JOIN BIL_MST_Credit_Organization crOrg ON txn.OrganizationId = crOrg.OrganizationId
LEFT JOIN BIL_CFG_Packages pkg ON txn.PackageId = pkg.BillingPackageId

--Table 3: InvoiceItems
SELECT BillingTransactionItemId
		,item.ServiceDepartmentId
		,item.ItemCode
		,item.IntegrationItemId
		,item.ItemId
		,ServiceDepartmentName
		,item.ItemName
		,item.IsCoPayment
		,Price
		,Quantity
		,SubTotal
		,DiscountAmount
		,TotalAmount
		,PerformerId
		,PerformerName
		,item.PrescriberId
		,CASE 
			WHEN item.PrescriberId IS NULL
				THEN ''
			ELSE emp.FullName
			END AS RequestedByName
		,item.PriceCategory
		,item.CreatedOn 'BillDate'
		,servCat.ServiceCategoryCode
		,servCat.ServiceCategoryName
FROM (SELECT BillingTransactionItemId,ServiceDepartmentId, ServiceDepartmentName,
			ItemCode,ItemName,IntegrationItemId,ItemId,Price, Quantity, SubTotal, DiscountAmount,
			TotalAmount, PerformerId, PerformerName, PrescriberId, ServiceItemId, PriceCategory, CreatedOn, IsCoPayment
			FROM BIL_TXN_BillingTransactionItems WITH (NOLOCK)
		WHERE BillingTransactionId = @BillingTransactionId) item 
INNER JOIN BIL_MST_ServiceItem mstServItm on item.ServiceItemId = mstServItm.ServiceItemId
LEFT JOIN BIL_MST_ServiceCategory servCat on mstServItm.ServiceCategoryId = servCat.ServiceCategoryId
LEFT JOIN EMP_Employee emp ON item.PrescriberId = emp.EmployeeId
	
--Table 4: VisitInformation
SELECT vis.PatientVisitId
		,vis.VisitCode
		,vis.PerformerId AS ConsultingDoctorId
		,vis.PerformerName AS ConsultingDoctor
		,adm.AdmissionDate
		,adm.DischargeDate
		,bedInfo.WardName
		,bedInfo.BedNumber
		,bedInfo.BedCode
		,vis.VisitType
FROM (SELECT PatientVisitId, VisitCode, PerformerId, PerformerName, VisitType 
	  FROM PAT_PatientVisits WITH(NOLOCK) WHERE PatientVisitId = @PatientVisitId) vis 
LEFT JOIN ADT_PatientAdmission adm WITH(NOLOCK) ON vis.PatientVisitId = adm.PatientVisitId
LEFT JOIN (SELECT TOP (1) bi.PatientVisitId,ward.WardName,bed.BedNumber,bed.BedCode
		    FROM (SELECT WardId, BedId,PatientVisitId,PatientBedInfoId
				  FROM ADT_TXN_PatientBedInfo WITH(NOLOCK) WHERE PatientVisitId = @PatientVisitId) bi
		    INNER JOIN ADT_MST_Ward ward ON bi.WardId = ward.WardID
		    INNER JOIN ADT_Bed bed ON bi.BedId = bed.BedID
		    ORDER BY PatientBedInfoId DESC
		) bedInfo ON vis.PatientVisitId = bedInfo.PatientVisitId

--Table 5: DepositLists
SELECT dep.DepositId
		,dep.ReceiptNo
		,fy.FiscalYearFormatted
		,fy.FiscalYearFormatted + '-DR' + CONVERT(VARCHAR(20), ReceiptNo) 'DepositReceiptNoFormattted'
		,dep.TransactionType
		,dep.InAmount
		,dep.OutAmount
		,dep.CreatedOn
		,usr.UserName
FROM (SELECT DepositId, ReceiptNo, TransactionType, InAmount, OutAmount, CreatedOn, CreatedBy, FiscalYearId
	  FROM BIL_TXN_Deposit WITH (NOLOCK) WHERE PatientVisitId = @PatientVisitId) dep 
INNER JOIN BIL_CFG_FiscalYears fy ON dep.FiscalYearId = fy.FiscalYearId
INNER JOIN RBAC_User usr ON dep.CreatedBy = usr.EmployeeId

--Table 6: PharmacyInvoiceItems
SELECT invitm.CreatedOn 'BillDate'
		,invitm.ItemId
		,invitm.ItemName
		,itm.ItemCode
		,invitm.ExpiryDate
		,invitm.BatchNo
		,Quantity
		,SalePrice
		,SubTotal
		,TotalDisAmt
		,VATAmount
		,TotalAmount
FROM (SELECT ItemId, ItemName, ExpiryDate,BatchNo,Quantity, SalePrice, SubTotal, TotalDisAmt, VATAmount, TotalAmount, CreatedOn
		FROM PHRM_TXN_InvoiceItems WITH(NOLOCK) WHERE DischargeStatementId = @DischargeStatementId) invitm 
INNER JOIN PHRM_MST_Item itm ON invitm.ItemId = itm.ItemId
	
--Table 7: DischargeDetails
SELECT DischargeStatementId
		,StatementDate
		,StatementNo
		,StatementTime
FROM BIL_TXN_DischargeStatement
WHERE DischargeStatementId = @DischargeStatementId

--Table 8: BillingSummaryViewUsingServiceDepartment
SELECT
	grp.GroupName,
	grp.SubTotal,
	grp.DiscountAmount,
	grp.TotalAmount
FROM (
SELECT 
	itms.ServiceDepartmentName AS 'GroupName', 
	CONVERT(DECIMAL(16,4),SUM(ISNULL(itms.SubTotal, 0))) AS 'SubTotal',
	CONVERT(DECIMAL(16,4),SUM(ISNULL(itms.DiscountAmount, 0))) AS 'DiscountAmount', 
	CONVERt(DECIMAL(16,4),SUM(ISNULL(itms.TotalAmount, 0))) AS 'TotalAmount' 
FROM 
		(SELECT ServiceDepartmentId, ServiceDepartmentName,BillingTransactionItemId,
			  SubTotal, DiscountAmount, TotalAmount FROM BIL_TXN_BillingTransactionItems 
		 WHERE BillingTransactionId = @BillingTransactionId) itms
		 INNER JOIN BIL_MST_ServiceDepartment servDep ON itms.ServiceDepartmentId = servDep.ServiceDepartmentId
		 GROUP BY itms.ServiceDepartmentId, itms.ServiceDepartmentName
)grp

--Table 9: PharmacySummaryView
SELECT 
	'Pharmacy Items' AS 'GroupName',
	CONVERT(DECIMAL(16,4),SUM(ISNULL(SubTotal,0))) AS 'SubTotal',
	CONVERT(DECIMAL(16,4),SUM(ISNULL(TotalDisAmt,0))) AS 'DiscountAmount',
	CONVERT(DECIMAL(16,4),SUM(ISNULL(TotalAmount, 0))) AS 'TotalAmount'
FROM PHRM_TXN_InvoiceItems WITH(NOLOCK) 
WHERE DischargeStatementId = @DischargeStatementId
GROUP BY DischargeStatementId
END