CREATE PROCEDURE SP_Report_Gov_HospitalMortality
	@fromDate DATE= null, 
	@toDate DATE = null
AS
BEGIN
SET NOCOUNT ON
/****************************************************************************************
FileName: [SP_Report_Gov_HospitalMorbidity ]
Change History
S.No.    UpdatedBy/Date                        Remarks
1.    Prem 5thSept 2022						Initial draft For Hospital Morbidity Report
******************************************************************************************
*/

BEGIN
--Temporary Age Range Table Created
 CREATE TABLE #AgeRange
 (
 AgeSerialNo INT,
 AgeRange varchar(100)
 );
 INSERT INTO #AgeRange
	(AgeSerialNo, AgeRange)
	VALUES
		  (1,'0-7Days'),
		  (2,'8-28Days'),
		  (3, '29Days-1Year'),
          (4, '01-04Years'),
          (5, '05-14Years'),
          (6, '15-19Years'),
          (7, '20-29Years'),
          (8, '30-39Years'),
          (9, '40-49Years'),
          (10, '50-59Years'),
		  (11, '60-69Years'),
          (12, '>=70Years')

--Temporary Gender Table is created.
	CREATE TABLE #Gender
	(
	Gender varchar(50)
	);
	INSERT INTO #Gender
	(Gender)
	VALUES
			('Male'),
			('Female')

			--Main Query start from here---

			SELECT 
			ICD10Code as ICDCode, ICD10Name as ICDCodeName,
			SUM(ISNULL([0-7Days_Female],0)) as v0Day_to_7_Days_Female,
			SUM(ISNULL([0-7Days_Male],0)) as v0Day_to_7_Days_Male,
			SUM(ISNULL([8-28Days_Female],0)) as v8Day_to_28_Days_Female,
			SUM(ISNULL([8-28Days_Male],0)) as v8Day_to_28_Days_Male,
			SUM(ISNULL([29Days-1Year_Female],0)) as v29Days_to_1yr_Female,		
			SUM(ISNULL([29Days-1Year_Male],0)) as v29Days_to_1yr_Male,
			SUM(ISNULL([01-04Years_Female],0)) as v1yr_to_4yr_Female,
			SUM(ISNULL([01-04Years_Male],0)) as v1yr_to_4yr_Male,
			SUM(ISNULL([05-14Years_Female],0)) as v5yr_to_14yr_Female,
			SUM(ISNULL([05-14Years_Male],0)) as v5yr_to_14yr_Male,
			SUM(ISNULL([15-19Years_Female],0)) as v15yr_to_19yr_Female,
			SUM(ISNULL([15-19Years_Male],0)) as v15yr_to_19yr_Male,
			SUM(ISNULL([20-29Years_Female],0)) as v20yr_to_29yr_Female,
			SUM(ISNULL([20-29Years_Male],0)) as v20yr_to_29yr_Male,
			SUM(ISNULL([30-39Years_Female],0)) as v30yr_to_39yr_Female,
			SUM(ISNULL([30-39Years_Male],0)) as v30yr_to_39yr_Male,
			SUM(ISNULL([40-49Years_Female],0)) as v40yr_to_49yr_Female,
			SUM(ISNULL([40-49Years_Male],0)) as v40yr_to_49yr_Male,
			SUM(ISNULL([50-59Years_Female],0)) as v50yr_to_59yr_Female,
			SUM(ISNULL([50-59Years_Male],0)) as v50yr_to_59yr_Male,
			SUM(ISNULL([60-69Years_Female],0)) as v60yr_to_69yr_Female,
			SUM(ISNULL([60-69Years_Male],0)) as v60yr_to_69yr_Male,
			SUM(ISNULL([>=70Years_Female],0)) as gt_70yr_Female,
			SUM(ISNULL([>=70Years_Male],0)) as gt_70yr_Male
			FROM(
			SELECT displayData.ColumnHeaders, displayData.ICD10Name, displayData.ICD10Code,
					Sum(ISNULL(TotalPatient,0)) as TotalPatientCount
					FROM
			(
			SELECT  ICD10Code,ICD10Name, AgeRange + '_' + Gender as ColumnHeaders, AgeSerialNo
			FROM 
			(
			SELECT DISTINCT IDig.ICD10Code,IDig.ICD10Name 
					FROM MR_RecordSummary MRecord
					INNER JOIN ADT_PatientAdmission Adm
					ON adm.PatientVisitId= MRecord.PatientVisitId
					INNER JOIN MR_TXN_Inpatient_Diagnosis IDig
					ON MRecord.MedicalRecordId=IDig.MedicalRecordId
					INNER JOIN ADT_DischargeType dt
					ON MRecord.DischargeTypeId=dt.DischargeTypeId
					WHERE IDig.IsActive !=0 AND
					dt.DischargeTypeName='Death' AND
					CONVERT(DATE,Adm.DischargeDate) BETWEEN @fromDate AND @toDate
			) AS icdDisease
			LEFT JOIN 
			(
			SELECT age.AgeSerialNo, age.AgeRange,gender.Gender 
			FROM #AgeRange age
				LEFT JOIN #Gender gender ON 1=1
				) ageGender
				ON 1=1
			)
			AS displayData
				LEFT JOIN
				(
				SELECT ICD10Code, ICD10Name, AgeRange + '_' + Gender as ColumnHeaders, SUM(PatientCount)'TotalPatient' 
							FROM
							(
							SELECT age.AgeRange, discharge.DischargeTypeName, gender.Gender, 
							SUM(ISNULL(PatientCount,0)) as PatientCount, MR.ICD10Code, MR.ICD10Name
							FROM #AgeRange age
							LEFT JOIN #Gender gender ON 1=1
							LEFT JOIN ADT_DischargeType discharge			ON 1=1
							INNER JOIN
									(
									SELECT *,ISNULL(COUNT(*),0) AS PatientCount
										FROM
										(
										SELECT Pat.Gender, dbo.[GetDobAgeRangeInpatientOutcome] (Pat.DateOfBirth,PatAd.DischargeDate) as AgeRange,	I.ICD10Code,I.ICD10Name,
										MRS.DischargeTypeId
										FROM
										MR_RecordSummary MRS
										INNER JOIN PAT_Patient Pat ON
										MRS.PatientId=Pat.PatientId
										INNER JOIN 
										ADT_PatientAdmission PatAd ON
										MRS.PatientVisitId= PatAd.PatientVisitId
										INNER JOIN MR_TXN_Inpatient_Diagnosis I ON MRS.MedicalRecordId=I.MedicalRecordId
										INNER JOIN 
										ADT_DischargeType  Dt ON
										mrs.DischargeTypeId=Dt.DischargeTypeId
										WHERE Dt.DischargeTypeName='Death'
										AND Convert(Date,PatAd.DischargeDate) BETWEEN @fromDate AND @toDate
										AND I.IsActive!=0						
										)  initdata
										GROUP BY initdata.AgeRange, initdata.Gender, ICD10Code,
										ICD10Name, initdata.DischargeTypeId
									) MR ON MR.DischargeTypeId=discharge.DischargeTypeId
				AND age.AgeRange=MR.AgeRange
				AND LOWER(MR.Gender)= LOWER(gender.Gender)
				WHERE discharge.IsActive=1
				GROUP BY age.AgeRange, discharge.DischargeTypeName, gender.Gender,MR.ICD10Code,MR.ICD10Name
							)t
							Group By  AgeRange, Gender,	ICD10Code, ICD10Name
							) countData
							ON countData.ColumnHeaders =displayData.ColumnHeaders AND	
							countData.ICD10Code = displayData.ICD10Code
							GROUP BY  displayData.ColumnHeaders, displayData.ICD10Name, displayData.ICD10Code
							) AS Ft
				PIVOT
				(
				SUM(ft.TotalPatientCount)
				FOR ft.ColumnHeaders IN
			(
			[0-7Days_Female],
			[0-7Days_Male],
			[8-28Days_Female],
			[8-28Days_Male],
			[29Days-1Year_Male],
			[29Days-1Year_Female],
			[01-04Years_Male],
			[01-04Years_Female],
			[05-14Years_Male],
			[05-14Years_Female],
			[15-19Years_Male],
			[15-19Years_Female],
			[20-29Years_Male],
			[20-29Years_Female],
			[30-39Years_Male],
			[30-39Years_Female],
			[40-49Years_Male],
			[40-49Years_Female],
			[50-59Years_Male],
			[50-59Years_Female],
			[60-69Years_Female],
			[60-69Years_Male],
			[>=70Years_Female],
			[>=70Years_Male]
		)
	) AS pivot_table
	GROUP BY ICD10Name, ICD10Code
	ORDER by  ICD10Name

	DROP TABLE #AgeRange
	DROP TABLE #Gender

	END
	END