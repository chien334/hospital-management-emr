CREATE OR REPLACE FUNCTION sp_report_emergencypatient_morbidity(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL
)
RETURNS TABLE (
    "EMER_ReportingGroupId" INT,
    "ReportingGroupName" VARCHAR,
    "DiseasesGroup" VARCHAR
) AS $$
BEGIN
    /************************************************************************
    filename: "sp_report_outpatient_morbidity "
    createdby/date: prem: 14th nov,2022
    description: to get details of emergency patient morbidity report in mr
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1.    prem					sp for emergency morbidity report in mr
    *************************************************************************/
    
    create temp table temp_reportgroupdata$ as select 
    		emer_reportinggroupid,reportinggroupname,
    		((select row_to_json(t) from (select serialnumber,icdcode,
    			emer_diseasegroupname,
    			sum (coalesce(femalecount,0)) as numberoffemale,
    			sum (coalesce(malecount,0)) as numberofmale ,		
    			sum (coalesce(othergendercount,0)) as numberofothergender) as "t")::text 
    		) AS "DiseasesGroup"	
    	
    	from
    	(
    		select 
    			serialnumber,reportinggroupname,emer_diseasegroupname,emer_reportinggroupid,icdcode,
    			case when gender ='Male' then sum(coalesce(patientcount,0)) end as malecount,
    			case when gender ='Female' then sum(coalesce(patientcount,0)) end as femalecount,
    			case when gender ='Other' then sum(coalesce(patientcount,0)) end as othergendercount
    	
    		from (
    			select dg.serialnumber,dg.icdcode,
    				   rp.groupcode ||' '||rp.emer_reportinggroupname AS "ReportingGroupName",
    				   dg.emer_diseasegroupname,temp.gender,temp.patientcount,rp.emer_reportinggroupid 
    		    from icd_emergency_reportinggroup rp 
    			inner join icd_emergency_diseasegroup dg on dg.emer_reportinggroupid=rp.emer_reportinggroupid
    			left join
    			(
    			    select
    				 dg.emer_diseasegroupid ,pt.gender,count(*) as patientcount,dg.icdcode
    				from mr_txn_emergency_finaldiagnosis fd
    				inner join icd_emergency_diseasegroup dg on fd.emer_diseasegroupid=dg.emer_diseasegroupid
    				inner join pat_patientvisits pv on pv.patientvisitid=fd.patientvisitid
    				inner join pat_patient pt on pt.patientid = fd.patientid
    				where fd.isactive=1 and pv.billingstatus!='returned' and (pv.visitdate)::date between
    				p_fromdate and p_todate
    				group by  dg.emer_diseasegroupid,pt.gender,dg.icdcode
    			)temp on temp.emer_diseasegroupid= dg.emer_diseasegroupid			
    			)ft
    			group by emer_diseasegroupname,reportinggroupname,emer_reportinggroupid, serialnumber, gender,icdcode
    			)fr
    	group by serialnumber,emer_reportinggroupid,reportinggroupname,emer_diseasegroupname,icdcode
    	order by serialnumber asc;
    
    	RETURN QUERY SELECT emer_reportinggroupid,reportinggroupname , '"' || string_agg(diseasesgroup, ',') || '"' AS "DiseasesGroup"
    	from temp_reportgroupdata$
    	group  by emer_reportinggroupid, reportinggroupname;
END;
$$ LANGUAGE plpgsql;