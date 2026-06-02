create Proc  [dbo].[SP_ExportDBToCSV]
As
/*
FileName: [SP_ExportDBToCSV]
CreatedBy/date: NageshBB/2017 Sep 28
Description: This stored procedure export all table as csv file from current database
Remarks:    
Change History
S.No.    CreatedBy/UpdatedBy/Date                        Remarks
1       NageshBB/2017-05-25								created the script
*/
Begin
-- To allow advanced options to be changed.
EXEC sp_configure 'show advanced options',
 1;

--GO -- To update the currently configured value for advanced options.
RECONFIGURE;

--GO -- To enable the feature.
EXEC sp_configure 'xp_cmdshell',
 1;

--GO -- To update the currently configured value for this feature.
RECONFIGURE;
--GO
DECLARE 
@cmd sysname, 
@DownloadDirPath varchar(300)=(select ParameterValue from CORE_CFG_Parameters where ParameterName='DBExportCSVXMLDirPath')
Set @DownloadDirPath=@DownloadDirPath+'CSV\'
SET @cmd='MD '+@DownloadDirPath;

EXEC master..xp_cmdshell @cmd;
Declare
@ServerName varchar(100)=convert(varchar(100),(Select SERVERPROPERTY('ServerName')))  --We can set value from core parameter table 
,@query1 VARCHAR(MAX)
,@DbName sysname=Db_name()
,@query2 VARCHAR(MAX)
,@TableName  VARCHAR(MAX)
,@ResultStatus varchar(10)='success'
SELECT ROW_NUMBER() OVER
(ORDER BY
		(SELECT 1)) rownum, 'select ' + STUFF(
		(SELECT ','+ 'Quotename(cast(' + ISNULL(COLUMN_NAME,'''''''') + ' as varchar(max)),''""'')' + ' as ""' + COLUMN_NAME + '"" '
		FROM INFORMATION_SCHEMA.COLUMNS		
		WHERE TABLE_NAME = t.name AND DATA_TYPE<>'image' ORDER BY ordinal_position
		FOR XML PATH('')),1,1,'') + ' FROM '+ '['+@DbName+'].['+SCHEMA_NAME(schema_id)+'].['+t.name+']' AS col1,
		'select ' + STUFF(
		(
			SELECT ','+ 'Quotename(''' +COLUMN_NAME + ''',''""'')'
			FROM INFORMATION_SCHEMA.COLUMNS
			WHERE TABLE_NAME = t.name AND DATA_TYPE<>'image' ORDER BY ordinal_position FOR XML PATH('')),1,1,''
		) 
		AS col2,t.name AS col3 INTO #temp FROM sys.tables t 
 
--Using loop we are now export table as csv files
DECLARE @row INT=0 

WHILE
	(SELECT count(1) FROM #temp)>0 
BEGIN
	SELECT TOP 1 @query1=col2,@query2=col1,@row=rownum,@TableName=col3 FROM #temp 

	DECLARE @sqlQuery VARCHAR(8000)=''

	SELECT @sqlQuery = 'bcp "' + @query1 + ' union all ' + @query2 + '" queryout '+@DownloadDirPath+'' + @TableName + '.csv -c -t, -T -S'+ @ServerName

	SELECT @sqlQuery EXEC master..xp_cmdshell @sqlQuery

	DELETE FROM #temp WHERE rownum=@row 
END

DROP TABLE #temp
Select @ResultStatus
--get Machine Name, ServerName and @@servername 
--SELECT ServerProperty('machinename') as [machinename]    ,ServerProperty('ServerName') [servername]   ,@@ServerName as [@@ServerName];

End