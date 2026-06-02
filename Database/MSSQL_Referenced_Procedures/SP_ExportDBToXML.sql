Create Proc  [dbo].[SP_ExportDBToXML]
As
/*
FileName: [SP_ExportDBToXML]
CreatedBy/date: NageshBB/2017 Sep 28
Description: This stored procedure export all table as XML file from current database
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
@cmd sysname ,
@DownloadDirPath sysname=(select ParameterValue from CORE_CFG_Parameters where ParameterName='DBExportCSVXMLDirPath')
Set @DownloadDirPath=@DownloadDirPath+'XML\'
SET @cmd='MD '+@DownloadDirPath;
EXEC master..xp_cmdshell @cmd;
DECLARE @Database SYSNAME, 
        @Schema SYSNAME,
        @Table SYSNAME,        
        @BcpParams NVARCHAR(100)='-c -t, -T',
        @cmdBCP NVARCHAR(500),        
        @FileName VARCHAR(600),
		@ResultStatus varchar(10)='success',
        @retExec INT,
        @ServerInstance NVARCHAR(50),                   
        @RootFolder NVARCHAR(165),              
        @TableNameWithSchema VARCHAR(600);
      

    SET @ServerInstance = (select @@SERVERNAME);
    SET @BcpParams = '-t -T -w';
    SET @RootFolder = (select ParameterValue from CORE_CFG_Parameters where ParameterName='DBExportCSVXMLDirPath');----folder where the file is stored------
	Set @RootFolder=@RootFolder+'XML\';
	--select @@SERVERNAME
    DECLARE curXml CURSOR FAST_FORWARD FOR
        SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME
        FROM INFORMATION_SCHEMA.Tables 
        WHERE TABLE_TYPE = 'BASE TABLE';

    OPEN curXml;
    FETCH NEXT FROM curXml INTO @Database, @Schema, @Table
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @TableNameWithSchema = @Database + '.' + @Schema + '.' + @Table;
        SET @FileName = @RootFolder + @Schema + '.' + @Table + '.xml';

        SELECT @cmdBCP = ' bcp "SELECT * FROM '
                         + @TableNameWithSchema 
                         + ' row FOR XML AUTO, ROOT(''' + @Table + '''), elements"'
                         + ' queryout "' + @FileName + '" '
                         + @BcpParams
                         + ' -S ' + @ServerInstance;
       -- PRINT @cmdBCP;
        EXEC @retExec = xp_cmdshell @cmdBCP;
        IF @retExec <> 0
        BEGIN
            CLOSE curXml;
            DEALLOCATE curXml;
            RAISERROR('BCP Error', 16, 1);
        END

        FETCH NEXT FROM curXml INTO @Database, @Schema, @Table;
    END
    CLOSE curXml;
    DEALLOCATE curXml;
End