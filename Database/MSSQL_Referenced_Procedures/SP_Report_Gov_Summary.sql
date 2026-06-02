CREATE PROCEDURE [dbo].[SP_Report_Gov_Summary] -- EXEC SP_Report_Gov_Summary '2022-01-01','2022-01-31'
	 @FromDate DATE = NULL
	,@ToDate DATE = NULL
	/*
FileName: [SP_Report_Gov_Summary]
CreatedBy/date: Sagar/2017-06-06
Description: to get all informations of MR> Hospital Service Summary Report page.

This SP returns 8 TABLES 
   table1: Outpatient and Emergency Services
   table2: Diagnosis and Other Services
   table3: Free Services
   table4: Total Immunization Patient Served 
   table5: Inpatient Referred Out Count
   table6: Total Patient Admitted table
   table7: InpatientDaysCount
   table8: Laboratory Services Provided [Distinct Patient Count] 
   table9: Referred Outpatient male female count added

Remarks   : default getdate() for FromDate and ToDate.
          : ToDate is incremented by 1 since otherwise it doesn't take 
           
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Prem/Sud:09Mar'22  	                  Re-Write of existing stored proc into functions.
                                              Removed Date wise IF-Else condition (which was made earlier for LPH and other hospitals
2.	Prem										Referred Out patient count in outpatient is added.
*/
AS
BEGIN

	
	   Select * from FN_MR_HospSummary_GetOPandERservices(@FromDate,@ToDate)

		-- Table 2
		-- Diagnosis and Other Services
		Select ReportingItemName, Unit, TotalCount
		from FN_MR_HospSummary_GetDiagnosticAndOtherServices(@FromDate,@ToDate)
		order by orderpriority ASC, ReportingItemName desc


	   Select * from FN_MR_HospSummary_GetFreeServices(@FromDate,@ToDate)

		-- Total Immunization Patient Served 

		Declare @VaccDepartmentName varchar(200) = (Select top 1 ParameterValue from CORE_CFG_Parameters where ParameterName='immunizationdeptname' 
													 and ParameterGroupName='Common');											 
		Declare @DeptId INT=(Select Top(1) DepartmentId from MST_Department where DepartmentName=@VaccDepartmentName);


		SELECT COUNT(*) AS TotalVaccinationClientServed
		FROM PAT_PatientVisits patV WITH(NOLOCK)
		WHERE  patV.DepartmentId = @DeptId
			AND patV.IsActive = 1
			AND patV.BillingStatus != 'returned'
			AND CONVERT(date,patV.VisitDate) BETWEEN @FromDate AND @ToDate;

		-- Table 5-- 

		-- Inpatient Referred Out Count table
		SELECT ISNULL( SUM(CASE WHEN Gender = 'Male' THEN 1 ELSE 0 END),0) AS IpRO_MaleCount,
               ISNULL(SUM(CASE WHEN Gender = 'Female' THEN 1 ELSE 0 END),0) AS IpRO_FemaleCount					
		FROM MR_RecordSummary mrs
			INNER JOIN ADT_DischargeType dt WITH(NOLOCK) ON mrs.DischargeTypeId = dt.DischargeTypeId
			INNER JOIN PAT_Patient pat WITH(NOLOCK) ON mrs.PatientId = pat.PatientId
			INNER JOIN ADT_PatientAdmission adm WITH(NOLOCK) ON mrs.PatientVisitId = adm.PatientVisitId
		 WHERE dt.DischargeTypeName = 'Referred'
		 AND CONVERT(DATE, adm.DischargeDate) BETWEEN @FromDate AND @ToDate
	
		-- table 6
		-- Total Patient Admitted table 
		SELECT COUNT(PatientId) AS TotalPatientsAdmitted
		FROM ADT_PatientAdmission WITH(NOLOCK)
		WHERE AdmissionStatus != 'cancel'
		   AND CONVERT(DATE,AdmissionDate) BETWEEN @FromDate AND @ToDate;

		-- table 7
		-- Total Inpatient Days Table
		select dbo.FN_MR_HospSummary_GetTotalInpatientDays(@FromDate, @ToDate) AS 'TotalInpatientDays'

		--We need Patient count, hence taking Distinct PatientID----
		SELECT COUNT (DISTINCT pat.PatientId) as TotlLabServiceProvidedPersonCount
		 FROM 
		BIL_TXN_BillingTransactionItems btxi WITH(NOLOCK)
		INNER JOIN PAT_Patient pat WITH(NOLOCK) ON pat.PatientId = btxi.PatientId
		INNER JOIN BIL_TXN_BillingTransaction inv WITH(NOLOCK) ON btxi.BillingTransactionId = inv.BillingTransactionId
		LEFT JOIN BIL_TXN_InvoiceReturnItems brtn WITH(NOLOCK) ON btxi.BillingTransactionItemId = brtn.BillingTransactionItemId

		WHERE 
			brtn.BillReturnItemId IS NULL
			AND CONVERT(DATE, inv.CreatedOn) BETWEEN @FromDate AND @ToDate
			AND btxi.ServiceDepartmentId in (select ServiceDepartmentId from BIL_MST_ServiceDepartment where IntegrationName ='LAB')
		SELECT ISNULL( SUM(CASE WHEN Gender = 'Male' THEN 1 ELSE 0 END),0) AS OpReferred_MaleCount,
               ISNULL(SUM(CASE WHEN Gender = 'Female' THEN 1 ELSE 0 END),0) AS OpReferred_FemaleCount			
		FROM (SELECT PatientId,PatientVisitId, IsPatientReferred, IsActive FROM MR_TXN_Outpatient_FinalDiagnosis		GROUP BY PatientVisitId, PatientId, IsPatientReferred, IsActive) ofd
		inner join PAT_Patient pt on pt.PatientId= ofd.PatientId
		inner join PAT_PatientVisits ptv on ptv.PatientVisitId= ofd.PatientVisitId
		WHERE ofd.IsActive=1 and ofd.IsPatientReferred=1 
		 AND CONVERT(DATE, ptv.VisitDate) BETWEEN @FromDate AND @ToDate

END