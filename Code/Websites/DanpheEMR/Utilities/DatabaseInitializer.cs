using System;
using System.Data.Entity;
using System.Data.Entity.Infrastructure;
using System.Data.SqlClient;
using DanpheEMR.DalLayer;

namespace DanpheEMR.Utilities
{
    public static class DatabaseInitializer
    {
        public static void Initialize(string connectionString)
        {
            try
            {
                // First, disable the automatic initializer to prevent it from running
                Database.SetInitializer<AdmissionDbContext>(null);
                
                // Create a new instance of the context
                using (var context = new AdmissionDbContext(connectionString))
                {
                    bool dbExists = context.Database.Exists();
                    
                    if (!dbExists)
                    {
                        // Create the database without applying the model
                        context.Database.Create();
                    }
                    
                    // Execute custom SQL to fix the problematic foreign key constraints
                    // Whether the database is new or existing
                    FixForeignKeyConstraints(context);
                }
            }
            catch (Exception ex)
            {
                // Log the exception
                Console.WriteLine($"Error initializing database: {ex.Message}");
                throw;
            }
        }
        
        private static void FixForeignKeyConstraints(DbContext context)
        {
            try
            {
                // Fix the WardId foreign key constraint
                context.Database.ExecuteSqlCommand(@"
                    IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_dbo.ADT_MAP_WardBedType_dbo.ADT_MST_Ward_WardId')
                    BEGIN
                        ALTER TABLE [dbo].[ADT_MAP_BedFeaturesMap] DROP CONSTRAINT [FK_dbo.ADT_MAP_WardBedType_dbo.ADT_MST_Ward_WardId]
                        ALTER TABLE [dbo].[ADT_MAP_BedFeaturesMap] ADD CONSTRAINT [FK_dbo.ADT_MAP_WardBedType_dbo.ADT_MST_Ward_WardId] 
                        FOREIGN KEY ([WardId]) REFERENCES [dbo].[ADT_MST_Ward] ([WardId]) ON DELETE NO ACTION
                    END
                ");
                
                // Fix other potential constraints that might cause circular references
                context.Database.ExecuteSqlCommand(@"
                    IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_dbo.ADT_MAP_BedFeaturesMap_dbo.ADT_MST_BedFeature_BedFeatureId')
                    BEGIN
                        ALTER TABLE [dbo].[ADT_MAP_BedFeaturesMap] DROP CONSTRAINT [FK_dbo.ADT_MAP_BedFeaturesMap_dbo.ADT_MST_BedFeature_BedFeatureId]
                        ALTER TABLE [dbo].[ADT_MAP_BedFeaturesMap] ADD CONSTRAINT [FK_dbo.ADT_MAP_BedFeaturesMap_dbo.ADT_MST_BedFeature_BedFeatureId] 
                        FOREIGN KEY ([BedFeatureId]) REFERENCES [dbo].[ADT_MST_BedFeature] ([BedFeatureId]) ON DELETE NO ACTION
                    END
                ");
                
                context.Database.ExecuteSqlCommand(@"
                    IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_dbo.ADT_MAP_BedFeaturesMap_dbo.ADT_Bed_BedId')
                    BEGIN
                        ALTER TABLE [dbo].[ADT_MAP_BedFeaturesMap] DROP CONSTRAINT [FK_dbo.ADT_MAP_BedFeaturesMap_dbo.ADT_Bed_BedId]
                        ALTER TABLE [dbo].[ADT_MAP_BedFeaturesMap] ADD CONSTRAINT [FK_dbo.ADT_MAP_BedFeaturesMap_dbo.ADT_Bed_BedId] 
                        FOREIGN KEY ([BedId]) REFERENCES [dbo].[ADT_Bed] ([BedId]) ON DELETE NO ACTION
                    END
                ");
            }
            catch (SqlException sqlEx)
            {
                // The table might not exist yet, which is fine
                if (sqlEx.Number != 3701) // 3701 is "Cannot drop the constraint ... because it does not exist or you do not have permission"
                {
                    throw;
                }
            }
        }
    }
}
