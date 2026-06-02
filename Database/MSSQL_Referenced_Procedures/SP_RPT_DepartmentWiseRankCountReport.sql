CREATE PROCEDURE [dbo].[SP_RPT_DepartmentWiseRankCountReport] 
		 @FromDate DATE= NULL
		,@ToDate DATE=NULL
		,@DepartmentIds VARCHAR(1000) = NULL
	    ,@RankNames VARCHAR(1000) = NULL
AS
BEGIN
	IF(@DepartmentIds IS NULL OR @DepartmentIds = '')
	SET	@DepartmentIds=''

	IF(@RankNames IS NULL OR @RankNames ='')
	SET	@RankNames=''
	DECLARE 
		 @columns NVARCHAR(MAX) = ''
		,@sql NVARCHAR(MAX) = ''
	
	BEGIN
		SELECT @columns += QUOTENAME(MembershipTypeName) + ','
		FROM PAT_CFG_MembershipType;
		SET @columns = LEFT(@columns, LEN(@columns) - 1);

		SET @sql = 'SELECT *
						FROM (
							SELECT dep.DepartmentName
								,pat.Rank
								,pat.PatientId
								,memtype.MembershipTypeName
							FROM PAT_Patient pat
							INNER JOIN PAT_PatientVisits visit ON pat.PatientId = visit.PatientId
							INNER JOIN MST_Department dep ON visit.DepartmentId = dep.DepartmentId
							INNER JOIN PAT_CFG_MembershipType memtype ON pat.MembershipTypeId=memtype.MembershipTypeId
							WHERE pat.Rank IS NOT NULL AND 
							CONVERT(DATE,visit.VisitDate) BETWEEN CONVERT(DATE,''' + CONVERT(varchar(20), CONVERT(DATE,ISNULL(@FromDate, GETDATE()))) + ''') 
							AND CONVERT(DATE,''' + CONVERT(varchar(20), CONVERT(DATE,ISNULL(@ToDate, GETDATE()))) + ''')
							AND (dep.DepartmentId IN (SELECT VALUE FROM STRING_SPLIT('''+@DepartmentIds+''' ,'''+','+''')) OR  '''+@DepartmentIds+''' = '''+''')
							AND (pat.Rank IN (SELECT VALUE FROM STRING_SPLIT('''+@RankNames+''' ,'''+','+''')) OR   '''+@RankNames+''' = '''+''')
							) AS SourceTable
						PIVOT(
						COUNT(PatientId)  FOR SourceTable.MembershipTypeName  IN (' + @columns + ')
						) AS Pvt';
	END
	EXECUTE SP_EXECUTESQL @sql
END