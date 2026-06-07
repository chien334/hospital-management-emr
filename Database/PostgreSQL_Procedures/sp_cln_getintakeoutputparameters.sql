CREATE OR REPLACE FUNCTION sp_cln_getintakeoutputparameters(

)
RETURNS TABLE (
    "IntakeOutputId" INT,
    "ParameterType" VARCHAR,
    "ParameterValue" DECIMAL,
    "ParentParameterValue" DECIMAL,
    "IsActive" BOOLEAN,
    "ParameterMainId" INT
) AS $$
BEGIN
    /*
    filename:"sp_cln_getintakeoutputparameters" 
    createdby/date:  santosh/2ndoct'23
    Description:  Get Intake/Output parameters for Clinical Intake/Output
     Change History
     S.No.    Date/User                    Change          Remarks
     1.       Santosh/2ndOct'23          created         initial draft.      
    */
    
    RETURN QUERY SELECT 
    tbl1.intakeoutputid,
    tbl1.parametertype,
    tbl1.parametervalue AS "ParameterValue",
    tbl2.parametervalue AS "ParentParameterValue",
    tbl1.isactive,
    tbl1.parametermainid
    from cln_mst_intakeouttakeparameter tbl1
    left join cln_mst_intakeouttakeparameter tbl2 on tbl1.parametermainid = tbl2.intakeoutputid;
END;
$$ LANGUAGE plpgsql;