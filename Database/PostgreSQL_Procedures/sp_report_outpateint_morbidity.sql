CREATE OR REPLACE FUNCTION sp_report_outpateint_morbidity(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
    ref3 refcursor := 'cursor3';
BEGIN
    /************************************************************************
    filename: "sp_report_outpatient_morbidity "   
    createdby/date: prem/bikash: 16th feb,2022
    description: to get details of outpatient morbidity report in mr
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1.    prem/bikash						sp for outpatient morbidity report in mr
    2.    prem								emergency patient removed.
    3.    nirmala                           fetched totalmalenewopdvisits,totalfemalenewopdvisits,totalmaleoldopdvisits,totalfemaleoldopdvisits 
    *************************************************************************/
    
    
    
    
    	-- table 1
    	
    open ref1 for select reportinggroupid, reportinggroupname,icdversion, '"' || string_agg(diseasesgroup, ',') || '"' as diseasesgroup
    from 
    (
    	select 
    			reportinggroupid,reportinggroupname,icdversion,
    			((select row_to_json(t) from (select serialnumber,
    				diseasegroupname,
    				icdcode,
    				sum (coalesce(femalecount,0)) as numberoffemale,
    				sum (coalesce(malecount,0)) as numberofmale ,		
    				sum (coalesce(othergendercount,0)) as numberofothergender) as "t")::text 
    			) as diseasesgroup	
    		--into temp_reportgroupdata$
    		from
    		(
    			select 
    				serialnumber,diseasegroupname,reportinggroupname,icdcode,reportinggroupid,icdversion,
    				case when gender ='Male' then sum(coalesce(patientcount,0)) end as malecount,
    				case when gender ='Female' then sum(coalesce(patientcount,0)) end as femalecount,
    				case when gender ='Other' then sum(coalesce(patientcount,0)) end as othergendercount
    
    	
    			from (
    				select  
    					dg.serialnumber, 
    					dg.diseasegroupname,
    					rg.reportinggroupid,
    					rg.groupcode || ' ' || rg.reportinggroupname as reportinggroupname,
    					dg.icdcode,
    					dt.gender, 
    					dt.patientcount,
    					rg.icdversion
    				
    		
    				from icd_reportinggroup rg
    				inner join icd_diseasegroup dg on rg.reportinggroupid=dg.reportinggroupid 
    				left join	 
    					(
    						select micd.icd10code,  pat.gender,
    						count(*) as patientcount
    						from mr_txn_outpatient_finaldiagnosis fd
    						inner join pat_patient pat  on fd.patientid = pat.patientid
    						inner join pat_patientvisits patv on fd.patientvisitid=patv.patientvisitid
    						inner join mst_icd10 micd on fd.icd10id = micd.icd10id
    						where patv.visittype ='outpatient' and patv.billingstatus!='returned' and (patv.visitdate)::date between
    						p_fromdate and p_todate and fd.isactive!=0
    						group by gender, micd.icd10id, icd10code
    					)dt on dt.icd10code = dg.icdcode	
    			)sft
    			group by diseasegroupname,reportinggroupname,reportinggroupid, serialnumber, icdcode, gender,icdversion
    	
    	)ft
    	group by serialnumber,reportinggroupid,reportinggroupname,diseasegroupname,icdcode,icdversion
    ) reportgroupdata$
    group by reportinggroupid, reportinggroupname,icdversion;
        return next ref1;
    
    
    
    
    	open ref2 for select
    		gt.gender, coalesce(ft.malecountoicd, 0) as malecountoicd, coalesce(ft.femalecountoicd,0) as femalecountoicd
    	from 
    	(
    		select * 
    		from (values ('Female'), ('Male')) x(gender) 
    	) as gt
    	left join
    	(
    		select
    				gender,
    				case when gender ='Male' then count(*) else 0 end as malecountoicd,
    				case when gender ='Female' then count(*)else 0 end as femalecountoicd
    
    			from mr_txn_outpatient_finaldiagnosis fd
    			inner join pat_patient pat  on fd.patientid = pat.patientid
    			inner join pat_patientvisits patv on fd.patientvisitid = patv.patientvisitid
    			inner join mst_icd10 micd on fd.icd10id = micd.icd10id
    			where micd.icd10code not in (select icdcode from icd_diseasegroup)
    			and fd.isactive !=0 
    			and patv.visittype='outpatient'
    			and patv.billingstatus!='returned' 
    			and (patv.visitdate)::date between
    			p_fromdate and p_todate 
    			group by gender
    	)ft on ft.gender=gt.gender;
        return next ref2;
    			
    
    	
    	open ref3 for select
        sum(case when patientvisittype = 'new' and gender = 'Male' then countbyapptype else 0 end) as totalmalenewopdvisits,
        sum(case when patientvisittype = 'new' and gender = 'Female' then countbyapptype else 0 end) as totalfemalenewopdvisits,
        sum(case when patientvisittype = 'old' and gender = 'Male' then countbyapptype else 0 end) as totalmaleoldopdvisits,
        sum(case when patientvisittype = 'old' and gender = 'Female' then countbyapptype else 0 end) as totalfemaleoldopdvisits
    from
    (
        select
            visittbl.patientvisittype,
            patienttbl.gender,
            count(*) as countbyapptype
        from
        ( 
            select 
                patientid,
                patientvisitid,
    			-- if appointment type is 'Followup' or 'referral' or 'transfer' then patientvisittype is regarded as old 
                case when appointmenttype = 'new' then 'new' else 'old' end as patientvisittype 
            from pat_patientvisits
            where
                visittype != 'inpatient'
                and billingstatus != 'returned'
                and (visitdate)::date between p_fromdate and p_todate
        ) as visittbl
        inner join pat_patient as patienttbl on visittbl.patientid = patienttbl.patientid
        group by visittbl.patientvisittype, patienttbl.gender
    ) as ft;
        return next ref3;
END;
$$ LANGUAGE plpgsql;