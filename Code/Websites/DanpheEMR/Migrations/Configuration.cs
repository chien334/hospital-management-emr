using System;
using System.Data.Entity;
using System.Data.Entity.Migrations;
using System.Linq;
using DanpheEMR.DalLayer;

namespace DanpheEMR.Migrations
{
    public sealed class AdmissionDbConfiguration : DbMigrationsConfiguration<AdmissionDbContext>
    {
        public AdmissionDbConfiguration()
        {
            AutomaticMigrationsEnabled = true;
            AutomaticMigrationDataLossAllowed = true;
            ContextKey = "DanpheEMR.DalLayer.AdmissionDbContext";
        }

        protected override void Seed(AdmissionDbContext context)
        {
            // This method will be called after migrating to the latest version.
            // You can use the DbSet<T>.AddOrUpdate() helper extension method
            // to avoid creating duplicate seed data.
        }
    }

    public sealed class CoreDbConfiguration : DbMigrationsConfiguration<Core.CoreDbContext>
    {
        public CoreDbConfiguration()
        {
            AutomaticMigrationsEnabled = true;
            AutomaticMigrationDataLossAllowed = true;
            ContextKey = "DanpheEMR.Core.CoreDbContext";
        }

        protected override void Seed(Core.CoreDbContext context)
        {
            // This method will be called after migrating to the latest version.
            // You can use the DbSet<T>.AddOrUpdate() helper extension method
            // to avoid creating duplicate seed data.
        }
    }
}
