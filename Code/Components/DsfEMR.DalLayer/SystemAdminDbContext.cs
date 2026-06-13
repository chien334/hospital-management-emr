using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using DsfEMR.ServerModel;
using Microsoft.EntityFrameworkCore;
using Microsoft.Data.SqlClient;
using System.Data;

namespace DsfEMR.DalLayer
{
    public class SystemAdminDbContext : DbContext
    {        
        public DbSet<DatabaseLogModel> DatabaseLog { get; set; }
        public DbSet<AdminParametersModel> AdminParameters { get; set; }
        public DbSet<LoginInformationModel> LoginInformation { get; set; }
        public DbSet<CookieAuthInfoModel> CookieInformation { get; set; }
        public DbSet<AuditTableDisplayName> AuditTableDisplayNames { get; set; }

        
        private readonly string? _connectionString;

        public SystemAdminDbContext(DbContextOptions<SystemAdminDbContext> options)
            : base(options)
        {

        }

        public SystemAdminDbContext(string conn)
        {
            _connectionString = conn;

        }

        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
            if (!optionsBuilder.IsConfigured && !string.IsNullOrEmpty(_connectionString))
            {
                optionsBuilder.UseNpgsql(_connectionString);
            }
            base.OnConfiguring(optionsBuilder);
        }


        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);
            base.OnModelCreating(modelBuilder);
            modelBuilder.Entity<DatabaseLogModel>().ToTable("SysAdmin_DBLog");
            modelBuilder.Entity<AdminParametersModel>().ToTable("SysAdmin_Parameters");
            modelBuilder.Entity<LoginInformationModel>().ToTable("DsfLogInInformation");
            modelBuilder.Entity<CookieAuthInfoModel>().ToTable("Dsf_CookieAuthInfo");
            modelBuilder.Entity<AuditTableDisplayName>().ToTable("tbl_AuditTableDisplayName");
        }

      
    }
}
