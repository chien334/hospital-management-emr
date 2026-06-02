CREATE PROCEDURE [dbo].[SP_BIL_GetInvoiceDetailsForPrint]  
   @InvoiceNumber INT,   
   @FiscalYearId INT,  
   @BillingTxnIdInput INT=NULL  
AS  
/*  
FileName: SP_BIL_GetInvoiceDetailsForPrint  
Description:   
 * To get PatientInformation, InvoiceInformation, InvoiceItemsInformation,   
  VisitInformation and Deposit Lists for Duplicate Print of all types of Invoices   
  generated from billing [Normal Billing, InsuranceBilling, IP/OP, all..]  
 * Returns Five tables  
Change History  
S.No.    UpdatedBy/Date                        Remarks  
1.      Sud/18May'21                        Initial Draft  
2.      Sud/15Sep'21                        New input parameter BillingTxnId is also passed,   
                                            There are duplicate FiscalYear+InvoiceNumber Combinations in big hospitals having many			     counters..  
										BillingTxnId is unique, so we'll pass that from Client>Server>DB so that we'll get only one record.  
3.    Sud/20Dec'21						 Added With(Nolock) so that this thread doesn't wait to complete other transaction.  
										 Nolock added only in the transaction tables, not required in Master/configuration tables.  
4.    Pratik/27Dec'2021					 Added price category in item select (Used to show in invoice print)  
5.    Dev /30Jan' 2022					 Added Municipality Name in patient info section.  
6.   Krishna/ 25th,Jul'22				 Added PaymentDetails in InvoiceInfo
7.	 Krishna/ 05th,Sept'22				 Add ReceivedAmount in the select Query Of invoiceInfo
8.   Dev/ 11th,Oct'22                    Add SSFPolicyNo in PatientInfo
9.	 Sanjeev/ 15th,Feb'23				 Add WardNumber in PatientInfo
10.	 Sanjeev/ 22nd,Feb'23				 Update condition for selectinig SSFPolicyNo in PatientInfo 
										 (i.e. Select PolicyNo as SSFPolicyNo for SSF Patient)
										 Add Policy Number (Select PolicyNo as PolicyNo for ECHS Patient)
11.	 Krishna/16thMarch'23				 Rename PAT_MAP_PriceCategory to PAT_MAP_PatientSchemes and PAT_CFG_MembershipType to 
										 BIL_CFG_Scheme
12.  Krishna/22ndMarch'23			     Remove Inner JOIN with BIL_CFG_Scheme in Patient Information and add it to Invoice
										 information
13.	 Krishna/21stApril'23				 Change DepositType to TransactionType and Amount to InAmount and OutAmount
14.	 Krishna/1stJune'23					 Added ItemCode,IsCoPayment, and DiscountPercent in Items select
15.	 Krishna/24thJune'23				 Read DepartmentName in Visit Information Select Query
16.	 Krishna/9thAug'23					 Read OtherCurrencyDetail
17.	 Krishna/10thAug'23				     Add BillingInvoiceSummary table
*/  
BEGIN  
 Declare @PatientId INT, @PatientVisitId INT, @BillTxnId INT, @CurrentSchemeId INT
  
IF (ISNULL(@BillingTxnIdInput,0)!=0)  
BEGIN  
 SELECT @PatientId=PatientId, @BillTxnId=BillingTransactionId, @PatientVisitId=PatientVisitId, @CurrentSchemeId = SchemeId  
 FROM BIL_TXN_BillingTransaction WITH(NOLOCK)  
 WHERE BillingTransactionId=@BillingTxnIdInput  
END  
ELSE  
BEGIN  
 SELECT @PatientId=PatientId, @BillTxnId=BillingTransactionId, @PatientVisitId=PatientVisitId, @CurrentSchemeId = SchemeId
 FROM BIL_TXN_BillingTransaction WITH(NOLOCK)  
 WHERE FiscalYearId=@FiscalYearId and InvoiceNo=@InvoiceNumber  
END  
  
  
--Table:1--Patient Information-----  
SELECT 
  pat.PatientId, 
  pat.PatientCode, 
  ShortName,
  Gender, 
  DateOfBirth, 
  Age,  
  pat.CountryId,   
  cont.CountryName,  
  pat.CountrySubDivisionId, 
  pat.WardNumber,
  dist.countrySubDivisionName,  
  pat.ADDRESS,  
  munc.MunicipalityName,  
  pat.PhoneNumber,  
  PANNumber,  
  PatientNameLocal,
  patMap.PolicyNo AS 'PolicyNo'--Select PolicyNo as PolicyNo for ECHS Patient--
  FROM PAT_Patient pat WITH(NOLOCK) 
  INNER JOIN MST_CountrySubDivision dist ON pat.CountrySubDivisionId = dist.CountrySubDivisionId 
  INNER JOIN MST_Country cont ON dist.CountryId = cont.CountryId
  LEFT JOIN MST_Municipality munc ON pat.MunicipalityId = munc.MunicipalityId 
  LEFT JOIN PAT_MAP_PatientSchemes patMap ON pat.PatientId = patMap.PatientId AND patMap.SchemeId = @CurrentSchemeId
  WHERE pat.PatientId = @PatientId
  
--Table:2--Invoice Information-----  
SELECT  txn.InvoiceNo 'InvoiceNumber',  
        txn.InvoiceCode,  
        fy.FiscalYearFormatted+'-'+  txn.InvoiceCode+Convert(VARCHAR(20),txn.InvoiceNo) AS 'InvoiceNumFormatted',  
  txn.CreatedOn 'TransactionDate',  
  txn.FiscalYearId,  
  fy.FiscalYearFormatted AS FiscalYear,  
  txn.PaymentMode,  
  txn.PaymentDetails,  
  txn.BillStatus,  
  txn.TransactionType,  
  txn.InvoiceType,  
  ISNULL(txn.PrintCount,0) 'PrintCount',  
  txn.SubTotal,  
  txn.DiscountAmount,  
  txn.TaxableAmount,  
  txn.NonTaxableAmount,  
  txn.TotalAmount,  
        txn.BillingTransactionId,  
  txn.PaidDate AS 'PaidDate',   
  txn.Tender,  
  txn.Change,  
  txn.Remarks,  
  ISNULL(txn.IsInsuranceBilling,0) AS 'IsInsuranceBilling',  
  txn.ClaimCode,  
  txn.OrganizationId 'CrOrganizationId',  
  crOrg.OrganizationName 'CreditOrganizationName',  
  usr.UserName,  
  cntr.CounterId,  
  cntr.CounterName,  
  txn.LabTypeName,  
  ISNULL(txn.ReceivedAmount,0) AS 'ReceivedAmount',
  txn.PackageId,   
  pkg.BillingPackageName AS 'PackageName',  
  ISNULL(txn.DepositAvailable,0) AS 'DepositAvailable',  
  ISNULL(txn.DepositUsed,0) AS 'DepositUsed',  
  ISNULL(txn.DepositReturnAmount,0) AS 'DepositReturnAmount',  
  ISNULL(txn.DepositBalance,0) AS 'DepositBalance',
  scheme.SchemeId,
  scheme.SchemeName,
  txn.OtherCurrencyDetail
FROM BIL_TXN_BillingTransaction txn WITH(NOLOCK)  
INNER JOIN BIL_CFG_FiscalYears fy  
     ON txn.FiscalYearId = fy.FiscalYearId  
INNER JOIN RBAC_User usr  
    ON txn.CreatedBy = usr.EmployeeId  
  
 INNER JOIN BIL_CFG_Counter cntr  
  ON txn.CounterId=cntr.CounterId
 INNER JOIN BIL_CFG_Scheme scheme
 ON scheme.SchemeId = txn.SchemeId
LEFT JOIN BIL_MST_Credit_Organization crOrg   
    ON txn.OrganizationId = crOrg.OrganizationId  
LEFT JOIN BIL_CFG_Packages pkg  
 ON txn.PackageId = pkg.BillingPackageId  
WHERE BillingTransactionId = @BillTxnId  
  
--Table:3--InvoiceItems Information-----  
SELECT   
BillingTransactionItemId, ServiceDepartmentId, ItemId,  
ServiceDepartmentName,ItemCode, ItemName, Price, Quantity, SubTotal,DiscountPercent, DiscountAmount, TotalAmount,  
PerformerId, PerformerName, item.PrescriberId, CASE WHEN item.PrescriberId IS NULL THEN '' ELSE emp.FullName END AS RequestedByName,  
item.PriceCategory, IsCoPayment  
FROM BIL_TXN_BillingTransactionItems item WITH(NOLOCK)  
LEFT JOIN EMP_Employee emp ON item.PrescriberId = emp.EmployeeId  
WHERE BillingTransactionId = @BillTxnId  
  
--Table:4--Visit Information-----  
SELECT vis.PatientVisitId,  
 vis.VisitCode,  
 vis.PerformerId AS ConsultingDoctorId,  
 vis.PerformerName AS ConsultingDoctor,  
 adm.AdmissionDate,  
 adm.DischargeDate,  
 bedInfo.WardName,  
 bedInfo.BedNumber,  
 bedInfo.BedCode,
 dep.DepartmentName
  
FROM PAT_PatientVisits vis WITH(NOLOCK)  
   INNER JOIN MST_Department dep ON dep.DepartmentId = vis.DepartmentId
   LEFT JOIN ADT_PatientAdmission adm WITH(NOLOCK)  
        ON vis.PatientVisitId=adm.PatientVisitId  
   LEFT JOIN (  
     SELECT TOP (1)  bi.PatientVisitId, ward.WardName, bed.BedNumber, bed.BedCode  
     FROM ADT_TXN_PatientBedInfo  bi WITH(NOLOCK)  
     INNER JOIN ADT_MST_Ward ward   
       ON bi.WardId=ward.WardID  
     INNER JOIN ADT_Bed bed   
       ON bi.BedId=bed.BedID  
     WHERE PatientVisitId=@PatientVisitId  
     ORDER BY PatientBedInfoId DESC  
   )bedInfo  ON vis.PatientVisitId = bedInfo.PatientVisitId  
  
WHERE vis.PatientVisitId = @PatientVisitId  
  
--Table:5--Deposits List -----  
SELECT   
  dep.DepositId, dep.ReceiptNo, fy.FiscalYearFormatted,  
  fy.FiscalYearFormatted+'-DR'+CONVERT(VARCHAR(20),ReceiptNo) 'DepositReceiptNoFormattted',  
  dep.TransactionType, dep.InAmount, dep.OutAmount, dep.CreatedOn, usr.UserName  
FROM BIL_TXN_Deposit dep WITH(NOLOCK)  
 INNER JOIN BIL_CFG_FiscalYears fy ON dep.FiscalYearId=fy.FiscalYearId  
 INNER JOIN RBAC_User usr ON dep.CreatedBy = usr.EmployeeId  
WHERE PatientVisitId=@PatientVisitId  

--Table: 6 BillingInvoiceSummary
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
		 WHERE BillingTransactionId = @BillTxnId) itms
		 INNER JOIN BIL_MST_ServiceDepartment servDep ON itms.ServiceDepartmentId = servDep.ServiceDepartmentId
		 GROUP BY itms.ServiceDepartmentId, itms.ServiceDepartmentName
)grp
END