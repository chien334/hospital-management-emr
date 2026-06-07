CREATE OR REPLACE FUNCTION sp_claim_generatenewclaimcode(
    p_schemeid INT DEFAULT NULL
)
RETURNS TABLE (
    "NewClaimCode" VARCHAR,
    "IsMaxLimitReached" BOOLEAN
) AS $$
DECLARE
    v_minlimit INT;
    v_maxlimit INT;
    v_claimcodeparam VARCHAR := (Select ParameterValue from CORE_CFG_Parameters 
										 where ParameterGroupName='Insurance' and ParameterName='ClaimCodeAutoGenerateSettings');
    v_maxclaimcode INT := (select MAX(ClaimCode) from PAT_PatientVisits
									where SchemeId = p_schemeid AND ClaimCode between v_minlimit and v_maxlimit);
    v_newclaimcode INT := v_minlimit;
    v_ismaxlimitreached BOOLEAN := FALSE;
BEGIN
    /*
    file: sp_claim_generatenewclaimcode
    created: krishna, 28thmay'23
    Description: Get new claim code from pat_visit table of specific scheme that required auto generation of claimCode.
    NOTE: 
       * Returns 0 as New claimcode if max limit is reached.
    
    Change History:
    S.No.  ChangedBy/Date               Remarks
    1.     Krishna, 28thMay'23        initial draft.
    */
    begin
    	
    	--read the json param and get the min/max fields. 
    	
    	v_minlimit := ((select json_value(v_claimcodeparam, '$.min')))::bigint;
    	v_maxlimit := ((select json_value(v_claimcodeparam, '$.max')))::bigint;
    
    	
    
    	 --- by default new claim code will start from minlimit value.
    
    	if v_maxclaimcode is not null 
    	then
    	   v_newclaimcode := v_maxclaimcode||1;
    	
    	elsif(v_newclaimcode>v_maxlimit)
    	then
    	 v_ismaxlimitreached := 1;
    	 v_newclaimcode := 0; ---return zero when maxlimit is reached
    	
    	else
    	
    	  v_ismaxlimitreached := 0;
    	end if;
    
    	RETURN QUERY SELECT v_newclaimcode AS "NewClaimCode", v_ismaxlimitreached AS "IsMaxLimitReached";
    
    end;
END;
$$ LANGUAGE plpgsql;