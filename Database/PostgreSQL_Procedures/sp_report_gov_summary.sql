CREATE OR REPLACE FUNCTION sp_report_gov_summary(
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
    ref9 refcursor := 'cursor9';
    v_vaccdepartmentname VARCHAR := (Select  ParameterValue from CORE_CFG_Parameters where ParameterName='immunizationdeptname' 
													 and ParameterGroupName='Common' LIMIT 1);
    v_deptid INT := (Select  DepartmentId from MST_Department where DepartmentName=v_vaccdepartmentname LIMIT 1);
BEGIN
    
    
    	
    	   open ref1 for select * from fn_mr_hospsummary_getopanderservices(p_fromdate,p_todate);
        return next ref1;
    
    		-- table 2
    		-- diagnosis and other services
    		open ref2 for select reportingitemname, unit, totalcount
    		from fn_mr_hospsummary_getdiagnosticandotherservices(p_fromdate,p_todate)
    		order by orderpriority asc, reportingitemname desc;
        return next ref2;
    
    
    	   open ref3 for select * from fn_mr_hospsummary_getfreeservices(p_fromdate,p_todate);
        return next ref3;
    
    		-- total immunization patient served 
    
    													 
    		
    
    
    		open ref4 for select count(*) as totalvaccinationclientserved
    		from pat_patientvisits patv 
    		where  patv.departmentid = v_deptid
    			and patv.isactive = 1
    			and patv.billingstatus != 'returned'
    			and (patv.visitdate)::date between p_fromdate and p_todate;
        return next ref4;
    
    		-- table 5-- 
    
    		-- inpatient referred out count table
    		open ref5 for select coalesce( sum(case when gender = 'Male' then 1 else 0 end),0) as ipro_malecount,
                   coalesce(sum(case when gender = 'Female' then 1 else 0 end),0) as ipro_femalecount					
    		from mr_recordsummary mrs
    			inner join adt_dischargetype dt  on mrs.dischargetypeid = dt.dischargetypeid
    			inner join pat_patient pat  on mrs.patientid = pat.patientid
    			inner join adt_patientadmission adm  on mrs.patientvisitid = adm.patientvisitid
    		 where dt.dischargetypename = 'Referred'
    		 and (adm.dischargedate)::date between p_fromdate and p_todate;
        return next ref5;
    	
    		-- table 6
    		-- total patient admitted table 
    		open ref6 for select count(patientid) as totalpatientsadmitted
    		from adt_patientadmission 
    		where admissionstatus != 'cancel'
    		   and (admissiondate)::date between p_fromdate and p_todate;
        return next ref6;
    
    		-- table 7
    		-- total inpatient days table
    		open ref7 for select fn_mr_hospsummary_gettotalinpatientdays(p_fromdate, p_todate) as "totalinpatientdays";
        return next ref7;
    
    		--we need patient count, hence taking distinct patientid----
    		open ref8 for select count (distinct pat.patientid) as totllabserviceprovidedpersoncount
    		 from 
    		bil_txn_billingtransactionitems btxi 
    		inner join pat_patient pat  on pat.patientid = btxi.patientid
    		inner join bil_txn_billingtransaction inv  on btxi.billingtransactionid = inv.billingtransactionid
    		left join bil_txn_invoicereturnitems brtn  on btxi.billingtransactionitemid = brtn.billingtransactionitemid
    
    		where 
    			brtn.billreturnitemid is null
    			and (inv.createdon)::date between p_fromdate and p_todate
    			and btxi.servicedepartmentid in (select servicedepartmentid from bil_mst_servicedepartment where integrationname ='LAB');
        return next ref8;
    		open ref9 for select coalesce( sum(case when gender = 'Male' then 1 else 0 end),0) as opreferred_malecount,
                   coalesce(sum(case when gender = 'Female' then 1 else 0 end),0) as opreferred_femalecount			
    		from (select patientid,patientvisitid, ispatientreferred, isactive from mr_txn_outpatient_finaldiagnosis		group by patientvisitid, patientid, ispatientreferred, isactive) ofd
    		inner join pat_patient pt on pt.patientid= ofd.patientid
    		inner join pat_patientvisits ptv on ptv.patientvisitid= ofd.patientvisitid
    		where ofd.isactive=1 and ofd.ispatientreferred=1 
    		 and (ptv.visitdate)::date between p_fromdate and p_todate;
        return next ref9;
END;
$$ LANGUAGE plpgsql;