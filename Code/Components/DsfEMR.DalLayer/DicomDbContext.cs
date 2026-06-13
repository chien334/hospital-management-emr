using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using DsfEMR.ServerModel;
using Microsoft.EntityFrameworkCore;

namespace DsfEMR.DalLayer
{
    public class DicomDbContext : DbContext
    {
        
        private readonly string? _connectionString;

        public DicomDbContext(DbContextOptions<DicomDbContext> options)
            : base(options)
        {

        }

        public DicomDbContext(string conn)
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


        public DbSet<PatientStudyModel> PatientStudies { get; set; }
        public DbSet<DicomFileInfoModel> DicomFiles { get; set; }
        public DbSet<SeriesInfoModel> Series { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);
            base.OnModelCreating(modelBuilder);
            modelBuilder.Entity<PatientStudyModel>().ToTable("DCM_PatientStudy");
            modelBuilder.Entity<DicomFileInfoModel>().ToTable("DCM_DicomFiles");
            modelBuilder.Entity<SeriesInfoModel>().ToTable("DCM_Series");
        }
    }
}
