--End:Nirmala/Rohit DATE: 2022-1-05: --Created new SP for Patient Dashboard-----
--START:Nirmala/Rohit DATE: 2022-1-05: --Created new SP for Patient Dashboard-----
CREATE PROCEDURE SP_Dashboard_PAT_AverageTreatmentCostbyAgeGroup @FromDate DATE = NULL
	,@ToDate DATE = NULL
AS
/*
 SP_Dashboard_PAT_AverageTreatmentCostbyAgeGroup '2022-1-05'
FileName: [SP_Dashboard_PAT_AverageTreatmentCostbyAgeGroup]
CreatedBy/date: Nirmala/Rohit/2022-1-05
Description: .
Remarks:    A
Change History
S.No.    UpdatedBy/Date                        Remarks
1      Nirmala/Rohit/2022-1-05                created the script
*/
BEGIN
	DECLARE @zeroTo14Years VARCHAR(20) = '0-14Years'
		,@14To25Years VARCHAR(20) = '14-25Years'
		,@25To35Years VARCHAR(20) = '25-35Years'
		,@35To45Years VARCHAR(20) = '35-45Years'
		,@45To55Years VARCHAR(20) = '45-55Years'
		,@greaterThan55Years VARCHAR(20) = '>55Years'

	SELECT Gender
		,AgeRange
		,COUNT(AgeNum) 'Total'
	FROM (
		SELECT AgeNum
			,Gender
			,CASE 
				WHEN AgeUnit = 'D'
					THEN @zeroTo14Years
				WHEN AgeUnit = 'M'
					THEN @zeroTo14Years
				WHEN (
						AgeUnit = 'Y'
						AND AgeNum < 14
						)
					THEN @zeroTo14Years
				WHEN (
						AgeUnit = 'Y'
						AND (
							AgeNum BETWEEN 14
								AND 25
							)
						)
					THEN @14To25Years
				WHEN (
						AgeUnit = 'Y'
						AND (
							AgeNum BETWEEN 25
								AND 35
							)
						)
					THEN @25To35Years
				WHEN (
						AgeUnit = 'Y'
						AND (
							AgeNum BETWEEN 35
								AND 45
							)
						)
					THEN @35To45Years
				WHEN (
						AgeUnit = 'Y'
						AND (
							AgeNum BETWEEN 45
								AND 55
							)
						)
					THEN @45To55Years
				WHEN (
						AgeUnit = 'Y'
						AND (AgeNum > 55)
						)
					THEN @greaterThan55Years
				END AS 'AgeRange'
		FROM (
			SELECT tbl.Age
				,(
					SELECT CAST(tbl.AgeNo AS INT) AS AgeNum
					) 'AgeNum'
				,tbl.AgeUnit
				,tbl.Gender
			FROM (
				SELECT Age
					,SUBSTRING(Age, 1, LEN(Age) - 1) AS 'AgeNo'
					,SUBSTRING(Age, LEN(Age), LEN(Age)) AS 'AgeUnit'
					,Gender
				FROM PAT_Patient
				WHERE Gender != '0'
					AND CONVERT(DATE, CreatedOn) BETWEEN CONVERT(DATE, @FromDate)
						AND CONVERT(DATE, @ToDate)
				) tbl
			) tbl1
		) tbl2
	GROUP BY AgeRange
		,Gender
	ORDER BY AgeRange
END