CREATE PROCEDURE [dbo].[SP_Report_OutPateint_Morbidity]
	@fromDate DATE= null, 
	@toDate DATE = null
AS

/************************************************************************
FileName: [SP_Report_OutPatient_Morbidity ]   
CreatedBy/date: Prem/Bikash: 16th Feb,2022
Description: To get details of Outpatient Morbidity report in MR
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1.    Prem/Bikash						SP For Outpatient Morbidity report in MR
2.    Prem								Emergency Patient Removed.
3.    Nirmala                           Fetched TotalMaleNewOPDVisits,TotalFemaleNewOPDVisits,TotalMaleOldOPDVisits,TotalFemaleOldOPDVisits 
*************************************************************************/

BEGIN
SET NOCOUNT ON

	-- table 1
	
Select ReportingGroupId, ReportingGroupName,IcdVersion, '[' + STRING_AGG(DiseasesGroup, ',') + ']' as DiseasesGroup
from 
(
	select 
			ReportingGroupId,ReportingGroupName,IcdVersion,
			(SELECT TOP(1)
				SerialNumber,
				DiseaseGroupName,
				ICDCode,
				SUM (ISNULL(FemaleCount,0)) as NumberOfFemale,
				SUM (ISNULL(MaleCount,0)) as NumberOfMale ,		
				SUM (ISNULL(OtherGenderCount,0)) as NumberOfOtherGender
			FOR
				JSON PATH,  WITHOUT_ARRAY_WRAPPER 
			) as DiseasesGroup	
		--INTO #ReportGroupData$
		FROM
		(
			SELECT 
				SerialNumber,DiseaseGroupName,ReportingGroupName,ICDCode,ReportingGroupId,IcdVersion,
				case When Gender ='Male' then SUM(ISNULL(PatientCount,0)) end as MaleCount,
				case When Gender ='Female' then SUM(ISNULL(PatientCount,0)) end as FemaleCount,
				case When Gender ='Other' then SUM(ISNULL(PatientCount,0)) end as OtherGenderCount

	
			FROM (
				Select  
					dg.SerialNumber, 
					dg.DiseaseGroupName,
					rg.ReportingGroupId,
					rg.GroupCode + ' ' + rg.ReportingGroupName as ReportingGroupName,
					dg.ICDCode,
					dt.Gender, 
					dt.PatientCount,
					rg.IcdVersion
				
		
				from ICD_ReportingGroup rg
				INNER JOIN ICD_DiseaseGroup dg on rg.ReportingGroupId=dg.ReportingGroupId 
				LEFT JOIN	 
					(
						select micd.ICD10Code,  pat.Gender,
						count(*) as PatientCount
						from MR_TXN_Outpatient_FinalDiagnosis fd
						inner join PAT_Patient pat  on fd.PatientId = pat.PatientId
						inner join PAT_PatientVisits patv on fd.PatientVisitId=patv.PatientVisitId
						inner join MST_ICD10 micd on fd.ICD10ID = micd.ICD10ID
						where patv.VisitType ='outpatient' AND patv.BillingStatus!='returned' AND CONVERT(DATE, patv.VisitDate) BETWEEN
						@fromDate AND @toDate and fd.IsActive!=0
						Group by Gender, micd.ICD10ID, ICD10Code
					)dt on dt.ICD10Code = dg.ICDCode	
			)sft
			Group by DiseaseGroupName,ReportingGroupName,ReportingGroupId, SerialNumber, ICDCode, Gender,IcdVersion
	
	)ft
	Group By SerialNumber,ReportingGroupId,ReportingGroupName,DiseaseGroupName,ICDCode,IcdVersion
) ReportGroupData$
group by ReportingGroupId, ReportingGroupName,IcdVersion




	SELECT
		gt.Gender, ISNULL(ft.MaleCountOICD, 0) as MaleCountOICD, ISNULL(ft.FemaleCountOICD,0) as FemaleCountOICD
	FROM 
	(
		select * 
		from (values ('Female'), ('Male')) x(Gender) 
	) as gt
	left join
	(
		SELECT
				Gender,
				case When Gender ='Male' then count(*) else 0 end as MaleCountOICD,
				case When Gender ='Female' then count(*)else 0 end as FemaleCountOICD

			from MR_TXN_Outpatient_FinalDiagnosis fd
			inner join PAT_Patient pat  on fd.PatientId = pat.PatientId
			inner join PAT_PatientVisits patv on fd.PatientVisitId = patv.PatientVisitId
			inner join MST_ICD10 micd on fd.ICD10ID = micd.ICD10ID
			where micd.ICD10Code not in (select ICDCode from ICD_DiseaseGroup)
			and fd.IsActive !=0 
			and patv.VisitType='outpatient'
			AND patv.BillingStatus!='returned' 
			AND CONVERT(DATE, patv.VisitDate) BETWEEN
			@fromDate AND @toDate 
			GROUP BY Gender
	)ft ON ft.Gender=gt.Gender
			

	
	SELECT
    SUM(CASE WHEN PatientVisitType = 'new' AND Gender = 'Male' THEN CountByAppType ELSE 0 END) AS TotalMaleNewOPDVisits,
    SUM(CASE WHEN PatientVisitType = 'new' AND Gender = 'Female' THEN CountByAppType ELSE 0 END) AS TotalFemaleNewOPDVisits,
    SUM(CASE WHEN PatientVisitType = 'old' AND Gender = 'Male' THEN CountByAppType ELSE 0 END) AS TotalMaleOldOPDVisits,
    SUM(CASE WHEN PatientVisitType = 'old' AND Gender = 'Female' THEN CountByAppType ELSE 0 END) AS TotalFemaleOldOPDVisits
FROM
(
    SELECT
        visitTbl.PatientVisitType,
        patientTbl.Gender,
        Count(*) AS CountByAppType
    FROM
    ( 
        SELECT 
            PatientId,
            PatientVisitId,
			-- If Appointment Type is 'Followup' or 'referral' or 'transfer' then PatientVisitType is regarded as old 
            CASE WHEN AppointmentType = 'new' THEN 'new' ELSE 'old' END AS PatientVisitType 
        FROM PAT_PatientVisits
        WHERE
            VisitType != 'inpatient'
            AND BillingStatus != 'returned'
            AND CONVERT(DATE, VisitDate) BETWEEN @fromDate AND @toDate
    ) AS visitTbl
    INNER JOIN PAT_Patient AS patientTbl ON visitTbl.PatientId = patientTbl.PatientId
    GROUP BY visitTbl.PatientVisitType, patientTbl.Gender
) AS ft
END