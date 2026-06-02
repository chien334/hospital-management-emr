CREATE PROCEDURE  [dbo].[SP_Report_Gov_InpatientMorbidity]
    @FromDate DATE = NULL,
    @ToDate DATE= NULL

AS
/*
FileName: [SP_Report_Gov_InpatientMorbidity]
CreatedBy/date: Bikash/Sudarshan/2021-09-14
Description: to get inpatient disease wise (morbidity)  data.
Remarks:
            
Change History
S.No.    UpdatedBy/Date							 Remarks
1.       Bikash/Sud: 30Sept'21                Corrected for Death Count taking from separate table..
2.		 Prem: 2th March '22				  Corrected for Diagnoisis based patient count.
*/

BEGIN
  -- Age Range
	CREATE TABLE #AgeRange
	(
		AgeSerialNo INT,
		AgeRange varchar(100)
	);
	INSERT INTO #AgeRange
		(AgeSerialNo, AgeRange)
	VALUES
		 (1, '0-7Days'),
			 (2, '8-28Days'),
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

	-- Gender Range
	CREATE TABLE #Genders
	(
		Gender VARCHAR(100)
	);
	INSERT INTO #Genders
		( Gender)
	VALUES
		('Male'),
		('Female');

		-- Query started --- 

	SELECT  ICD10Code as ICDCode, ICD10Name as ICDCodeName,
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
			SUM(ISNULL([>=70Years_Male],0)) as gt_70yr_Male	,	
		
			SUM(ISNULL(TotalDeaths_Female,0)) as TotalDeaths_Female,
			SUM(ISNULL(TotalDeaths_Male,0)) as TotalDeaths_Male

	FROM
		(
			SELECT displayData.ColumnHeaders, displayData.ICD10Name, displayData.ICD10Code,
					Sum(ISNULL(TotalPatient,0)) as TotalPatientCount,
					Sum (ISNULL(deathOnly.MaleCount,0)) as TotalDeaths_Male,
					Sum (ISNULL(deathOnly.FemaleCount,0)) as TotalDeaths_Female
			FROM
				(
					SELECT ICD10Code,ICD10Name, AgeRange + '_' + Gender as ColumnHeaders, AgeSerialNo
					FROM 				
					(					
							SELECT distinct I.ICD10Code, I.ICD10Name
							FROM MR_RecordSummary MRec
							--INNER JOIN PAT_Patient P ON MRec.PatientId = P.PatientId
							INNER JOIN ADT_PatientAdmission adm ON adm.PatientVisitId=MRec.PatientVisitId
							INNER JOIN MR_TXN_Inpatient_Diagnosis I ON MRec.MedicalRecordId=I.MedicalRecordId
							WHERE Convert(Date,adm.DischargeDate) BETWEEN @FromDate AND @ToDate
							AND I.IsActive!=0
					) As diseaseD
					LEFT JOIN
					(
						Select age.AgeSerialNo,age.AgeRange, gender.Gender
						FROM #AgeRange age
						LEFT JOIN #Genders gender ON 1=1
					) ageGender
					ON 1 = 1 
				) 
				AS displayData
					LEFT JOIN
					(
						SELECT  ICD10Code, ICD10Name, AgeRange + '_' + Gender as ColumnHeaders, 
						SUM(PatientCount)'TotalPatient'
						--,SUM( Case When DischargeTypeName='Death' and Gender='Male' then PatientCount ELSE 0 END) AS Death_Male
						--,SUM( Case When DischargeTypeName='Death' and Gender='Female' then PatientCount ELSE 0 END) AS Death_Female
						FROM
							(
								SELECT age.AgeRange, discharge.DischargeTypeName, gender.Gender, 
									SUM(ISNULL(PatientCount,0)) as PatientCount, MR.ICD10ID, MR.ICD10Code, MR.ICD10Name
								FROM #AgeRange age
									LEFT JOIN #Genders gender ON 1=1
									LEFT JOIN ADT_DischargeType discharge ON 1=1
									INNER JOIN 
									(
										Select *, ISNULL(COUNT(*),0) as PatientCount
										From
											(
												SELECT MRec.DischargeTypeId, 
												dbo.[GetDobAgeRangeInpatientOutcome] (P.DateOfBirth, adm.DischargeDate) as AgeRange, 
												P.Gender,I.ICD10ID, I.ICD10Code, I.ICD10Name
												FROM MR_RecordSummary MRec
													INNER JOIN PAT_Patient P ON MRec.PatientId = P.PatientId
													INNER JOIN ADT_PatientAdmission adm ON adm.PatientVisitId=MRec.PatientVisitId
													INNER JOIN MR_TXN_Inpatient_Diagnosis I ON MRec.MedicalRecordId=I.MedicalRecordId
													WHERE Convert(Date,adm.DischargeDate) BETWEEN @FromDate AND @ToDate
													AND I.IsActive!=0
											) initdata
										GROUP BY initdata.DischargeTypeId, 
										initdata.AgeRange,initdata.Gender, 
										ICD10ID, ICD10Code, ICD10Name

									) MR ON MR.DischargeTypeId = discharge.DischargeTypeId 
											AND age.AgeRange = MR.AgeRange
											AND LOWER(MR.Gender) = LOWER(gender.Gender)
								WHERE discharge.IsActive = 1
								GROUP BY age.AgeRange, discharge.DischargeTypeName, gender.Gender,
								MR.ICD10ID,MR.ICD10Code,MR.ICD10Name
							) t
						Group By  AgeRange, Gender,  ICD10Code, ICD10Name
					)countData 
				ON countData.ColumnHeaders = displayData.ColumnHeaders and countData.ICD10Code = displayData.ICD10Code

				LEFT JOIN (
						SELECT ipDiag.ICD10ID, ipDiag.ICD10Code, ipDiag.ICD10Name, 
						   SUM( Case When pat.Gender='Male' then 1 ELSE  0 End) AS MaleCount,
						   SUM(Case When pat.Gender='Female' then 1 ELSE 0 End) AS FemaleCount
						from MR_RecordSummary mr 
							inner join PAT_PatientVisits vis on mr.PatientVisitId=vis.PatientVisitId
							inner join ADT_PatientAdmission adm on vis.PatientVisitId= adm.PatientVisitId 
							inner join ADT_DischargeType discType on mr.DischargeTypeId=discType.DischargeTypeId
							LEFT join MR_TXN_Inpatient_Diagnosis ipDiag on ipDiag.MedicalRecordId=mr.MedicalRecordId
							inner join PAT_Patient pat on pat.PatientId= mr.PatientId
						Where adm.AdmissionStatus='discharged'
							  and Convert(Date,adm.DischargeDate) between @FromDate and @ToDate
							  and discType.DischargeTypeName='Death'
							  and ipDiag.IsActive!=0
						Group by ipDiag.ICD10ID,
							 ipDiag.ICD10Code, ipDiag.ICD10Name
			
				) deathOnly ON displayData.ICD10Code=deathOnly.ICD10Code 

			GROUP BY  displayData.ColumnHeaders, displayData.ICD10Name, displayData.ICD10Code
		
	) As ft 
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

	--Drop temporary tables---
	DROP TABLE #AgeRange
	DROP TABLE #Genders
END