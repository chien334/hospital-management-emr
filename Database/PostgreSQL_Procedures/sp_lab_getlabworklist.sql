CREATE OR REPLACE FUNCTION sp_lab_getlabworklist(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_labtypename VARCHAR DEFAULT 'op-lab',
    p_categoryidcsv VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "SampleCollectedOn" TIMESTAMP,
    "BarCodeNumber" VARCHAR,
    "SampleCodeFormatted" VARCHAR,
    "PatientName" VARCHAR,
    "PatientCode" VARCHAR,
    "DateOfBirth" TIMESTAMP,
    "Gender" VARCHAR,
    "LabTestNameCsv" VARCHAR,
    "Barcode" VARCHAR
) AS $$
DECLARE
    v_isverificationenabled BOOLEAN;
    v_verificationparam VARCHAR := (Select ParameterValue 
              from CORE_CFG_Parameters 
              where ParameterName='LabReportVerificationNeededB4Print');
BEGIN
    /*
    filename: "sp_lab_getlabworklist"
    createdby/date: sud/devn/09jan'23
    Description: To get lab work list based on given filters. 
                 We've moved the logic from c# controller to this sp since it's way too complex in LINQ query. 
    Remarks    :  Data are filtered based on RequestCreatedOn (i.e: Billing Date), 
                  Which may vary from hospital to hospital, we need to discuss if other hospital has any issues.
    Change History
    S.No.    UpdatedBy/Date                        Remarks
    1       Sud/DevN/09Jan'23      created
    2.      devn/15jan'23                        DateRange filter changeed from CreatedOn to
                SampleCollectedOnDate
    3.      DevN/9Feb'23                         get testnames as semicolon (;) separated string rather than csv.
    4.      devn/12sept'23                       Get BarCodeNumber and exclude tests send to external lab.
    */
    
    
     
     
     v_isverificationenabled := (SELECT JSON_VALUE(v_verificationparam, '$.enableverificationstep'));
    
    
     RETURN QUERY SELECT req.SampleCreatedOn AS "SampleCollectedOn", req.BarCodeNumber, 
     req.SampleCodeFormatted,pat.ShortName AS "PatientName", pat.PatientCode AS "PatientCode",
     (pat.DateOfBirth)::Date AS "DateOfBirth", 
     pat.Gender, STRING_AGG(req.LabTestName,';') AS "LabTestNameCsv" ,
     req.BarCodeNumber AS "Barcode"
    
     From LAB_TestRequisition req
     INNER JOIN LAB_LabTests tst on req.LabTestId=tst.LabTestId
     INNER JOIN 
     (Select (value)::int AS "CategoryId" from string_split(p_categoryidcsv, ',') where RTRIM(value) <> '') selCat 
        on selCat.CategoryId= tst.LabTestCategoryId
    
       INNER JOIN PAT_Patient pat on req.PatientId=pat.PatientId
       INNER JOIN Lab_MST_LabVendors vendor ON req.ResultingVendorId = vendor.LabVendorId
     where (req.SampleCollectedOnDateTime)::Date Between p_fromdate and p_todate
       and COALESCE(req.LabTypeName,'op-lab')= COALESCE(p_labtypename,'op-lab') -- this is our default
       and req.BillingStatus NOT IN ('cancel','returned')
       AND vendor.IsExternal = 0
       AND
        ( 
        --when verification disabled then take only requests having orderstatus: pending.
        (
        v_isverificationenabled=1 
       and req.OrderStatus IN ('pending','result-added','report-generated')
       and COALESCE(req.IsVerified,0) = 0 
         )
       OR 
         (
        v_isverificationenabled=0 and req.OrderStatus IN ('pending')
         )
        )
     group by req.samplecreatedon, req.barcodenumber, req.samplecodeformatted, pat.shortname , pat.patientcode, 
        (pat.dateofbirth)::date, pat.gender
     order by req.samplecreatedon, req.barcodenumber, req.samplecodeformatted;
END;
$$ LANGUAGE plpgsql;