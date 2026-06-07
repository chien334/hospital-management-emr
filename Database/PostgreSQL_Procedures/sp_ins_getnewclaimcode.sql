CREATE OR REPLACE FUNCTION sp_ins_getnewclaimcode(

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
									where ClaimCode between v_minlimit and v_maxlimit);
    v_newclaimcode INT := v_minlimit;
    v_ismaxlimitreached BOOLEAN := FALSE;
BEGIN
    /*
    file: sp_ins_getnewclaimcode
    created: sud/pratik : 1-oct'21
    Description: Get new claim code from pat_visit table.
       Moving the logic from C# to SQL since there was issue in LINQ comparision of String(data type of Claimcode)  
    NOTE: 
       * Returns 0 as New claimcode if max limit is reached.
       * Need to change the datatype of ClaimCode to BigInt in near future since string comparision is too heavy operation.
    
    Change History:
    S.No.  ChangedBy/Date               Remarks
    1.     Sud/Pratik : 1-Oct'21        initial draft.
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