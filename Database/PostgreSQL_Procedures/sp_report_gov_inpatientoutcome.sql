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
CREATE OR REPLACE FUNCTION sp_report_gov_inpatientoutcome(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
    ref3 refcursor := 'cursor3';
    ref4 refcursor := 'cursor4';
    ref5 refcursor := 'cursor5';
    ref6 refcursor := 'cursor6';
    ref7 refcursor := 'cursor7';
    ref8 refcursor := 'cursor8';
BEGIN
    begin
        if(p_fromdate is not null or p_todate is not null or len(p_fromdate)>0 or len(p_todate)>0)
    then
    
            -- start: inpatient outcome data set
            -- start: inpatient outcome data set
            -- age range
    
            create temp table temp_agerange
            (
                ageserialno int,
                agerange varchar(100),
                agedisplayname varchar(100)
    
            );
            insert into temp_agerange
                (ageserialno, agerange,agedisplayname)
            values
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
                (12, '>=70Years','gt_70yr');
    
            -- gender range
            create temp table temp_genders
            (
                sn int,
                gender varchar(100)
            );
            insert into temp_genders
                ( gender)
            values
                ('Male'),
                ('Female');
            -- query starts from here
            select agerange, recovered_male, recovered_female,stable_male,stable_female, not_improved_male, 
    		not_improved_female, referred_male, referred_female, lama_male, 
    		lama_female,dor_male,dor_female, absconded_male, absconded_female, "death_lt48_male", 
    		"death_lt48_female", "death_gt48_male", "death_gt48_female"
            from
                (
            select
                "ageserialno",
                "agerange",
                coalesce(sum(case when "columnsheader" = 'Recovered_Male' then "patientcount" else 0 end), 0) as "recovered_male",
                coalesce(sum(case when "columnsheader" = 'Recovered_Female' then "patientcount" else 0 end), 0) as "recovered_female",
                coalesce(sum(case when "columnsheader" = 'Stable_Male' then "patientcount" else 0 end), 0) as "stable_male",
                coalesce(sum(case when "columnsheader" = 'Stable_Female' then "patientcount" else 0 end), 0) as "stable_female",
                coalesce(sum(case when "columnsheader" = 'Not_Improved_Male' then "patientcount" else 0 end), 0) as "not_improved_male",
                coalesce(sum(case when "columnsheader" = 'Not_Improved_Female' then "patientcount" else 0 end), 0) as "not_improved_female",
                coalesce(sum(case when "columnsheader" = 'Referred_Male' then "patientcount" else 0 end), 0) as "referred_male",
                coalesce(sum(case when "columnsheader" = 'Referred_Female' then "patientcount" else 0 end), 0) as "referred_female",
                coalesce(sum(case when "columnsheader" = 'LAMA_Male' then "patientcount" else 0 end), 0) as "lama_male",
                coalesce(sum(case when "columnsheader" = 'LAMA_Female' then "patientcount" else 0 end), 0) as "lama_female",
                coalesce(sum(case when "columnsheader" = 'DOR_Male' then "patientcount" else 0 end), 0) as "dor_male",
                coalesce(sum(case when "columnsheader" = 'DOR_Female' then "patientcount" else 0 end), 0) as "dor_female",
                coalesce(sum(case when "columnsheader" = 'Absconded_Male' then "patientcount" else 0 end), 0) as "absconded_male",
                coalesce(sum(case when "columnsheader" = 'Absconded_Female' then "patientcount" else 0 end), 0) as "absconded_female",
                coalesce(sum(case when "columnsheader" = 'Death_Lt48_Male' then "patientcount" else 0 end), 0) as "death_lt48_male",
                coalesce(sum(case when "columnsheader" = 'Death_Lt48_Female' then "patientcount" else 0 end), 0) as "death_lt48_female",
                coalesce(sum(case when "columnsheader" = 'Death_Gt48_Male' then "patientcount" else 0 end), 0) as "death_gt48_male",
                coalesce(sum(case when "columnsheader" = 'Death_Gt48_Female' then "patientcount" else 0 end), 0) as "death_gt48_female"
            from (
                
        
            select age.ageserialno, age.agerange, discharge.dischargetypename || '_' || gender.gender as columnsheader, 
    		sum(coalesce(patientcount,0)) as patientcount
                from temp_agerange age
                    left join temp_genders gender on 1=1
                    left join (select
                        case when de.deathtype is null then replace(dt.dischargetypename,' ','_') 
    					   else (case when de.deathtype = '<48' then dt.dischargetypename ||'_Lt48' 
    					         when de.deathtype = '>48' then dt.dischargetypename ||'_Gt48'  end ) end as dischargetypename,
                        isactive
                    from adt_dischargetype dt
                        left join adt_mst_deathtype de on dt.dischargetypeid = de.dischargetypeid
                    where dt.isactive =1
                        ) discharge on 1=1
                    left join
                    (
                        select *,
                        coalesce(count(*),0) as patientcount
                    from (
    								 select
                            case when dth.deathtype is null then replace(dt.dischargetypename,' ','_') 
    						   else (case when dth.deathtype = '<48' then dt.dischargetypename ||'_Lt48' 
    						          when dth.deathtype = '>48' then dt.dischargetypename ||'_Gt48'  end ) end as dischargetypename,
                            pat.gender,
                            "getdobagerangeinpatientoutcome" (pat.dateofbirth, adm.dischargedate) as agerange
                        from mr_recordsummary mr
                            inner join adt_patientadmission adm on mr.patientvisitid=adm.patientvisitid
                            left join pat_patient pat on pat.patientid = mr.patientid
                            left join adt_dischargetype  dt on dt.dischargetypeid = mr.dischargetypeid
                            left join adt_mst_deathtype dth on dth.deathtypeid = mr.deathperiodtypeid
    
                        where (adm.dischargedate)::date between p_fromdate and p_todate
    
    											) as gp
                    group by dischargetypename, gender, agerange
                        
                    ) mr on mr.dischargetypename = discharge.dischargetypename 
    				and mr.agerange = age.agerange and mr.gender = gender.gender
    
                where discharge.isactive = 1
                group by age.ageserialno,age.agerange, discharge.dischargetypename, gender.gender
    
    
            ) t
            group by "ageserialno", "agerange"
        ) pivot_table
    
            order by ageserialno;
    
            drop table if exists temp_agerange;
            drop table if exists temp_genders;
            -- end: inpatient outcome data set
    
    
    
            --start: gestational week vs gravida vs patient count
            -- create the table in the specified schema
            create temp table temp_gestationalweeksrange
            (
                rangedisplayname varchar(100),
                rangestartson float,
                rangeendson float
            );
            insert into temp_gestationalweeksrange
                (rangedisplayname,rangestartson, rangeendson)
            values
                ('22-27', 22, 27),
                ('28-36', 28, 36),
                ('37-41', 37, 41),
                ('> 41', 42, 999999);
    
    
            select gravidaname,
                "22-27" as gestweek1,
                "28-36" as gestweek2,
                "37-41" as gestweek3,
                "> 41" as gestweek4
            from (
            select
                "gravidaname",
                coalesce(sum(case when "rangedisplayname" = '22-27' then "patientcount" else 0 end), 0) as "22-27",
                coalesce(sum(case when "rangedisplayname" = '28-36' then "patientcount" else 0 end), 0) as "28-36",
                coalesce(sum(case when "rangedisplayname" = '37-41' then "patientcount" else 0 end), 0) as "37-41",
                coalesce(sum(case when "rangedisplayname" = '> 41' then "patientcount" else 0 end), 0) as "> 41"
            from (
                
        select g.gravitaname as gravidaname, gwr.rangedisplayname, sum(coalesce(gravidadata.patientcount,0)) as patientcount
                from adt_mst_gravita g
                    inner join temp_gestationalweeksrange gwr on 1 = 1
                    left join
                    (
            select
                        gestationalweek, mrs.gravitaid, count(*) as "patientcount"
                    from mr_recordsummary mrs
                        inner join pat_patient p on mrs.patientid = p.patientid
                        inner join adt_patientadmission adm on mrs.patientvisitid=adm.patientvisitid
                        left join adt_mst_dischargeconditiontype dcon on dcon.dischargeconditionid = mrs.dischargeconditionid
                    where lower(dcon.condition) = 'delivery' and p.gender = 'Female'
                        and (adm.dischargedate)::date between p_fromdate and p_todate
                    group by mrs.gestationalweek, mrs.gravitaid
        ) gravidadata on
        gravidadata.gravitaid = g.gravitaid and gravidadata.gestationalweek between  gwr.rangestartson  and gwr.rangeendson
                group by g.gravitaname, gwr.rangedisplayname
    
            ) t
            group by "gravidaname"
        ) pivot_table;
            drop table "temp_gestationalweeksrange";
            --end: gestational week vs gravida vs patient count
    
    
    
    
            --temporary gestational table
            create temp table temp_gestationalweeksrange2
            (
                rangedisplayname varchar(100),
                rangestartson float,
                rangeendson float
            );
            insert into temp_gestationalweeksrange2
                (rangedisplayname,rangestartson, rangeendson)
            values
                ('22-27', 22, 27),
                ('28-36', 28, 36),
                ('37-41', 37, 41),
                ('> 41', 42, 999999);
    
            -- temporary age table
            create temp table temp_agerange2
            (
                agesequence int,
                agedisplayname varchar(100)
            );
    
    
            insert into temp_agerange2
                (agesequence,agedisplayname)
            values
                (1, '<20'),
                (2, '20-34'),
                (3, '>34');
    
    
    
            select agerange,
                "22-27" as gestweek1,
                "28-36" as gestweek2,
                "37-41" as gestweek3,
                "> 41" as gestweek4
            from
                (
            select
                "agesequence",
                "agerange",
                coalesce(sum(case when "gestationalweek" = '22-27' then "patientcount" else 0 end), 0) as "22-27",
                coalesce(sum(case when "gestationalweek" = '28-36' then "patientcount" else 0 end), 0) as "28-36",
                coalesce(sum(case when "gestationalweek" = '37-41' then "patientcount" else 0 end), 0) as "37-41",
                coalesce(sum(case when "gestationalweek" = '> 41' then "patientcount" else 0 end), 0) as "> 41"
            from (
                
        select ar.agesequence, ar.agedisplayname as "agerange", gwr.rangedisplayname as "gestationalweek", sum(coalesce(agegestationaldata.patientcount,0)) as "patientcount"
                from temp_gestationalweeksrange2 gwr
                    inner join temp_agerange2 ar on 1=1
                    left join
                    (
    		   select *,
                        count(*) as "patientcount"
                    from
                        (
    				select
                            mrs.gestationalweek,
                            "getdobagerangegestationalweek"(p.dateofbirth, adm.dischargedate) as agerange
    
                        from mr_recordsummary mrs
                            inner join pat_patient p on mrs.patientid = p.patientid
                            inner join adt_patientadmission adm on mrs.patientvisitid=adm.patientvisitid
                            left join adt_mst_dischargeconditiontype dcon on dcon.dischargeconditionid = mrs.dischargeconditionid
                        where lower(dcon.condition) = 'delivery' and p.gender = 'Female'
                            and (adm.dischargedate)::date between p_fromdate and p_todate
    			) mr
                    group by  gestationalweek, agerange
    
        ) agegestationaldata
                    on agegestationaldata.gestationalweek  between  gwr.rangestartson  and gwr.rangeendson and
                        agegestationaldata.agerange = ar.agedisplayname
                group by ar.agesequence ,ar.agedisplayname, gwr.rangedisplayname
    
            ) t
            group by "agesequence", "agerange"
        ) pivot_table
            order by agesequence;
            drop table if exists temp_gestationalweeksrange2;
            drop table if exists temp_agerange2;
    
    
            -- start: no of surgeries dataset
    
            create temp table temp_surgerytype_visittype
            (
                sn int,
                surgerydisplayname varchar(50),
                surgerytype varchar(50),
                visittype varchar(50)
            );
    
            insert into temp_surgerytype_visittype
            values
                (1, 'Emergency','Major', 'emergency' ),
    			(2, 'Inpatient','Major', 'inpatient' ),
    			(3, 'Emergency','Intermediate', 'emergency' ),
    			(4, 'Inpatient','Intermediate', 'inpatient' ),
                (5, 'Outpatient', 'Minor', 'outpatient'),
                (6, 'Inpatient', 'Minor', 'inpatient'),
                (7, 'Emergency', 'Minor', 'emergency'),
                (8, 'Plaster', 'Plaster', '');
    
    
            select surgerydisplayname,
                coalesce(count(case when gender='Male' then coalesce(gender,0) end),0 ) as malecount,
                coalesce(count(case when gender='Female' then coalesce(gender,0) end),0) as femalecount
    
            from temp_surgerytype_visittype sj
                left join
                (
        select pat.patientid, pat.gender, bt.itemname, bp.category, bt.visittype
                from bil_txn_billingtransactionitems bt
                    inner join pat_patient pat on pat.patientid = bt.patientid
                    left join bil_cfg_billitemprice bp on bt.servicedepartmentid = bp.servicedepartmentid and bt.itemid = bp.itemid
                    inner join bil_txn_billingtransaction inv on bt.billingtransactionid = inv.billingtransactionid
                    left join bil_txn_invoicereturnitems brtn on bt.billingtransactionitemid = brtn.billingtransactionitemid
    
                where bp.isot = 1
                    and bt.discountamount >0
                    and bt.billstatus !='cancel'
                    and bt.billstatus != 'adtCancel'
                    and bt.billstatus != 'provisional'
                    and brtn.billreturnitemid is null
                    and (inv.createdon)::date between p_fromdate and p_todate
      )as dt on dt.category = sj.surgerytype and (dt.visittype = sj.visittype or sj.visittype = '')
            group by sj.sn, sj.surgerydisplayname
            order by sj.sn;
    
            drop table if exists temp_surgerytype_visittype;
            -- end:  no of surgeries dataset
    
    
            -- start: death data set
            open ref1 for select condition,
                count (case when gender = 'Male' then coalesce(gender,0)end) as malecount,
                count (case when gender = 'Female' then coalesce(gender,0)end) as femalecount
            from
                ( select dct.dischargeconditionid, dct.condition, dct.dischargetypeid
                from adt_mst_dischargeconditiontype dct
                    inner join adt_dischargetype dt on dct.dischargetypeid = dt.dischargetypeid
                where lower(dt.dischargetypename) ='death' and isactive=1
        ) as deathtypes
                left join (
        select pat.patientid, r.dischargetypeid, r.dischargeconditionid, pat.gender
                from mr_recordsummary r
                    inner join adt_patientadmission adm
                    on r.patientvisitid=adm.patientvisitid
                    inner join pat_patient pat on pat.patientid = r.patientid
                where
           (adm.dischargedate)::date between p_fromdate and p_todate
        ) as mr
                on mr.dischargeconditionid = deathtypes.dischargeconditionid and mr.dischargetypeid = deathtypes.dischargetypeid
            group by condition
            order by condition;
        return next ref1;
    
    
            -- end: death data set
    
    
            create temp table temp_excemptiontype
            (
                costexemption varchar (50),
                exemptionrangestart int,
                exemptionrangeend int);
            insert into temp_excemptiontype
            values
                ('Partially', 1, 99),
                ('Complete', 100, 100);
    
    
            select patcount.costexemption, patcount.noofpatient, costcal.exemptedamount
            from
                (
      -- start: partially or completely excemption amount calculation
      select costexemption, sum(coalesce(discountamount,0)) as exemptedamount
                from temp_excemptiontype et
                    left join
                    (
    	--discountpercent calculation changed by sud: 30aug'21----
        SELECT COALESCE(COALESCE(t.DiscountAmount,0)/COALESCE(NULLIF(t.SubTotal,0),1),0)*100 AS "DiscountPercent",
                        t.DiscountAmount
                    FROM BIL_TXN_BillingTransactionItems  t
                        INNER JOIN BIL_TXN_BillingTransaction tx on t.BillingTransactionId = tx.BillingTransactionId
                        INNER JOIN BIL_TXN_BillingTransaction inv ON tx.BillingTransactionId = inv.BillingTransactionId
                        LEFT JOIN BIL_TXN_InvoiceReturnItems brtn ON t.BillingTransactionItemId = brtn.BillingTransactionItemId
    
                    WHERE t.DiscountAmount >0 and t.BillStatus !='cancel'
                        AND t.BillStatus !='cancel' AND t.BillStatus != 'adtcancel'
                        AND t.BillStatus != 'provisional' AND brtn.BillReturnItemId IS NULL
                        AND (inv.CreatedOn)::date BETWEEN p_fromdate AND p_todate
    
        ) as ft on ft.DiscountPercent between et.exemptionRangeStart and et.exemptionRangeEnd
                group by et.CostExemption
      -- Start: Partially or completely excemption amount calculation
      ) as costCal
    
                Inner Join
                (
      SELECT CostExemption,
                    Count(COALESCE(PatientId,0)) as NoOfPatient
                from (
        Select distinct CostExemption, PatientId
                    from temp_ExcemptionType et
                        Left Join
                        (
          SELECT COALESCE(COALESCE(t.DiscountAmount,0)/COALESCE(NULLIF(t.SubTotal,0),1),0)*100 AS "DiscountPercent",
                            t.PatientId
                        FROM BIL_TXN_BillingTransactionItems  t
                            INNER JOIN BIL_TXN_BillingTransaction tx on t.BillingTransactionId = tx.BillingTransactionId
                            INNER JOIN BIL_TXN_BillingTransaction inv ON tx.BillingTransactionId = inv.BillingTransactionId
                            LEFT JOIN BIL_TXN_InvoiceReturnItems brtn ON t.BillingTransactionItemId = brtn.BillingTransactionItemId
    
                        WHERE t.DiscountAmount >0 and t.BillStatus !='cancel'
                            AND t.BillStatus !='cancel' AND t.BillStatus != 'adtcancel'
                            AND t.BillStatus != 'provisional' AND brtn.BillReturnItemId IS NULL
                            AND (inv.CreatedOn)::date BETWEEN p_fromdate AND p_todate
    
        ) as sft on sft.DiscountPercent between et.exemptionRangeStart and et.exemptionRangeEnd
      )as ft
                group by CostExemption
      ) as patCount on patCount.CostExemption = costCal.CostExemption;
    
            DROP TABLE IF EXISTS temp_ExcemptionType;
    
    		
            -- Start: Free Health Service and Social Service Programme dataset
    
            OPEN ref2 FOR Select
                MembershipTypeName,
                COALESCE(SUM ( case when VisitType ='outpatient' then PatCount End),0) as OutpatientsCount,
                COALESCE(SUM ( case when VisitType ='inpatient' then PatCount End),0) as InpatientsCount,
                COALESCE(SUM ( case when VisitType ='emergency' then PatCount End),0) as ErPatientsCount
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
                        AND t.BillStatus !='cancel' AND t.BillStatus != 'adtcancel'
                        AND t.BillStatus != 'provisional' AND brtn.BillReturnItemId IS NULL
                        AND (inv.CreatedOn)::date BETWEEN p_fromdate AND p_todate
    
        ) as sft
                group by MembershipTypeName, VisitType
    
    ) as ft
            group by MembershipTypeName;
        RETURN NEXT ref2;
        -- End : Free Health Service and Social Service Programme dataset 
    
    
    OPEN ref3 FOR select pt.Gender, COUNT(*) as caseCount from MR_RecordSummary mr
    inner join PAT_PatientVisits pvs on pvs.PatientVisitId= mr.PatientVisitId
    left join PAT_Patient pt on pt.PatientId= mr.PatientId
    where mr.CaseMain='medico-legal'
    group by pt.gender;
        return next ref3;
        end if;
    end;
END;
$$ LANGUAGE plpgsql;