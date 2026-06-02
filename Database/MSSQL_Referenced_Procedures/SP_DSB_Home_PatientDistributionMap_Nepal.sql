CREATE PROCEDURE [dbo].[SP_DSB_Home_PatientDistributionMap_Nepal]
AS
/*
FileName: [SP_DSB_Home_PatientDistributionMap_Nepal]
CreatedBy/date: sudarshan/2017-07-09
Description: to get zone wise patient distribution--ONLY FOR NEPAL NOW.
Remarks: 
Change History
S.No.    UpdatedBy/Date                        Remarks
1       sudarshan/2017-07-09	               created
*/
BEGIN

	Select A.MapAreaCode, IsNull(B.PatientCount,0) PatientCount
	FROM 
	(
	  Select Distinct MapAreaCode from MST_CountrySubDivision
	  WHERE CountryId=(select CountryId from MST_Country where CountryName='Nepal') 
			AND MapAreaCode IS NOT NULL
	) A

	left join 
	(
		 Select csd.MapAreaCode, Count(PatientId) 'PatientCount' 
		 from MST_CountrySubDivision csd,PAT_Patient pat
		 where pat.CountrySubDivisionId=csd.CountrySubDivisionId
		 and pat.CountryId=(select CountryId from MST_Country where CountryName='Nepal')
		 GROUP BY csd.MapAreaCode
	) B
	ON 
	A.MapAreaCode=B.MapAreaCode
END