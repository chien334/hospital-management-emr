CREATE OR REPLACE FUNCTION sp_report_gov_inpatientmorbidity(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL
)
RETURNS TABLE (
    "ICDCode" VARCHAR,
    "ICDCodeName" VARCHAR,
    "v0Day_to_7_Days_Female" VARCHAR,
    "v0Day_to_7_Days_Male" VARCHAR,
    "v8Day_to_28_Days_Female" VARCHAR,
    "v8Day_to_28_Days_Male" VARCHAR,
    "v29Days_to_1yr_Female" VARCHAR,
    "v29Days_to_1yr_Male" VARCHAR,
    "v1yr_to_4yr_Female" VARCHAR,
    "v1yr_to_4yr_Male" VARCHAR,
    "v5yr_to_14yr_Female" VARCHAR,
    "v5yr_to_14yr_Male" VARCHAR,
    "v15yr_to_19yr_Female" VARCHAR,
    "v15yr_to_19yr_Male" VARCHAR,
    "v20yr_to_29yr_Female" VARCHAR,
    "v20yr_to_29yr_Male" VARCHAR,
    "v30yr_to_39yr_Female" VARCHAR,
    "v30yr_to_39yr_Male" VARCHAR,
    "v40yr_to_49yr_Female" VARCHAR,
    "v40yr_to_49yr_Male" VARCHAR,
    "v50yr_to_59yr_Female" VARCHAR,
    "v50yr_to_59yr_Male" VARCHAR,
    "v60yr_to_69yr_Female" VARCHAR,
    "v60yr_to_69yr_Male" VARCHAR,
    "gt_70yr_Female" VARCHAR,
    "gt_70yr_Male" VARCHAR,
    "TotalDeaths_Female" DECIMAL,
    "TotalDeaths_Male" DECIMAL
) AS $$
BEGIN
    /*
    filename: "sp_report_gov_inpatientmorbidity"
    createdby/date: bikash/sudarshan/2021-09-14
    description: to get inpatient disease wise (morbidity)  data.
    remarks:
                
    change history
    s.no.    updatedby/date							 remarks
    1.       bikash/sud: 30sept'21                Corrected for Death Count taking from separate table..
    2.		 Prem: 2th March '22				  corrected for diagnoisis based patient count.
    */
    
    
      -- age range
    	create temp table temp_agerange
    	(
    		ageserialno int,
    		agerange varchar(100)
    	);
    	insert into temp_agerange
    		(ageserialno, agerange)
    	values
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
                (12, '>=70Years');
    
    	-- gender range
    	create temp table temp_genders
    	(
    		gender varchar(100)
    	);
    	insert into temp_genders
    		( gender)
    	values
    		('Male'),
    		('Female');
    
    		-- query started --- 
    
    	RETURN QUERY SELECT  icd10code AS "ICDCode", icd10name AS "ICDCodeName",
    			sum(coalesce("0-7days_female",0)) AS "v0Day_to_7_Days_Female",
    			sum(coalesce("0-7days_male",0)) AS "v0Day_to_7_Days_Male",
    			sum(coalesce("8-28days_female",0)) AS "v8Day_to_28_Days_Female",
    			sum(coalesce("8-28days_male",0)) AS "v8Day_to_28_Days_Male",
    			sum(coalesce("29days-1year_female",0)) AS "v29Days_to_1yr_Female",		
    			sum(coalesce("29days-1year_male",0)) AS "v29Days_to_1yr_Male",
    			sum(coalesce("01-04years_female",0)) AS "v1yr_to_4yr_Female",
    			sum(coalesce("01-04years_male",0)) AS "v1yr_to_4yr_Male",
    			sum(coalesce("05-14years_female",0)) AS "v5yr_to_14yr_Female",
    			sum(coalesce("05-14years_male",0)) AS "v5yr_to_14yr_Male",
    			sum(coalesce("15-19years_female",0)) AS "v15yr_to_19yr_Female",
    			sum(coalesce("15-19years_male",0)) AS "v15yr_to_19yr_Male",
    			sum(coalesce("20-29years_female",0)) AS "v20yr_to_29yr_Female",
    			sum(coalesce("20-29years_male",0)) AS "v20yr_to_29yr_Male",
    			sum(coalesce("30-39years_female",0)) AS "v30yr_to_39yr_Female",
    			sum(coalesce("30-39years_male",0)) AS "v30yr_to_39yr_Male",
    			sum(coalesce("40-49years_female",0)) AS "v40yr_to_49yr_Female",
    			sum(coalesce("40-49years_male",0)) AS "v40yr_to_49yr_Male",
    			sum(coalesce("50-59years_female",0)) AS "v50yr_to_59yr_Female",
    			sum(coalesce("50-59years_male",0)) AS "v50yr_to_59yr_Male",
    			sum(coalesce("60-69years_female",0)) AS "v60yr_to_69yr_Female",
    			sum(coalesce("60-69years_male",0)) AS "v60yr_to_69yr_Male",
    			sum(coalesce(">=70years_female",0)) AS "gt_70yr_Female",
    			sum(coalesce(">=70years_male",0)) AS "gt_70yr_Male"	,	
    		
    			sum(coalesce(totaldeaths_female,0)) AS "TotalDeaths_Female",
    			sum(coalesce(totaldeaths_male,0)) AS "TotalDeaths_Male"
    
    	from
    		(
            select
                "icd10name",
                "icd10code",
                "totaldeaths_male",
                "totaldeaths_female",
                coalesce(sum(case when "columnheaders" = '0-7Days_Female' then "totalpatientcount" else 0 end), 0) as "0-7days_female",
                coalesce(sum(case when "columnheaders" = '0-7Days_Male' then "totalpatientcount" else 0 end), 0) as "0-7days_male",
                coalesce(sum(case when "columnheaders" = '8-28Days_Female' then "totalpatientcount" else 0 end), 0) as "8-28days_female",
                coalesce(sum(case when "columnheaders" = '8-28Days_Male' then "totalpatientcount" else 0 end), 0) as "8-28days_male",
                coalesce(sum(case when "columnheaders" = '29Days-1Year_Male' then "totalpatientcount" else 0 end), 0) as "29days-1year_male",
                coalesce(sum(case when "columnheaders" = '29Days-1Year_Female' then "totalpatientcount" else 0 end), 0) as "29days-1year_female",
                coalesce(sum(case when "columnheaders" = '01-04Years_Male' then "totalpatientcount" else 0 end), 0) as "01-04years_male",
                coalesce(sum(case when "columnheaders" = '01-04Years_Female' then "totalpatientcount" else 0 end), 0) as "01-04years_female",
                coalesce(sum(case when "columnheaders" = '05-14Years_Male' then "totalpatientcount" else 0 end), 0) as "05-14years_male",
                coalesce(sum(case when "columnheaders" = '05-14Years_Female' then "totalpatientcount" else 0 end), 0) as "05-14years_female",
                coalesce(sum(case when "columnheaders" = '15-19Years_Male' then "totalpatientcount" else 0 end), 0) as "15-19years_male",
                coalesce(sum(case when "columnheaders" = '15-19Years_Female' then "totalpatientcount" else 0 end), 0) as "15-19years_female",
                coalesce(sum(case when "columnheaders" = '20-29Years_Male' then "totalpatientcount" else 0 end), 0) as "20-29years_male",
                coalesce(sum(case when "columnheaders" = '20-29Years_Female' then "totalpatientcount" else 0 end), 0) as "20-29years_female",
                coalesce(sum(case when "columnheaders" = '30-39Years_Male' then "totalpatientcount" else 0 end), 0) as "30-39years_male",
                coalesce(sum(case when "columnheaders" = '30-39Years_Female' then "totalpatientcount" else 0 end), 0) as "30-39years_female",
                coalesce(sum(case when "columnheaders" = '40-49Years_Male' then "totalpatientcount" else 0 end), 0) as "40-49years_male",
                coalesce(sum(case when "columnheaders" = '40-49Years_Female' then "totalpatientcount" else 0 end), 0) as "40-49years_female",
                coalesce(sum(case when "columnheaders" = '50-59Years_Male' then "totalpatientcount" else 0 end), 0) as "50-59years_male",
                coalesce(sum(case when "columnheaders" = '50-59Years_Female' then "totalpatientcount" else 0 end), 0) as "50-59years_female",
                coalesce(sum(case when "columnheaders" = '60-69Years_Female' then "totalpatientcount" else 0 end), 0) as "60-69years_female",
                coalesce(sum(case when "columnheaders" = '60-69Years_Male' then "totalpatientcount" else 0 end), 0) as "60-69years_male",
                coalesce(sum(case when "columnheaders" = '>=70Years_Female' then "totalpatientcount" else 0 end), 0) as ">=70years_female",
                coalesce(sum(case when "columnheaders" = '>=70Years_Male' then "totalpatientcount" else 0 end), 0) as ">=70years_male"
            from (
                
    			select displaydata.columnheaders, displaydata.icd10name, displaydata.icd10code,
    					sum(coalesce(totalpatient,0)) as totalpatientcount,
    					sum (coalesce(deathonly.malecount,0)) AS "TotalDeaths_Male",
    					sum (coalesce(deathonly.femalecount,0)) AS "TotalDeaths_Female"
    			from
    				(
    					select icd10code,icd10name, agerange || '_' || gender as columnheaders, ageserialno
    					from 				
    					(					
    							select distinct i.icd10code, i.icd10name
    							from mr_recordsummary mrec
    							--inner join pat_patient p on mrec.patientid = p.patientid
    							inner join adt_patientadmission adm on adm.patientvisitid=mrec.patientvisitid
    							inner join mr_txn_inpatient_diagnosis i on mrec.medicalrecordid=i.medicalrecordid
    							where (adm.dischargedate)::date between p_fromdate and p_todate
    							and i.isactive!=0
    					) as diseased
    					left join
    					(
    						select age.ageserialno,age.agerange, gender.gender
    						from temp_agerange age
    						left join temp_genders gender on 1=1
    					) agegender
    					on 1 = 1 
    				) 
    				as displaydata
    					left join
    					(
    						select  icd10code, icd10name, agerange || '_' || gender as columnheaders, 
    						sum(patientcount) as "totalpatient"
    						--,sum( case when dischargetypename='Death' and gender='Male' then patientcount else 0 end) as death_male
    						--,sum( case when dischargetypename='Death' and gender='Female' then patientcount else 0 end) as death_female
    						from
    							(
    								select age.agerange, discharge.dischargetypename, gender.gender, 
    									sum(coalesce(patientcount,0)) as patientcount, mr.icd10id, mr.icd10code, mr.icd10name
    								from temp_agerange age
    									left join temp_genders gender on 1=1
    									left join adt_dischargetype discharge on 1=1
    									inner join 
    									(
    										select *, coalesce(count(*),0) as patientcount
    										from
    											(
    												select mrec.dischargetypeid, 
    												"getdobagerangeinpatientoutcome" (p.dateofbirth, adm.dischargedate) as agerange, 
    												p.gender,i.icd10id, i.icd10code, i.icd10name
    												from mr_recordsummary mrec
    													inner join pat_patient p on mrec.patientid = p.patientid
    													inner join adt_patientadmission adm on adm.patientvisitid=mrec.patientvisitid
    													inner join mr_txn_inpatient_diagnosis i on mrec.medicalrecordid=i.medicalrecordid
    													where (adm.dischargedate)::date between p_fromdate and p_todate
    													and i.isactive!=0
    											) initdata
    										group by initdata.dischargetypeid, 
    										initdata.agerange,initdata.gender, 
    										icd10id, icd10code, icd10name
    
    									) mr on mr.dischargetypeid = discharge.dischargetypeid 
    											and age.agerange = mr.agerange
    											and lower(mr.gender) = lower(gender.gender)
    								where discharge.isactive = 1
    								group by age.agerange, discharge.dischargetypename, gender.gender,
    								mr.icd10id,mr.icd10code,mr.icd10name
    							) t
    						group by  agerange, gender,  icd10code, icd10name
    					)countdata 
    				on countdata.columnheaders = displaydata.columnheaders and countdata.icd10code = displaydata.icd10code
    
    				left join (
    						select ipdiag.icd10id, ipdiag.icd10code, ipdiag.icd10name, 
    						   sum( case when pat.gender='Male' then 1 else  0 end) as malecount,
    						   sum(case when pat.gender='Female' then 1 else 0 end) as femalecount
    						from mr_recordsummary mr 
    							inner join pat_patientvisits vis on mr.patientvisitid=vis.patientvisitid
    							inner join adt_patientadmission adm on vis.patientvisitid= adm.patientvisitid 
    							inner join adt_dischargetype disctype on mr.dischargetypeid=disctype.dischargetypeid
    							left join mr_txn_inpatient_diagnosis ipdiag on ipdiag.medicalrecordid=mr.medicalrecordid
    							inner join pat_patient pat on pat.patientid= mr.patientid
    						where adm.admissionstatus='discharged'
    							  and (adm.dischargedate)::date between p_fromdate and p_todate
    							  and disctype.dischargetypename='Death'
    							  and ipdiag.isactive!=0
    						group by ipdiag.icd10id,
    							 ipdiag.icd10code, ipdiag.icd10name
    			
    				) deathonly on displaydata.icd10code=deathonly.icd10code 
    
    			group by  displaydata.columnheaders, displaydata.icd10name, displaydata.icd10code
    		
    	
            ) ft
            group by "icd10name", "icd10code", "totaldeaths_male", "totaldeaths_female"
        ) pivot_table
    	group by icd10name, icd10code
    	order by  icd10name;
    
    	--drop temporary tables---
    	drop table if exists temp_agerange;
    	drop table if exists temp_genders;
END;
$$ LANGUAGE plpgsql;