CREATE PROCEDURE [dbo].[SP_Report_EmergencyPatient_Morbidity]
	@fromDate DATE= null, 
	@toDate DATE = null
AS

/************************************************************************
FileName: [SP_Report_OutPatient_Morbidity ]
CreatedBy/date: Prem: 14th Nov,2022
Description: To get details of Emergency Patient Morbidity report in MR
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1.    Prem					SP For Emergency Morbidity report in MR
*************************************************************************/

SELECT 
		EMER_ReportingGroupId,ReportingGroupName,
		(SELECT TOP(1)
			SerialNumber,ICDCode,
			EMER_DiseaseGroupName,
			SUM (ISNULL(FemaleCount,0)) as NumberOfFemale,
			SUM (ISNULL(MaleCount,0)) as NumberOfMale ,		
			SUM (ISNULL(OtherGenderCount,0)) as NumberOfOtherGender
		FOR
			JSON PATH,  WITHOUT_ARRAY_WRAPPER 
		) as DiseasesGroup	
	INTO #ReportGroupData$
	FROM
	(
		SELECT 
			SerialNumber,ReportingGroupName,EMER_DiseaseGroupName,EMER_ReportingGroupId,ICDCode,
			CASE WHEN Gender ='Male' THEN SUM(ISNULL(PatientCount,0)) END AS MaleCount,
			CASE WHEN Gender ='Female' THEN SUM(ISNULL(PatientCount,0)) END AS FemaleCount,
			CASE WHEN Gender ='Other' THEN SUM(ISNULL(PatientCount,0)) END AS OtherGenderCount
	
		FROM (
			SELECT dg.SerialNumber,dg.ICDCode,
				   rp.GroupCode +' '+rp.EMER_ReportingGroupName AS ReportingGroupName,
				   dg.EMER_DiseaseGroupName,temp.Gender,temp.PatientCount,rp.EMER_ReportingGroupId 
		    FROM ICD_Emergency_ReportingGroup rp 
			INNER JOIN ICD_Emergency_DiseaseGroup dg ON dg.EMER_ReportingGroupId=rp.EMER_ReportingGroupId
			LEFT JOIN
			(
			    SELECT
				 dg.EMER_DiseaseGroupId ,pt.Gender,COUNT(*) AS PatientCount,dg.ICDCode
				FROM MR_TXN_Emergency_FinalDiagnosis fd
				INNER JOIN ICD_Emergency_DiseaseGroup dg ON fd.EMER_DiseaseGroupId=dg.EMER_DiseaseGroupId
				INNER JOIN PAT_PatientVisits pv ON pv.PatientVisitId=fd.PatientVisitId
				INNER JOIN PAT_Patient pt ON pt.PatientId = fd.PatientId
				WHERE fd.IsActive=1 AND pv.BillingStatus!='returned' AND CONVERT(DATE, pv.VisitDate) BETWEEN
				@fromDate AND @toDate
				GROUP BY  dg.EMER_DiseaseGroupId,pt.Gender,dg.ICDCode
			)temp on temp.EMER_DiseaseGroupId= dg.EMER_DiseaseGroupId			
			)ft
			GROUP BY EMER_DiseaseGroupName,ReportingGroupName,EMER_ReportingGroupId, SerialNumber, Gender,ICDCode
			)fr
	GROUP BY SerialNumber,EMER_ReportingGroupId,ReportingGroupName,EMER_DiseaseGroupName,ICDCode
	ORDER BY SerialNumber ASC

	SELECT EMER_ReportingGroupId,ReportingGroupName , '[' + STRING_AGG(DiseasesGroup, ',') + ']' AS DiseasesGroup
	FROM #ReportGroupData$
	GROUP  BY EMER_ReportingGroupId, ReportingGroupName