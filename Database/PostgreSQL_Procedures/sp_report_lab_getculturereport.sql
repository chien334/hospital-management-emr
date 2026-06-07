CREATE OR REPLACE FUNCTION sp_report_lab_getculturereport(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL
)
RETURNS TABLE (
    "ShortName" VARCHAR,
    "PatientCode" VARCHAR,
    "Age" VARCHAR,
    "Gender" VARCHAR,
    "SampleCodeFormatted" VARCHAR,
    "Finding" VARCHAR,
    "Sensitivity" VARCHAR,
    "Resistant" VARCHAR,
    "Intermediate" VARCHAR,
    "ResultDate" TIMESTAMP,
    "LabTestSpecimen" VARCHAR
) AS $$
DECLARE
    v_isverificationenabled BOOLEAN;
    v_verificationparam VARCHAR := (Select ParameterValue from CORE_CFG_Parameters where ParameterName='LabReportVerificationNeededB4Print');
BEGIN
    /*
     file: sp_report_lab_getculturereport
     description: to get details of culture test of patients between selected dates
     conditions/checks: 
            
     change history:
     s.no.    changedate/by              remarks
     1.      26jul'21/Anjana          Initial Draft 
     2.     30 Sept'21/anish        verification filter and other filters added 
    */
    
        
        
        v_isverificationenabled := (select json_value(v_verificationparam, '$.EnableVerificationStep'));
    
        --for positive culture test report
        RETURN QUERY SELECT 
        max(tblpositivedata.shortname) AS "ShortName",
        max(tblpositivedata.patientcode) AS "PatientCode",
        max(tblpositivedata.age) AS "Age",
        max(tblpositivedata.gender) AS "Gender",
        max(tblpositivedata.samplecodeformatted) AS "SampleCodeFormatted",
        max(tblpositivedata.finding) AS "Finding",
        max(tblpositivedata."sensitivity") AS "Sensitivity",
        max(tblpositivedata.resistant) AS "Resistant",
        max(tblpositivedata."intermediate") AS "Intermediate",
        max(tblpositivedata.resultdate) AS "ResultDate",
        max(tblpositivedata.labtestspecimen) AS "LabTestSpecimen"
        from (select * from (select 
        max(pat.shortname) AS "ShortName",
        pat.patientid,
        pat.patientcode,
        max(pat.age) AS "Age",
        max(pat.gender) AS "Gender",
        req.samplecodeformatted,
        max(case when res.componentname in ('Result','Result C/S') then res."value" end) AS "Finding",
        (case when max(res."value") = 'Sensitive' then string_agg(res.componentname , ', ') end) AS "Sensitivity",
        (case when max(res."value") = 'Resistant' then string_agg(res.componentname , ', ') end) AS "Resistant",
        (case when max(res."value") = 'Intermediate' then string_agg(res.componentname , ', ') end) AS "Intermediate",
        max(res.createdon) AS "ResultDate",
        req.requisitionid as requisitionid,
        max(req.labtestspecimen) AS "LabTestSpecimen"
        from pat_patient pat
        join lab_testrequisition req on pat.patientid = req.patientid
        join lab_txn_testcomponentresult res on req.requisitionid = res.requisitionid
        join lab_reporttemplate template on req.reporttemplateid = template.reporttemplateid
        where (req.orderdatetime)::date between ((p_fromdate)::date) 
        and (p_todate)::date and res.isactive = 1 and req.isactive = 1 and res.isnegativeresult = 0 
        and template.templatetype='culture' 
        and (req.isverified=1 or coalesce(req.isverified,0)=v_isverificationenabled)
        group by pat.patientid, pat.patientcode,req.samplecodeformatted, req.requisitionid, res."value"
        ) as tblinnerpositivedata) as tblpositivedata
        group by tblpositivedata.requisitionid
    
        union all
        --for negative culture test report
        select 
        max(tblnegativedata.shortname) AS "ShortName",
        max(tblnegativedata.patientcode) AS "PatientCode",
        max(tblnegativedata.age) AS "Age",
        max(tblnegativedata.gender) AS "Gender",
        max(tblnegativedata.samplecodeformatted) AS "SampleCodeFormatted",
        max(tblnegativedata.finding) AS "Finding",
        max(tblnegativedata."sensitivity") AS "Sensitivity",
        max(tblnegativedata.resistant) AS "Resistant",
        max(tblnegativedata."intermediate") AS "Intermediate",
        max(tblnegativedata.resultdate) AS "ResultDate",
        max(tblnegativedata.labtestspecimen) AS "LabTestSpecimen"
        from (select * from (select 
        max(pat.shortname) AS "ShortName",
        pat.patientid,
        pat.patientcode,
        max(pat.age) AS "Age",
        max(pat.gender) AS "Gender",
        req.samplecodeformatted,
        max(case when res.componentname = 'Negative Result' then res.negativeresulttext end) AS "Finding",
        max(case when res.componentname ='Negative Result' then res."value" end) AS "Sensitivity",
        max(case when res.componentname ='Negative Result' then res."value" end) AS "Resistant",
        max(case when res.componentname ='Negative Result' then res."value" end) AS "Intermediate",
        max(res.createdon) AS "ResultDate",
        req.requisitionid as requisitionid,
        max(req.labtestspecimen) AS "LabTestSpecimen"
        from pat_patient pat
        join lab_testrequisition req on pat.patientid = req.patientid
        join lab_txn_testcomponentresult res on req.requisitionid = res.requisitionid
        join lab_reporttemplate template on req.reporttemplateid = template.reporttemplateid
        where (req.orderdatetime)::date between ((p_fromdate)::date) and (p_todate)::date 
        and res.isactive = 1 and req.isactive = 1 and res.isnegativeresult = 1 and template.templatetype='culture' 
        and (req.isverified=1 or coalesce(req.isverified,0)=v_isverificationenabled)
        group by pat.patientid, pat.patientcode, req.samplecodeformatted, req.requisitionid, res."value"
        ) as tblinnernegativedata) as tblnegativedata
        group by tblnegativedata.requisitionid;
END;
$$ LANGUAGE plpgsql;