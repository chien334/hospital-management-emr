/*exec SP_Report_Gov_InpatientOutcome '2022-07-13','2022-07-20'
FileName: [SP_Report_Gov_Inpatient_Outcome]
CreatedBy/date: Ramavtar/2017-10-13
Description: to get count of number of admitted patient by Gender between given dates and count of discharge patient by gender and discharge types between given dates; 
Remarks:
            
Change History
S.No.    UpdatedBy/Date							 Remarks
1       Ramavtar/2017-10-13					Created the script
2		Bikash/10th-Aug'2021				Modified Inpatient Outcome (table1)
3		Bikash/10th-Aug'2021				Added IGestational Week vs Gravida vs Patient Count (table2) 
4		Bikash/10th-Aug'2021				Added Maternal Age and gestational week data set (table 3)
5		Bikash/10th-Aug'2021				Added Free Health Service Summary (table 6)
6		Bikash/10th-Aug'2021				Added Free Health Service and Social Service Proramme dataset (table 7) 
7		Bikash/10th-Aug'2021				Added Death data set (table 5)
8		Bikash/10th-Aug'2021				Added No. of Surgeries dataset (table 4)
9		Bikash/11th-Aug'2021				Modified No. of Surgeries dataset (table 4), visit type added 
9		Bikash/12th-Aug'2021				Modified Death dataset (table 5), optimized
10		Bikash/12th-Sept'2021				Modified Death Category  i.e. <48hr and >=48hr added (table 1)
11		Bikash/13th-Sept'2021				Modified: Patient Age calculation on Discharged Date and Gestational week logic changed(table 1, table2 and table 3)
12		Prem/20th-July'2022					Modified: DOR column added in table1.
13		Prem/31th-Aug'2022					Modified:DateRange Modified.
*/
CREATE PROCEDURE  [dbo].[SP_Report_Gov_InpatientOutcome]
    @FromDate DATE = NULL,
    @ToDate DATE= NULL

AS
BEGIN
    IF(@FromDate IS NOT NULL OR @ToDate IS NOT NULL or LEN(@FromDate)>0 OR LEN(@ToDate)>0)
BEGIN

        -- Start: Inpatient Outcome Data Set
        -- Start: Inpatient Outcome Data Set
        -- Age Range

        CREATE TABLE #AgeRange
        (
            AgeSerialNo INT,
            AgeRange varchar(100),
            AgeDisplayName varchar(100)

        );
        INSERT INTO #AgeRange
            (AgeSerialNo, AgeRange,AgeDisplayName)
        VALUES
            (1, '0-7Days','v0Day_to_7_Days'),
			 (2, '8-28Days','v8Day_to_28_Days'),
            (3, '29Days-1Year','v29Days_to_1yr'),
            (4, '01-04Years','v1yr_to_4yr'),
            (5, '05-14Years','v5yr_to_14yr' ),
            (6, '15-19Years','v15yr_to_19yr'),
            (7, '20-29Years','v20yr_to_29yr'),
            (8, '30-39Years','v30yr_to_39yr'),
            (9, '40-49Years','v40yr_to_49yr'),
            (10, '50-59Years','v50yr_to_59yr'),
			(11, '60-69Years','v60yr_to_69yr'),
            (12, '>=70Years','gt_70yr')

        -- Gender Range
        CREATE TABLE #Genders
        (
            SN INT,
            Gender VARCHAR(100)
        );
        INSERT INTO #Genders
            ( Gender)
        VALUES
            ('Male'),
            ('Female')
        -- Query Starts from here
        SELECT AgeRange, Recovered_Male, Recovered_Female,Stable_Male,Stable_Female, Not_Improved_Male, 
		Not_Improved_Female, Referred_Male, Referred_Female, LAMA_Male, 
		LAMA_Female,DOR_Male,DOR_Female, Absconded_Male, Absconded_Female, [Death_Lt48_Male], 
		[Death_Lt48_Female], [Death_Gt48_Male], [Death_Gt48_Female]
        FROM
            (
    
        SELECT age.AgeSerialNo, age.AgeRange, discharge.DischargeTypeName + '_' + gender.Gender as ColumnsHeader, 
		SUM(ISNULL(PatientCount,0)) as PatientCount
            FROM #AgeRange age
                LEFT JOIN #Genders gender ON 1=1
                LEFT JOIN (SELECT
                    CASE when de.DeathType IS NULL then Replace(dt.DischargeTypeName,' ','_') 
					   else (CASE When de.DeathType = '<48' then dt.DischargeTypeName +'_Lt48' 
					         When de.DeathType = '>48' then dt.DischargeTypeName +'_Gt48'  End ) END as DischargeTypeName,
                    IsActive
                FROM ADT_DischargeType dt
                    LEFT JOIN ADT_MST_DeathType de on dt.DischargeTypeId = de.DischargeTypeId
                WHERE dt.IsActive =1
                    ) discharge ON 1=1
                LEFT JOIN
                (
                    SELECT *,
                    ISNULL(Count(*),0) as PatientCount
                FROM (
								 SELECT
                        CASE when dth.DeathType IS NULL then Replace(dt.DischargeTypeName,' ','_') 
						   else (CASE When dth.DeathType = '<48' then dt.DischargeTypeName +'_Lt48' 
						          When dth.DeathType = '>48' then dt.DischargeTypeName +'_Gt48'  End ) END as DischargeTypeName,
                        pat.Gender,
                        dbo.[GetDobAgeRangeInpatientOutcome] (pat.DateOfBirth, adm.DischargeDate) as AgeRange
                    from MR_RecordSummary mr
                        INNER JOIN ADT_PatientAdmission adm on mr.PatientVisitId=adm.PatientVisitId
                        Left JOIN PAT_Patient pat on pat.PatientId = mr.PatientId
                        Left JOIN ADT_DischargeType  dt on dt.DischargeTypeId = mr.DischargeTypeId
                        Left JOIN ADT_MST_DeathType dth on dth.DeathTypeId = mr.DeathPeriodTypeId

                    WHERE CONVERT(DATE,adm.DischargeDate) BETWEEN @FromDate AND @ToDate

											) AS gp
                GROUP BY DischargeTypeName, Gender, AgeRange
                    
                ) MR ON MR.DischargeTypeName = discharge.DischargeTypeName 
				AND MR.AgeRange = age.AgeRange AND MR.Gender = gender.Gender

            WHERE discharge.IsActive = 1
            GROUP BY age.AgeSerialNo,age.AgeRange, discharge.DischargeTypeName, gender.Gender

) t
  PIVOT
  (
    SUM(t.PatientCount)
    FOR t.ColumnsHeader IN
    (
      [Recovered_Male],
      [Recovered_Female],
	  [Stable_Male],
      [Stable_Female],
      [Not_Improved_Male],
      [Not_Improved_Female],
      [Referred_Male],
      [Referred_Female],
      [LAMA_Male],
      [LAMA_Female],
	  [DOR_Male],
      [DOR_Female],
      [Absconded_Male],
      [Absconded_Female],
      [Death_Lt48_Male],
      [Death_Lt48_Female],
      [Death_Gt48_Male],
      [Death_Gt48_Female]
    )
  ) AS pivot_table

        ORDER BY AgeSerialNo

        DROP TABLE #AgeRange
        DROP TABLE #Genders
        -- End: Inpatient Outcome Data Set



        --Start: Gestational Week vs Gravida vs Patient Count
        -- Create the table in the specified schema
        CREATE TABLE #GestationalWeeksRange
        (
            RangeDisplayName varchar(100),
            RangeStartsOn FLOAT,
            RangeEndsOn FLOAT
        );
        INSERT INTO #GestationalWeeksRange
            (RangeDisplayName,RangeStartsOn, RangeEndsOn)
        VALUES
            ('22-27', 22, 27),
            ('28-36', 28, 36),
            ('37-41', 37, 41),
            ('> 41', 42, 999999)


        SELECT GravidaName,
            [22-27] as GestWeek1,
            [28-36] as GestWeek2,
            [37-41] as GestWeek3,
            [> 41] as GestWeek4
        FROM (
    SELECT G.GravitaName as GravidaName, GWR.RangeDisplayName, SUM(ISNULL(GravidaData.PatientCount,0)) AS PatientCount
            FROM ADT_MST_Gravita G
                INNER JOIN #GestationalWeeksRange GWR ON 1 = 1
                LEFT JOIN
                (
        SELECT
                    GestationalWeek, MRS.GravitaId, count(*) 'PatientCount'
                FROM MR_RecordSummary MRS
                    INNER JOIN PAT_Patient P ON MRS.PatientId = P.PatientId
                    INNER JOIN ADT_PatientAdmission adm on MRS.PatientVisitId=adm.PatientVisitId
                    LEFT JOIN ADT_MST_DischargeConditionType dcon on dcon.DischargeConditionId = MRS.DischargeConditionId
                WHERE LOWER(dcon.Condition) = 'delivery' AND P.Gender = 'Female'
                    and Convert(Date, adm.DischargeDate) BETWEEN @FromDate AND @ToDate
                GROUP BY MRS.GestationalWeek, MRS.GravitaId
    ) GravidaData ON
    GravidaData.GravitaId = G.GravitaId AND GravidaData.GestationalWeek BETWEEN  GWR.RangeStartsOn  AND GWR.RangeEndsOn
            GROUP BY G.GravitaName, GWR.RangeDisplayName
) t
PIVOT
(
    SUM(t.PatientCount)
    FOR t.RangeDisplayName IN
    (
        [22-27], 
        [28-36], 
        [37-41], 
        [> 41]
    )
) AS pivot_table;
        DROP TABLE [#GestationalWeeksRange]
        --End: Gestational Week vs Gravida vs Patient Count




        --Temporary Gestational Table
        CREATE TABLE #GestationalWeeksRange2
        (
            RangeDisplayName varchar(100),
            RangeStartsOn FLOAT,
            RangeEndsOn FLOAT
        );
        INSERT INTO #GestationalWeeksRange2
            (RangeDisplayName,RangeStartsOn, RangeEndsOn)
        VALUES
            ('22-27', 22, 27),
            ('28-36', 28, 36),
            ('37-41', 37, 41),
            ('> 41', 42, 999999)

        -- Temporary age table
        CREATE TABLE #AgeRange2
        (
            AgeSequence int,
            AgeDisplayName varchar(100)
        );


        INSERT INTO #AgeRange2
            (AgeSequence,AgeDisplayName)
        VALUES
            (1, '<20'),
            (2, '20-34'),
            (3, '>34')



        SELECT AgeRange,
            [22-27] as GestWeek1,
            [28-36] as GestWeek2,
            [37-41] as GestWeek3,
            [> 41] as GestWeek4
        FROM
            (
    SELECT AR.AgeSequence, AR.AgeDisplayName 'AgeRange', GWR.RangeDisplayName 'GestationalWeek', SUM(ISNULL(ageGestationalData.PatientCount,0)) 'PatientCount'
            FROM #GestationalWeeksRange2 GWR
                INNER JOIN #AgeRange2 AR ON 1=1
                LEFT JOIN
                (
		   select *,
                    Count(*) 'PatientCount'
                from
                    (
				SELECT
                        MRS.GestationalWeek,
                        dbo.[GetDobAgeRangeGestationalWeek](P.DateOfBirth, adm.DischargeDate) as AgeRange

                    FROM MR_RecordSummary MRS
                        INNER JOIN PAT_Patient P ON MRS.PatientId = P.PatientId
                        INNER JOIN ADT_PatientAdmission adm on MRS.PatientVisitId=adm.PatientVisitId
                        LEFT JOIN ADT_MST_DischargeConditionType dcon on dcon.DischargeConditionId = MRS.DischargeConditionId
                    WHERE LOWER(dcon.Condition) = 'delivery' AND P.Gender = 'Female'
                        And CONVERT(Date, adm.DischargeDate) BETWEEN @FromDate AND @ToDate
			) mr
                GROUP BY  GestationalWeek, AgeRange

    ) ageGestationalData
                ON ageGestationalData.GestationalWeek  BETWEEN  GWR.RangeStartsOn  AND GWR.RangeEndsOn AND
                    ageGestationalData.AgeRange = AR.AgeDisplayName
            GROUP BY AR.AgeSequence ,AR.AgeDisplayName, GWR.RangeDisplayName
) t
PIVOT
(
    SUM(t.PatientCount)
    FOR t.GestationalWeek IN
    (
        [22-27], 
        [28-36], 
        [37-41], 
        [> 41]
    )
) AS pivot_table
        Order By AgeSequence
        DROP TABLE #GestationalWeeksRange2
        DROP TABLE #AgeRange2


        -- Start: No of Surgeries dataset

        Create table #SurgeryType_VisitType
        (
            SN int,
            SurgeryDisplayName varchar(50),
            SurgeryType varchar(50),
            VisitType varchar(50)
        );

        insert into #SurgeryType_VisitType
        values
            (1, 'Emergency','Major', 'emergency' ),
			(2, 'Inpatient','Major', 'inpatient' ),
			(3, 'Emergency','Intermediate', 'emergency' ),
			(4, 'Inpatient','Intermediate', 'inpatient' ),
            (5, 'Outpatient', 'Minor', 'outpatient'),
            (6, 'Inpatient', 'Minor', 'inpatient'),
            (7, 'Emergency', 'Minor', 'emergency'),
            (8, 'Plaster', 'Plaster', '');


        Select SurgeryDisplayName,
            ISNULL(COUNT(case when Gender='Male' Then ISNULL(Gender,0) End),0 ) as MaleCount,
            ISNULL(COUNT(case when Gender='Female' Then ISNULL(Gender,0) End),0) as FemaleCount

        from #SurgeryType_VisitType sj
            left join
            (
    select pat.PatientId, pat.Gender, bt.ItemName, bp.Category, bt.VisitType
            from BIL_TXN_BillingTransactionItems bt
                inner join PAT_Patient pat on pat.PatientId = bt.PatientId
                Left JOIN BIL_CFG_BillItemPrice bp ON bt.ServiceDepartmentId = bp.ServiceDepartmentId and bt.ItemId = bp.ItemId
                INNER JOIN BIL_TXN_BillingTransaction inv ON bt.BillingTransactionId = inv.BillingTransactionId
                LEFT JOIN BIL_TXN_InvoiceReturnItems brtn ON bt.BillingTransactionItemId = brtn.BillingTransactionItemId

            WHERE bp.IsOT = 1
                And bt.DiscountAmount >0
                and bt.BillStatus !='cancel'
                AND bt.BillStatus != 'adtCancel'
                AND bt.BillStatus != 'provisional'
                AND brtn.BillReturnItemId IS NULL
                AND CONVERT(date,inv.CreatedOn) BETWEEN @FromDate AND @ToDate
  )AS dt on dt.Category = sj.SurgeryType and (dt.VisitType = sj.VisitType or sj.VisitType = '')
        Group by sj.SN, sj.SurgeryDisplayName
        ORDER BY sj.SN

        DROP TABLE #SurgeryType_VisitType
        -- End:  No of Surgeries dataset


        -- Start: Death data set
        SELECT Condition,
            COUNT (CASE WHEN Gender = 'Male' THEN IsNull(Gender,0)End) as MaleCount,
            COUNT (CASE WHEN Gender = 'Female' THEN IsNull(Gender,0)End) as FemaleCount
        FROM
            ( Select dct.DischargeConditionId, dct.Condition, dct.DischargeTypeId
            FROM ADT_MST_DischargeConditionType dct
                INNER JOIN ADT_DischargeType dt on dct.DischargeTypeId = dt.DischargeTypeId
            WHERE LOWER(dt.DischargeTypeName) ='death' and IsActive=1
    ) as deathTypes
            LEFT JOIN (
    select pat.PatientId, r.DischargeTypeId, r.DischargeConditionId, pat.Gender
            FROM MR_RecordSummary r
                INNER JOIN ADT_PatientAdmission adm
                on r.PatientVisitId=adm.PatientVisitId
                INNER JOIN PAT_Patient pat on pat.PatientId = r.PatientId
            WHERE
       CONVERT(date, adm.DischargeDate) BETWEEN @FromDate AND @ToDate
    ) as mr
            on mr.DischargeConditionId = deathTypes.DischargeConditionId and mr.DischargeTypeId = deathTypes.DischargeTypeId
        GROUP BY Condition
        ORDER by Condition


        -- End: Death data set


        create table #ExcemptionType
        (
            CostExemption varchar (50),
            exemptionRangeStart int,
            exemptionRangeEnd int,
        );
        insert into #ExcemptionType
        values
            ('Partially', 1, 99),
            ('Complete', 100, 100);


        Select patCount.CostExemption, patCount.NoOfPatient, costCal.ExemptedAmount
        from
            (
  -- Start: Partially or completely excemption amount calculation
  Select CostExemption, SUM(ISNULL(DiscountAmount,0)) as ExemptedAmount
            from #ExcemptionType et
                Left Join
                (
	--DiscountPercent calculation changed by sud: 30Aug'21----
    SELECT ISNULL(ISNULL(t.DiscountAmount,0)/ISNULL(NULLIF(t.SubTotal,0),1),0)*100 'DiscountPercent',
                    t.DiscountAmount
                FROM BIL_TXN_BillingTransactionItems  t
                    INNER JOIN BIL_TXN_BillingTransaction tx on t.BillingTransactionId = tx.BillingTransactionId
                    INNER JOIN BIL_TXN_BillingTransaction inv ON tx.BillingTransactionId = inv.BillingTransactionId
                    LEFT JOIN BIL_TXN_InvoiceReturnItems brtn ON t.BillingTransactionItemId = brtn.BillingTransactionItemId

                WHERE t.DiscountAmount >0 and t.BillStatus !='cancel'
                    AND t.BillStatus !='cancel' AND t.BillStatus != 'adtCancel'
                    AND t.BillStatus != 'provisional' AND brtn.BillReturnItemId IS NULL
                    AND CONVERT(date,inv.CreatedOn) BETWEEN @FromDate AND @ToDate

    ) as ft on ft.DiscountPercent between et.exemptionRangeStart and et.exemptionRangeEnd
            group by et.CostExemption
  -- Start: Partially or completely excemption amount calculation
  ) as costCal

            Inner Join
            (
  SELECT CostExemption,
                Count(ISNULL(PatientId,0)) as NoOfPatient
            from (
    Select distinct CostExemption, PatientId
                from #ExcemptionType et
                    Left Join
                    (
      SELECT ISNULL(ISNULL(t.DiscountAmount,0)/ISNULL(NULLIF(t.SubTotal,0),1),0)*100 'DiscountPercent',
                        t.PatientId
                    FROM BIL_TXN_BillingTransactionItems  t
                        INNER JOIN BIL_TXN_BillingTransaction tx on t.BillingTransactionId = tx.BillingTransactionId
                        INNER JOIN BIL_TXN_BillingTransaction inv ON tx.BillingTransactionId = inv.BillingTransactionId
                        LEFT JOIN BIL_TXN_InvoiceReturnItems brtn ON t.BillingTransactionItemId = brtn.BillingTransactionItemId

                    WHERE t.DiscountAmount >0 and t.BillStatus !='cancel'
                        AND t.BillStatus !='cancel' AND t.BillStatus != 'adtCancel'
                        AND t.BillStatus != 'provisional' AND brtn.BillReturnItemId IS NULL
                        AND CONVERT(date,inv.CreatedOn) BETWEEN @FromDate AND @ToDate

    ) as sft on sft.DiscountPercent between et.exemptionRangeStart and et.exemptionRangeEnd
  )as ft
            group by CostExemption
  ) as patCount on patCount.CostExemption = costCal.CostExemption

        Drop table #ExcemptionType

		
        -- Start: Free Health Service and Social Service Programme dataset

        Select
            MembershipTypeName,
            ISNULL(SUM ( case when VisitType ='outpatient' then PatCount End),0) as OutpatientsCount,
            ISNULL(SUM ( case when VisitType ='inpatient' then PatCount End),0) as InpatientsCount,
            ISNULL(SUM ( case when VisitType ='emergency' then PatCount End),0) as ErPatientsCount
        from (
  select MembershipTypeName, VisitType
    , Count(PatientId) as PatCount
            from
                (
    select distinct mt.MembershipTypeName, t.PatientId, t.VisitType
                from BIL_TXN_BillingTransactionItems t
                    inner join PAT_CFG_MembershipType mt on mt.MembershipTypeId = t.DiscountSchemeId
                    INNER JOIN BIL_TXN_BillingTransaction inv ON t.BillingTransactionId = inv.BillingTransactionId
                    LEFT JOIN BIL_TXN_InvoiceReturnItems brtn ON t.BillingTransactionItemId = brtn.BillingTransactionItemId

                WHERE LOWER(mt.CommunityName) ='social service unit'
                    And t.DiscountAmount >0 and t.BillStatus !='cancel'
                    AND t.BillStatus !='cancel' AND t.BillStatus != 'adtCancel'
                    AND t.BillStatus != 'provisional' AND brtn.BillReturnItemId IS NULL
                    AND CONVERT(date,inv.CreatedOn) BETWEEN @FromDate AND @ToDate

    ) as sft
            group by MembershipTypeName, VisitType

) as ft
        group by MembershipTypeName
    -- End : Free Health Service and Social Service Programme dataset 


select pt.Gender, COUNT(*) as caseCount from MR_RecordSummary mr
inner join PAT_PatientVisits pvs on pvs.PatientVisitId= mr.PatientVisitId
left join PAT_Patient pt on pt.PatientId= mr.PatientId
where mr.CaseMain='Medico-legal'
GROUP BY pt.Gender
    END
END