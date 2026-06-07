DROP FUNCTION IF EXISTS sp_lab_getallsmsapplicabletests(date, date);
DROP FUNCTION IF EXISTS sp_lab_getallsmsapplicabletests(timestamp without time zone, timestamp without time zone);

CREATE OR REPLACE FUNCTION sp_lab_getallsmsapplicabletests(
    p_fromdate TIMESTAMP,
    p_todate TIMESTAMP
)
RETURNS TABLE (
    "RequisitionId" BIGINT,
    "PatientName" VARCHAR,
    "LabTestName" VARCHAR,
    "SampleCollectedOnDateTime" TIMESTAMP,
    "DateOfBirth" TIMESTAMP,
    "Age" VARCHAR,
    "Gender" VARCHAR,
    "PatientCode" VARCHAR,
    "PhoneNumber" VARCHAR,
    "IsSmsSend" BOOLEAN,
    "IsVerified" BOOLEAN,
    "Result" VARCHAR,
    "IsFileUploaded" BOOLEAN
) AS $$
DECLARE
    v_covidtestname VARCHAR := '';
    v_verificationparameter VARCHAR := '';
    v_isverificationrequired BOOLEAN := FALSE;
    v_verificationlevel INT := 0;
BEGIN
    /*
    sp name:    sp_lab_getallsmsapplicabletests
    author:     krishna bogati/sanjit raj shakya / antigravity
    createdon:  2021-12-22
    remarks:    updated for PostgreSQL compatibility
    */
    
    select "ParameterValue"::json->>'DisplayName' into v_covidtestname 
    from "CORE_CFG_Parameters"
    where lower("ParameterGroupName") = 'common' and lower("ParameterName") = 'covidtestname' 
    limit 1;

    select "ParameterValue" into v_verificationparameter 
    from "CORE_CFG_Parameters"
    where lower("ParameterGroupName") = 'lab' and lower("ParameterName") = 'labreportverificationneededb4print' 
    limit 1;

    v_isverificationrequired := cast (v_verificationparameter::json->>'EnableVerificationStep' as boolean);
    v_verificationlevel := cast (v_verificationparameter::json->>'VerificationLevel' as int);


    RETURN QUERY SELECT 
        lr."RequisitionId", 
        p."ShortName" AS "PatientName", 
        lr."LabTestName", 
        lr."SampleCollectedOnDateTime", 
        p."DateOfBirth", 
        p."Age", 
        p."Gender", 
        p."PatientCode", 
        coalesce(p."PhoneNumber",'') AS "PhoneNumber", 
        coalesce(lr."IsSmsSend", false) AS "IsSmsSend", 
        lr."IsVerified", 
        cast(ltcr."Value" as varchar) AS "Result", 
        coalesce(lr."IsFileUploaded", false) AS "IsFileUploaded"
    from 
        "LAB_TestRequisition" as lr
        inner join "PAT_Patient" as p on lr."PatientId" = p."PatientId"
        inner join "LAB_LabTests" as lt on lr."LabTestId" = lt."LabTestId"
        inner join "LAB_TXN_TestComponentResult" as ltcr on lr."RequisitionId" = ltcr."RequisitionId"
    where 
        lt."SmsApplicable" = true and 
        lt."LabTestName" = v_covidtestname and
        lower(lr."OrderStatus") in ('report-generated','result-added') and
        ((v_isverificationrequired = true and lr."IsVerified" = true) or v_isverificationrequired = false) and
        lower(ltcr."Value") in ('positive','negative') and
        lr."IsActive" = true and
        lr."CreatedOn"::date between p_fromdate::date and p_todate::date;
END;
$$ LANGUAGE plpgsql;