CREATE TABLE IF NOT EXISTS "SysAdmin_DBLog" (
    "DBLogId" SERIAL PRIMARY KEY,
    "FileName" VARCHAR(500),
    "FolderPath" VARCHAR(500),
    "DatabaseName" VARCHAR(200),
    "DatabaseVersion" VARCHAR(50),
    "IsDBRestorable" BOOLEAN,
    "Action" VARCHAR(200),
    "ActionType" VARCHAR(200),
    "Status" VARCHAR(100),
    "MessageDetail" TEXT,
    "Remarks" VARCHAR(500),
    "CreatedBy" INT,
    "CreatedOn" TIMESTAMP,
    "DeleteOn" TIMESTAMP,
    "IsActive" BOOLEAN
);

CREATE TABLE IF NOT EXISTS "SysAdmin_Parameters" (
    "ParameterId" SERIAL PRIMARY KEY,
    "ParameterGroupName" VARCHAR(200),
    "ParameterName" VARCHAR(200),
    "ParameterValue" TEXT,
    "ValueDataType" VARCHAR(100),
    "Description" TEXT,
    "ParameterType" VARCHAR(100),
    "ValueLookUpList" TEXT
);

CREATE TABLE IF NOT EXISTS "Dsf_CookieAuthInfo" (
    "AuthId" SERIAL PRIMARY KEY,
    "Selector" BIGINT,
    "HashedToken" VARCHAR(500),
    "UserId" INT,
    "Expires" TIMESTAMP
);

CREATE TABLE IF NOT EXISTS "tbl_AuditTableDisplayName" (
    "AuditTableDisplayNameId" SERIAL PRIMARY KEY,
    "DisplayName" VARCHAR(200),
    "TableName" VARCHAR(200),
    "IsActive" BOOLEAN
);

-- Seed SysAdmin_Parameters if empty
INSERT INTO "SysAdmin_Parameters" ("ParameterGroupName", "ParameterName", "ParameterValue", "ValueDataType", "Description", "ParameterType")
SELECT 'Backup', 'DaillyDBBackupLimit', '5', 'string', 'Daily DB Backup Limit', 'System'
WHERE NOT EXISTS (SELECT 1 FROM "SysAdmin_Parameters" WHERE "ParameterName" = 'DaillyDBBackupLimit');

INSERT INTO "SysAdmin_Parameters" ("ParameterGroupName", "ParameterName", "ParameterValue", "ValueDataType", "Description", "ParameterType")
SELECT 'Backup', 'DbBackupFolderPath', '/Users/macbbook/SourceCodes/hospital-management-emr/Backup/', 'string', 'DB Backup Folder Path', 'System'
WHERE NOT EXISTS (SELECT 1 FROM "SysAdmin_Parameters" WHERE "ParameterName" = 'DbBackupFolderPath');

INSERT INTO "SysAdmin_Parameters" ("ParameterGroupName", "ParameterName", "ParameterValue", "ValueDataType", "Description", "ParameterType")
SELECT 'Version', 'DatabaseCurrentVersion', 'v1.0.0', 'string', 'Database Current Version', 'System'
WHERE NOT EXISTS (SELECT 1 FROM "SysAdmin_Parameters" WHERE "ParameterName" = 'DatabaseCurrentVersion');
