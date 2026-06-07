CREATE OR REPLACE FUNCTION sp_report_lab_gethivtestdetails(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL
)
RETURNS TABLE (
    "RequisitionId" INT,
    "ShortName" VARCHAR,
    "PatientCode" VARCHAR,
    "Age" VARCHAR,
    "Gender" VARCHAR,
    "Method" VARCHAR,
    "Value" DECIMAL,
    "Address" VARCHAR,
    "SampleCode" VARCHAR,
    "ComponentName" TIMESTAMP,
    "ResultDate" TIMESTAMP,
    "LabTypeName" VARCHAR
) AS $$
DECLARE
    v_isverificationenabled BOOLEAN;
    v_verificationparam VARCHAR := (Select ParameterValue from CORE_CFG_Parameters where ParameterName='LabReportVerificationNeededB4Print');
BEGIN
    /*
     file: sp_report_lab_gethivtestdetails
     description: to get details of hiv test of patients between selected dates
     conditions/checks: 
            
     change history:
     s.no.    changedate/by              remarks
     1.      25jul'21/Anjana          Initial Draft 
     2.      3 Sept/Anish             Filters Added with verification Parameter
     3.      16 Nov/Dev Narayan       Change procedure for getting labtypename
    */
    
        
        
        v_isverificationenabled := (SELECT JSON_VALUE(v_verificationparam, '$.enableverificationstep'));
    
        RETURN QUERY SELECT allData.RequisitionId,allData.ShortName,allData.PatientCode,
      max(allData.Age) AS "Age",
      max(allData.Gender) AS "Gender",
      allData.Method, 
      allData."Value", 
        allData."Address", 
      allData.SampleCodeFormatted AS "SampleCode", 
      allData.ComponentName, 
      (allData.ResultDate)::Date AS "ResultDate",
      allData.LabTypeName
        from (Select 
        pat.ShortName,
        pat.PatientCode,
        pat.Age,
        pat.Gender,
        pat."Address",
        req.SampleCodeFormatted,
        res.ComponentName,
        res."Value",
        res.Method,
        req.RequisitionId,
        res.CreatedOn AS "ResultDate",
    	req.LabTypeName
        from PAT_Patient pat
        join LAB_TestRequisition req on pat.PatientId = req.PatientId
        join LAB_TXN_TestComponentResult res on req.RequisitionId = res.RequisitionId
        where res.ComponentName = 'hiv' and res.isactive=1 and req.isactive=1 
        and (req.isverified=1 or coalesce(req.isverified,0)=v_isverificationenabled)
        and (req.orderdatetime)::date between ((p_fromdate)::date) and (p_todate)::date
        ) alldata group by alldata.requisitionid, alldata.method, alldata."value", alldata."address",
        alldata.shortname,alldata.patientcode, alldata.samplecodeformatted, alldata.componentname,(alldata.resultdate)::date,alldata.labtypename
    	order by (alldata.resultdate)::date desc;
END;
$$ LANGUAGE plpgsql;