/*  
  FileName: [SP_NEPH_GetDialisysPatientListWithBillingItem]   
  Created: 29-Dec-22/Nirmala 
  Description: To Get the Nephrology Patient Detail 
   
  Remarks:     
  History  
  S.No.    Date/User              Change          Remarks  
  1.       29-Dec'22/Nirmala                      Create SP_NEPH_GetDialisysPatientListWithBillingItem for Nursing Nephrology   
 */
CREATE PROCEDURE SP_NEPH_GetDialisysPatientListWithBillingItem
AS
BEGIN
SELECT pat.PatientId
	,pat.PatientCode
	,pat.DialysisCode
	,pat.Gender
	,bti.ItemName
	,bti.RequisitionDate
	,pat.Age
	,pat.DateOfBirth
	,pat.Address
	,pat.PhoneNumber
	,bti.PerformerName
	,ShortName = pat.FirstName + ' ' + ISNULL(pat.MiddleName, ' ') + pat.LastName
FROM PAT_Patient pat
INNER JOIN BIL_TXN_BillingTransactionItems bti ON pat.PatientId = bti.PatientId
INNER JOIN BIL_MST_ServiceDepartment msd ON bti.ServiceDepartmentId = msd.ServiceDepartmentId
WHERE msd.IntegrationName = 'Nephrology'
	AND pat.DialysisCode IS NOT NULL
ORDER BY pat.PatientId DESC;
END