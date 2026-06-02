CREATE Procedure SP_Claim_GenerateNewClaimCode
@SchemeId INT = null
AS
/*
File: SP_Claim_GenerateNewClaimCode
Created: Krishna, 28thMay'23
Description: Get new claim code from pat_visit table of specific scheme that required auto generation of claimCode.
NOTE: 
   * Returns 0 as New claimcode if max limit is reached.

Change History:
S.No.  ChangedBy/Date               Remarks
1.     Krishna, 28thMay'23        Initial Draft.
*/
BEGIN
	declare @minLimit BIGINT, @maxLimit BIGINT;
	--Read the json param and get the min/max fields. 
	declare @claimCodeParam varchar(500) = (Select ParameterValue from CORE_CFG_Parameters 
										 where ParameterGroupName='Insurance' and ParameterName='ClaimCodeAutoGenerateSettings')
	set @minLimit =  Convert(BIGINT,(SELECT JSON_VALUE(@claimCodeParam, '$.min')));
	set @maxLimit =  Convert(BIGINT,(SELECT JSON_VALUE(@claimCodeParam, '$.max')));

	Declare @maxClaimCode BIGINT = (select MAX(ClaimCode) from PAT_PatientVisits
									where SchemeId = @SchemeId AND ClaimCode between @minLimit and @maxLimit)

	Declare @newClaimCode BIGINT=@minLimit --- by default new claim code will start from MinLimit value.

	IF @maxClaimCode is not null 
	BEGIN
	   SET  @newClaimCode = @maxClaimCode+1
	END
	ELSE


	Declare @isMaxLimitReached BIT = 0;
	if(@newClaimCode>@maxLimit)
	BEGIN
	 SET @isMaxLimitReached=1
	 SET @newClaimCode=0 ---Return zero when maxlimit is reached
	END
	ELSE
	BEGIN
	  SET @isMaxLimitReached=0
	END

	Select @newClaimCode AS 'NewClaimCode', @isMaxLimitReached AS 'IsMaxLimitReached'

END