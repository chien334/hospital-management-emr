CREATE OR REPLACE FUNCTION sp_lab_getpatientlistforreportdispatch(
    p_startdate DATE DEFAULT NULL,
    p_enddate DATE DEFAULT NULL,
    p_categorylist VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "PatientId" INT,
    "PatientCode" VARCHAR,
    "PatientName" VARCHAR,
    "PhoneNumber" TIMESTAMP,
    "Gender" VARCHAR,
    "DateOfBirth" TIMESTAMP
) AS $$
DECLARE
    v_allowprovisionalprintstr VARCHAR;
    v_allowprovisionalprint BOOLEAN := FALSE;
    v_isverificationenabled BOOLEAN;
    v_verificationparam VARCHAR := (Select ParameterValue 
                                           from CORE_CFG_Parameters 
                                           where ParameterName='LabReportVerificationNeededB4Print');
BEGIN
    DROP TABLE IF EXISTS v_categoryidtbl;
    CREATE TEMP TABLE v_categoryidtbl (
        CategoryId int
    );
    /*
    file: sp_lab_getpatientlistforreportdispatch
    created: anish/sud:6sep'21
    Description: To get distinct patient list in the given date range for Lab-Dispatch Page.
    NOTE: Returned  And Cancelled items are excluded from this.
    Change History:
    S.No.  ChangedBy/Date         Remarks
    1.    Anish/Sud:6Sep'21       needed new sp since previous was processing more data and hence taking more time
    2.    anish:10sep'21          Correction in Verification Filter, which was missing earlier.
                                  Added ProvisionalRestriction Check(parameterized) which was missing earlier.
    */
    BEGIN
    
    
    Insert into v_categoryidtbl
    Select value from string_split(p_categorylist, ',') where RTRIM(value) <> '';
    
    
    v_allowprovisionalprintstr := (Select ParameterValue 
                                     from CORE_CFG_Parameters 
    								 where LOWER(ParameterGroupName)='lab' and ParameterName='allowlabreporttoprintonprovisional');
    
    IF(v_allowprovisionalprintstr = 'true' OR v_allowprovisionalprintstr = '1')
    THEN 
      v_allowprovisionalprint := 1;
    END IF;
    
    
    
    
    
    v_isverificationenabled := (SELECT JSON_VALUE(v_verificationparam, '$.enableverificationstep'));
    
    --need to get distinct since there could be more than one requisition for same patient---  
    RETURN QUERY SELECT distinct 
        pat.PatientId,
        pat.PatientCode,
        pat.ShortName AS "PatientName",
        pat.PhoneNumber,
        pat.Gender,
        (pat.DateOfBirth)::Date AS "DateOfBirth"
        
    from LAB_TestRequisition req 
        INNER JOIN  PAT_Patient pat on req.PatientId = pat.PatientId
        INNER JOIN LAB_LabTests test on req.LabTestId = test.LabTestId
        INNER JOIN v_categoryidtbl cat on test.LabTestCategoryId=cat.CategoryId
        
    where req.OrderStatus = 'report-generated'  --take only report generated patients..
        and (req.IsVerified=1 OR COALESCE(req.IsVerified,0) = v_isverificationenabled )
           --filter by request created on--
        and (req.CreatedOn)::Date Between p_startdate and p_enddate
        and req.BillingStatus !='returned'  --exclude returned and cancelled requests (from billing)
        and req.BillingStatus !='cancel'
    	AND (  v_allowprovisionalprint = 1
    	       OR(req.VisitType='inpatient' OR req.VisitType='emergency')
    		   OR (req.BillingStatus !='provisional')
    		)
    
    order by pat.shortname;
    end;
END;
$$ LANGUAGE plpgsql;