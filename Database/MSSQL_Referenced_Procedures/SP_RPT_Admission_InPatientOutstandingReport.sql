CREATE PROCEDURE SP_RPT_Admission_InPatientOutstandingReport
@Operator VARCHAR(50) = NULL,
@Amount DECIMAL = NULL
AS 
/*  
 FileName: [SP_RPT_Admission_InPatientOutstandingReport]   
 Created: 11-Sept'23/Nirmala  
 Description: To Get the InPatients Info with outstanding Billing Status.  
 Change History  
 S.No.    Date/User              Change          Remarks  
 1.      11-Sept'23/Nirmala                      inital draft   
*/
BEGIN
SELECT * FROM(
SELECT 
	ipVisit.SchemeName AS 'SchemeName',
	ipVisit.PriceCategoryName AS 'PriceCategoryName',
	pat.ShortName AS 'PatientName',
	ipVisit.VisitCode AS 'IPNo',
	ipVisit.PolicyNo,
	pat.PatientCode AS 'HospitalNo',
	pat.PhoneNumber AS 'ContactNo',
	pat.Address AS 'Address',
	pat.DateOfBirth AS 'DateOfBirth',
	CONCAT(DATEDIFF(YEAR, pat.DateOfBirth, ipVisit.VisitDate), 'Y', '/', SUBSTRING(pat.Gender, 0, 2)) AS 'AgeSex',
	ipVisit.WardBed AS 'WardBed',
	ipVisit.AdmissionDate AS 'AdmittedOn',
	DATEDIFF(DAY,ipVisit.AdmissionDate, GETDATE()) AS 'TotalDays',
	ISNULL(itms.ProvisionalServiceTotal,0) AS 'ProvisionalServiceAmount',
	ISNULL(billDetails.CreditServiceTotal,0) 'CreditServiceAmount',
	ISNULL(invoiceDetails.PharmacyCreditTotal,0) 'PharmacyCreditAmount',
	ISNULL(provisionalDetails.PharmacyProvisionalTotal,0) 'PharmacyProvisionalAmount',
	ISNULL(dep.TotalDeposit,0) AS 'DepositBalance',
	ISNULL(itms.ProvisionalServiceTotal, 0) + (ISNULL(billDetails.CreditServiceTotal,0)) +
	(ISNULL(invoiceDetails.PharmacyCreditTotal,0)) +
	ISNULL(provisionalDetails.PharmacyProvisionalTotal,0) 'TotalAmount',
	(ISNULL(itms.ProvisionalServiceTotal, 0) + (ISNULL(billDetails.CreditServiceTotal,0)) +
	(ISNULL(invoiceDetails.PharmacyCreditTotal,0)) +
	ISNULL(provisionalDetails.PharmacyProvisionalTotal,0)) - ISNULL(dep.TotalDeposit,0) AS 'TotalDueAmount',
	ipVisit.CareOfPersonName 'CarePersonName',
	ipVisit.CareOfPersonPhoneNo 'CarePersonContact'
from PAT_Patient pat
INNER JOIN (SELECT 
			adm.PatientId, adm.PatientVisitId, adm.AdmissionDate, visit.VisitDate, adm.CareOfPersonName,adm.CareOfPersonPhoneNo,visit.VisitCode,
			scheme.SchemeName, priceCat.PriceCategoryName,patScheme.PolicyNo,
			CONCAT(wardBedInfo.WardName, '/', wardBedInfo.BedCode) AS 'WardBed'
			FROM (SELECT VisitCode, VisitDate, PatientVisitId, PatientId, SchemeId, PriceCategoryId
					FROM PAT_PatientVisits WHERE VisitType = 'inpatient') visit 
			INNER JOIN (SELECT PatientId,PatientVisitId, AdmissionDate, CareOfPersonName, CareOfPersonPhoneNo 
						FROM ADT_PatientAdmission 
						WHERE DischargeDate IS NULL) adm ON visit.PatientVisitId = adm.PatientVisitId 
			INNER JOIN BIL_CFG_Scheme scheme ON scheme.SchemeId = visit.SchemeId
			INNER JOIN PAT_MAP_PatientSchemes patScheme ON patScheme.SchemeId = scheme.SchemeId AND patScheme.LatestPatientVisitId = visit.PatientVisitId
			INNER JOIN BIL_CFG_PriceCategory priceCat ON priceCat.PriceCategoryId = visit.PriceCategoryId
			OUTER APPLY (SELECT ward.WardName,bed.BedCode FROM 
					(SELECT TOP(1) BedId, WardId FROM ADT_TXN_PatientBedInfo 
					WHERE PatientVisitId = adm.PatientVisitId ORDER BY PatientBedInfoId DESC) bedInfo
					INNER JOIN ADT_Bed bed ON bedInfo.BedId = bed.BedID
					INNER JOIN ADT_MST_Ward ward ON bedInfo.WardId = ward.WardID) wardBedInfo
			) ipVisit ON ipVisit.PatientId = pat.PatientId
INNER JOIN (SELECT PatientVisitId, PatientId, SUM(TotalAmount) AS 'ProvisionalServiceTotal'
				FROM BIL_TXN_BillingTransactionItems WHERE BillStatus = 'provisional'
			GROUP BY PatientVisitId, PatientId) itms 
		ON ipVisit.PatientVisitId = itms.PatientVisitId
LEFT JOIN (
		SELECT bilItems.PatientId, bilItems.PatientVisitId,
		SUM(bilItems.TotalAmount - ISNULL(bilRetItems.ReturnedTotalAmount,0)) 'CreditServiceTotal' 
		FROM BIL_TXN_BillingTransactionItems  bilItems
		LEFT JOIN (SELECT BillingTransactionItemId,SUM(RetTotalAmount) AS 'ReturnedTotalAmount' 
					FROM BIL_TXN_InvoiceReturnItems 
					GROUP BY BillingTransactionItemId) bilRetItems 
					ON bilItems.BillingTransactionItemId = bilRetItems.BillingTransactionItemId
		WHERE bilItems.BillStatus='unpaid'
		GROUP BY bilItems.PatientId, bilItems.PatientVisitId) billDetails 
		ON ipVisit.PatientVisitId = billDetails.PatientVisitId
LEFT JOIN (SELECT PatientVisitId, (SUM(InAmount) - SUM(OutAmount)) AS 'TotalDeposit' 
			FROM BIL_TXN_Deposit GROUP BY PatientVisitId) dep ON dep.PatientVisitId = ipVisit.PatientVisitId
LEFT JOIN (
		SELECT invItems.PatientId, invItems.PatientVisitId,
		SUM(invItems.TotalAmount - ISNULL(invRetItems.ReturnedTotalAmount,0)) 'PharmacyCreditTotal' 
		FROM PHRM_TXN_InvoiceItems  invItems
			LEFT JOIN (SELECT InvoiceItemId,SUM(TotalAmount) AS 'ReturnedTotalAmount'
				FROM PHRM_TXN_InvoiceReturnItems  
				GROUP BY InvoiceItemId) invRetItems ON invItems.InvoiceItemId = invRetItems.InvoiceItemId
		WHERE invItems.BilItemStatus='unpaid'
		GROUP BY invItems.PatientId, invItems.PatientVisitId) invoiceDetails 
		ON ipVisit.PatientVisitId = invoiceDetails.PatientVisitId
LEFT JOIN (
		  SELECT invItems.PatientId, invItems.PatientVisitId,
		  SUM(invItems.TotalAmount) 'PharmacyProvisionalTotal' 
		  FROM PHRM_TXN_InvoiceItems  invItems
		  WHERE invItems.BilItemStatus='provisional' 
		  GROUP BY invItems.PatientId, invItems.PatientVisitId) provisionalDetails 
		  ON ipVisit.PatientVisitId = provisionalDetails.PatientVisitId
)result
WHERE ((@Operator = 'LessThanOrEqualsTo' AND result.TotalDueAmount <= @Amount) 
		OR (@Operator = 'GreaterThanOrEqualsTo' AND result.TotalDueAmount >= @Amount)
	    OR  @Operator IS NULL
	    OR @Amount IS NULL)
END