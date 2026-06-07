CREATE OR REPLACE FUNCTION sp_report_lab_covidtestssummary(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_testname VARCHAR DEFAULT NULL,
    p_countrysubdivisionid INT DEFAULT NULL
)
RETURNS TABLE (
    "District" VARCHAR,
    "TotalCases" DECIMAL,
    "NewNegativeCases" VARCHAR,
    "NewPositiveCases" VARCHAR,
    "FollowupNegativeCases" VARCHAR,
    "FollowupPositiveCases" VARCHAR
) AS $$
DECLARE
    v_isverificationenabled BOOLEAN;
    v_verificationparam VARCHAR := (Select ParameterValue from CORE_CFG_Parameters where ParameterName='LabReportVerificationNeededB4Print');
BEGIN
    /************************************************************************  
    filename: "sp_report_lab_covidtestssummary"  
    createdby/date: anjana/22june,2021  
    description: get covid tests summary details  
    s.no.    updatedby/date                        remarks  
    1        anjana/22june,2021     initial draft  
    2        pratik/5thsep,2021                 positive and negative followup cases from lab_testrequisition  
    3  anish/12sept 2021     replace empty provider id by 'new'  
    *************************************************************************/  
      
    begin  
       
          
        v_isverificationenabled := (select json_value(v_verificationparam, '$.EnableVerificationStep'));  
      
     if(p_fromdate is not null or p_todate is not null)  
     then  
      
     if(p_countrysubdivisionid = 0)  
      then  
       p_countrysubdivisionid := null;  
      end if;  
       
     RETURN QUERY SELECT  
     subdiv.countrysubdivisionname AS "District",  
     count(*) AS "TotalCases",  
     sum( case when lower("value") = 'negative' and coalesce(req.prescribername,'new') like '%new%' then 1 else 0 end) AS "NewNegativeCases",  
     sum( case when lower("value") = 'positive' and coalesce(req.prescribername,'new') like '%new%' then 1 else 0 end) AS "NewPositiveCases",  
     sum( case when lower("value") = 'negative' and replace(req.prescribername,'-','') like '%followup%' then 1 else 0 end) AS "FollowupNegativeCases",  
     sum( case when lower("value") = 'positive' and replace(prescribername,'-','') like '%followup%' then 1 else 0 end) AS "FollowupPositiveCases"  
      
     from lab_testrequisition req  
     join lab_txn_testcomponentresult result on req.requisitionid = result.requisitionid  
     join pat_patient pat on req.patientid = pat.patientid  
     left join mst_countrysubdivision subdiv on pat.countrysubdivisionid = subdiv.countrysubdivisionid  
     join lab_labtests test on req.labtestid = test.labtestid  
        where test.labtestname = p_testname and req.isactive = 1 and result.isactive=1 and (req.orderdatetime)::date between (p_fromdate)::date and (p_todate)::date  
     and coalesce(p_countrysubdivisionid,subdiv.countrysubdivisionid)=subdiv.countrysubdivisionid and result."value" in ('negative','positive')  
     and (req.isverified=1 or coalesce(req.isverified,0)=v_isverificationenabled)   
      group by subdiv.countrysubdivisionname;  
     end if;  
    end;
END;
$$ LANGUAGE plpgsql;