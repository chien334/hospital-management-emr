-- Script to fix the FK_dbo.ADT_MAP_WardBedType_dbo.ADT_MST_Ward_WardId constraint
-- This script disables cascade delete to prevent circular references

-- First determine the actual name of the tables
DECLARE @TableName NVARCHAR(255)
DECLARE @BedFeaturesMapTable NVARCHAR(255) = 'ADT_MAP_BedFeaturesMap'
DECLARE @WardTable NVARCHAR(255) = 'ADT_MST_Ward'
DECLARE @BedFeatureTable NVARCHAR(255) = 'ADT_MST_BedFeature'
DECLARE @BedTable NVARCHAR(255) = 'ADT_Bed'

-- Check if the constraint exists and drop it if it does
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_dbo.ADT_MAP_WardBedType_dbo.ADT_MST_Ward_WardId')
BEGIN
    ALTER TABLE [dbo].[ADT_MAP_BedFeaturesMap] DROP CONSTRAINT [FK_dbo.ADT_MAP_WardBedType_dbo.ADT_MST_Ward_WardId]
    
    -- Re-create the constraint without cascade delete
    ALTER TABLE [dbo].[ADT_MAP_BedFeaturesMap] ADD CONSTRAINT [FK_dbo.ADT_MAP_WardBedType_dbo.ADT_MST_Ward_WardId] 
    FOREIGN KEY ([WardId]) REFERENCES [dbo].[ADT_MST_Ward] ([WardId]) ON DELETE NO ACTION
    
    PRINT 'Constraint FK_dbo.ADT_MAP_WardBedType_dbo.ADT_MST_Ward_WardId has been modified to disable cascade delete.'
END
ELSE
BEGIN
    -- This is just an alternative name that might be used for the same constraint
    IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_dbo.ADT_MAP_BedFeaturesMap_dbo.ADT_MST_Ward_WardId')
    BEGIN
        ALTER TABLE [dbo].[ADT_MAP_BedFeaturesMap] DROP CONSTRAINT [FK_dbo.ADT_MAP_BedFeaturesMap_dbo.ADT_MST_Ward_WardId]
        
        -- Re-create the constraint without cascade delete
        ALTER TABLE [dbo].[ADT_MAP_BedFeaturesMap] ADD CONSTRAINT [FK_dbo.ADT_MAP_BedFeaturesMap_dbo.ADT_MST_Ward_WardId] 
        FOREIGN KEY ([WardId]) REFERENCES [dbo].[ADT_MST_Ward] ([WardId]) ON DELETE NO ACTION
        
        PRINT 'Constraint FK_dbo.ADT_MAP_BedFeaturesMap_dbo.ADT_MST_Ward_WardId has been modified to disable cascade delete.'
    END
    ELSE
    BEGIN
        PRINT 'No matching constraint found for WardId. Looking for constraints by table relationship instead.'
        
        -- Check for any constraints between the two tables
        DECLARE @FKName NVARCHAR(255)
        SELECT TOP 1 @FKName = name 
        FROM sys.foreign_keys 
        WHERE parent_object_id = OBJECT_ID(@BedFeaturesMapTable)
        AND referenced_object_id = OBJECT_ID(@WardTable)
        
        IF @FKName IS NOT NULL
        BEGIN
            DECLARE @DropSQL NVARCHAR(MAX) = 'ALTER TABLE [dbo].[' + @BedFeaturesMapTable + '] DROP CONSTRAINT [' + @FKName + ']'
            EXEC sp_executesql @DropSQL
            
            DECLARE @AddSQL NVARCHAR(MAX) = 'ALTER TABLE [dbo].[' + @BedFeaturesMapTable + '] ADD CONSTRAINT [' + @FKName + '] 
            FOREIGN KEY ([WardId]) REFERENCES [dbo].[' + @WardTable + '] ([WardId]) ON DELETE NO ACTION'
            EXEC sp_executesql @AddSQL
            
            PRINT 'Constraint ' + @FKName + ' has been modified to disable cascade delete.'
        END
        ELSE
        BEGIN
            PRINT 'No constraint found between ' + @BedFeaturesMapTable + ' and ' + @WardTable
        END
    END
END

-- Check for other potential circular reference constraints related to BedFeatureMap
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_dbo.ADT_MAP_BedFeaturesMap_dbo.ADT_MST_BedFeature_BedFeatureId')
BEGIN
    ALTER TABLE [dbo].[ADT_MAP_BedFeaturesMap] DROP CONSTRAINT [FK_dbo.ADT_MAP_BedFeaturesMap_dbo.ADT_MST_BedFeature_BedFeatureId]
    
    -- Re-create the constraint without cascade delete
    ALTER TABLE [dbo].[ADT_MAP_BedFeaturesMap] ADD CONSTRAINT [FK_dbo.ADT_MAP_BedFeaturesMap_dbo.ADT_MST_BedFeature_BedFeatureId] 
    FOREIGN KEY ([BedFeatureId]) REFERENCES [dbo].[ADT_MST_BedFeature] ([BedFeatureId]) ON DELETE NO ACTION
    
    PRINT 'Constraint FK_dbo.ADT_MAP_BedFeaturesMap_dbo.ADT_MST_BedFeature_BedFeatureId has been modified to disable cascade delete.'
END
ELSE
BEGIN
    -- Check for any constraints between these tables
    DECLARE @BedFeatureFKName NVARCHAR(255)
    SELECT TOP 1 @BedFeatureFKName = name 
    FROM sys.foreign_keys 
    WHERE parent_object_id = OBJECT_ID(@BedFeaturesMapTable)
    AND referenced_object_id = OBJECT_ID(@BedFeatureTable)
    
    IF @BedFeatureFKName IS NOT NULL
    BEGIN
        DECLARE @BedFeatureDropSQL NVARCHAR(MAX) = 'ALTER TABLE [dbo].[' + @BedFeaturesMapTable + '] DROP CONSTRAINT [' + @BedFeatureFKName + ']'
        EXEC sp_executesql @BedFeatureDropSQL
        
        DECLARE @BedFeatureAddSQL NVARCHAR(MAX) = 'ALTER TABLE [dbo].[' + @BedFeaturesMapTable + '] ADD CONSTRAINT [' + @BedFeatureFKName + '] 
        FOREIGN KEY ([BedFeatureId]) REFERENCES [dbo].[' + @BedFeatureTable + '] ([BedFeatureId]) ON DELETE NO ACTION'
        EXEC sp_executesql @BedFeatureAddSQL
        
        PRINT 'Constraint ' + @BedFeatureFKName + ' has been modified to disable cascade delete.'
    END
END

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_dbo.ADT_MAP_BedFeaturesMap_dbo.ADT_Bed_BedId')
BEGIN
    ALTER TABLE [dbo].[ADT_MAP_BedFeaturesMap] DROP CONSTRAINT [FK_dbo.ADT_MAP_BedFeaturesMap_dbo.ADT_Bed_BedId]
    
    -- Re-create the constraint without cascade delete
    ALTER TABLE [dbo].[ADT_MAP_BedFeaturesMap] ADD CONSTRAINT [FK_dbo.ADT_MAP_BedFeaturesMap_dbo.ADT_Bed_BedId] 
    FOREIGN KEY ([BedId]) REFERENCES [dbo].[ADT_Bed] ([BedId]) ON DELETE NO ACTION
    
    PRINT 'Constraint FK_dbo.ADT_MAP_BedFeaturesMap_dbo.ADT_Bed_BedId has been modified to disable cascade delete.'
END
ELSE
BEGIN
    -- Check for any constraints between these tables
    DECLARE @BedFKName NVARCHAR(255)
    SELECT TOP 1 @BedFKName = name 
    FROM sys.foreign_keys 
    WHERE parent_object_id = OBJECT_ID(@BedFeaturesMapTable)
    AND referenced_object_id = OBJECT_ID(@BedTable)
    
    IF @BedFKName IS NOT NULL
    BEGIN
        DECLARE @BedDropSQL NVARCHAR(MAX) = 'ALTER TABLE [dbo].[' + @BedFeaturesMapTable + '] DROP CONSTRAINT [' + @BedFKName + ']'
        EXEC sp_executesql @BedDropSQL
        
        DECLARE @BedAddSQL NVARCHAR(MAX) = 'ALTER TABLE [dbo].[' + @BedFeaturesMapTable + '] ADD CONSTRAINT [' + @BedFKName + '] 
        FOREIGN KEY ([BedId]) REFERENCES [dbo].[' + @BedTable + '] ([BedId]) ON DELETE NO ACTION'
        EXEC sp_executesql @BedAddSQL
        
        PRINT 'Constraint ' + @BedFKName + ' has been modified to disable cascade delete.'
    END
END

PRINT 'Foreign key constraint fix completed.'
