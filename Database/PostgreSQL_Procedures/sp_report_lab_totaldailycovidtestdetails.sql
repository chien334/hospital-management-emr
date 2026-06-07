CREATE OR REPLACE FUNCTION sp_report_lab_totaldailycovidtestdetails(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_testname VARCHAR DEFAULT NULL,
    p_resulttype VARCHAR DEFAULT NULL,
    p_countrysubdivisionid INT DEFAULT NULL,
    p_casetype VARCHAR DEFAULT NULL,
    p_gender VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "SampleId" INT,
    "CollectionDate" TIMESTAMP,
    "PatientType" VARCHAR,
    "TestDate" TIMESTAMP,
    "PatientName" VARCHAR,
    "Gender" VARCHAR,
    "VerifiedOn" TIMESTAMP,
    "EGene" VARCHAR,
    "ORFGene" VARCHAR,
    "NGene" VARCHAR,
    "Report" VARCHAR,
    "Age" VARCHAR,
    "PhoneNumber" TIMESTAMP,
    "Address" VARCHAR,
    "MunicipalityName" VARCHAR,
    "CountrySubDivisionName" TIMESTAMP
) AS $$
DECLARE
    v_isverificationenabled BOOLEAN;
    v_verificationparam VARCHAR := (  
  Select   
    ParameterValue   
  from   
    CORE_CFG_Parameters   
  where   
    ParameterName = 'LabReportVerificationNeededB4Print'  
);
    v_labtestid INT;
BEGIN
    /*  
       file: sp_report_lab_totaldailycovidtestdetails   
       description: get all details of covid tests as per resultdate.  
       created: anish  
       modified: sud: 9-oct'21-- Filter condition changed to ResultDate (earler it was Billing Date)..   
       Modified: Dev:29-Nov'21--alter procedure to show ngene, egene value when positive is selected....  
       modifiedl krishna,9thjun'22--changed RequestedBy to PrescriberId
       */  
      BEGIN   
       
    v_isverificationenabled := (  
        SELECT   
          JSON_VALUE(  
            v_verificationparam, '$.enableverificationstep'  
          )  
      );  
    IF(p_countrysubdivisionid = 0) THEN   
    p_countrysubdivisionid := null; END IF;   
    p_resulttype := LOWER(  
        COALESCE(p_resulttype, 'all')  
      );  
    p_casetype := REPLACE(  
        LOWER(  
          COALESCE(p_casetype, 'all')  
        ),   
        '-',   
        ''  
      );  
    --p_gender := LOWER(COALESCE(p_gender,'all'));  
       
    v_labtestid := (  
        Select   
           LabTestId   
        from   
          LAB_LabTests   
        where   
          LabTestName = p_testname LIMIT 1  
      );   
    RETURN QUERY SELECT   
      *   
    from   
      (  
        SELECT   
          req.SampleCodeFormatted AS "SampleId",   
          req.SampleCollectedOnDateTime AS "CollectionDate",   
          COALESCE(emp.FullName, 'new') AS "PatientType",   
          req.ResultAddedOn AS "TestDate",   
          pat.ShortName AS "PatientName",   
          pat.Gender AS "Gender",   
          req.VerifiedOn,   
          max(  
            case when val.ComponentName = 'e gene ct level' then val."Value" end  
          ) AS "EGene",   
          max(  
            case when val.ComponentName = 'orf1ab gene ct level' then val."Value" end  
          ) AS "ORFGene",   
          max(  
            case when val.ComponentName = 'n gene ct level' then val."Value" end  
          ) AS "NGene",   
          max(  
            case when val.ComponentName = 'test of covid-19' then val."Value" end  
          ) AS "Report",   
          pat.Age,   
          --max(pat.Gender),  
          pat.PhoneNumber,   
          pat."Address",   
          mun.MunicipalityName,   
          subDiv.CountrySubDivisionName   
        from   
          LAB_TestRequisition req   
          join PAT_Patient pat on req.PatientId = pat.PatientId --join LAB_LabTests test on req.LabTestId = test.LabTestId  
          left join (  
            Select   
              RequisitionId,   
              "Value",   
              ComponentName   
            from   
              LAB_TXN_TestComponentResult result   
            where   
              LabTestId = v_labtestid   
              and result.IsActive = 1  
          ) val on req.RequisitionId = val.RequisitionId   
          left join MST_CountrySubDivision subDiv on pat.CountrySubDivisionId = subDiv.CountrySubDivisionId   
          left join MST_Municipality mun on pat.MunicipalityId = mun.MunicipalityId   
          left join EMP_Employee emp on req.PrescriberId = emp.EmployeeId   
        WHERE   
          req.LabTestId = v_labtestid   
          and req.IsActive = 1   
          AND (  
            req.IsVerified = 1   
            OR COALESCE(req.IsVerified, 0)= v_isverificationenabled  
          )   
          AND COALESCE(  
            p_countrysubdivisionid, pat.CountrySubDivisionId  
          )= pat.CountrySubDivisionId --AND Convert(date,req.CreatedOn) BETWEEN (CONVERT(date, p_fromdate)) AND CONVERT(date, p_todate)  
          --sud: Taking from ResultAddedOn date   
          AND (req.ResultAddedOn)::date BETWEEN (  
            (p_fromdate)::date  
          )   
          AND (p_todate)::date        
          AND (  
            COALESCE(  
              REPLACE(emp."FullName", '-', ''),   
              'new'  
            ) = p_casetype   
            OR p_casetype = 'all'  
          )   
        GROUP BY   
          req.SampleCodeFormatted,   
          req.SampleCollectedOnDateTime,   
          req.VerifiedOn,   
          req.ResultAddedOn,   
          pat.Gender,   
          pat.ShortName,   
          pat.Age,   
          pat.PhoneNumber,   
          pat."Address",   
          mun.MunicipalityName,   
          subDiv.CountrySubDivisionName,   
          emp.FullName  
      ) allData   
      where allData.Report = p_resulttype OR p_resulttype = 'all';  
      end;
END;
$$ LANGUAGE plpgsql;