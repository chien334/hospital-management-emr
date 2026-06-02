CREATE PROCEDURE SP_Marketing_Referral_Detail_Report
    @FromDate DATE = NULL,
    @ToDate DATE = NULL,
    @ReferringPartyId INT = NULL
AS
/* 
exec [SP_Marketing_Referral_Detail_Report] '2015-01-01', '2023-08-13'
Change History
S.No.    UpdatedBy/Date                        Remarks
1        Bibek/2023-08-13                   Created initial script 
*/
BEGIN
 SELECT   
	RC.InvoiceNoFormatted,
    RC.InvoiceDate AS 'InvoiceDate',
    pat.ShortName AS 'PatientName',
    pat.PatientCode AS 'HospitalNo',
    RP.ReferringPartyName,
    RPG.GroupName,
    RO.ReferringOrganizationName,
    ISNULL(RP.VehicleNumber, '') AS VehicleNumber,
    RS.ReferralSchemeName,
    RC.InvoiceNetAmount AS 'InvoiceNetAmount',
    RC.Percentage,	
    RC.ReferralAmount,
    RC.Remarks,
    emp.FullName AS 'EnteredBy',
    RC.CreatedOn AS 'EnteredOn'
FROM (SELECT PatientId,InvoiceNoFormatted,InvoiceDate,InvoiceNetAmount,
				Percentage,ReferralAmount,Remarks,CreatedBy,CreatedOn,ReferringPartyId,
				ReferralSchemeId,FiscalYearId FROM MKT_TXN_ReferralCommission
				WHERE InvoiceDate BETWEEN @FromDate AND @ToDate AND IsActive = 1 
					AND ISNULL(@ReferringPartyId, ReferringPartyId) = ReferringPartyId) RC 
INNER JOIN PAT_Patient pat ON RC.PatientId = pat.PatientId
INNER JOIN MKT_CFG_ReferringParty RP on RC.ReferringPartyId = RP.ReferringPartyId
INNER JOIN MKT_MST_ReferringOrganization RO on RP.ReferringOrgId = RO.ReferringOrganizationId
INNER JOIN MKT_MST_ReferringPartyGroup RPG on RP.ReferringPartyGroupId = RPG.ReferringPartyGroupId
INNER JOIN MKT_MST_ReferralScheme RS on RC.ReferralSchemeId = RS.ReferralSchemeId
INNER JOIN BIL_CFG_FiscalYears FY ON RC.FiscalYearId = FY.FiscalYearId
INNER JOIN EMP_Employee emp ON RC.CreatedBy = emp.EmployeeId

ORDER BY RC.InvoiceDate DESC       
END