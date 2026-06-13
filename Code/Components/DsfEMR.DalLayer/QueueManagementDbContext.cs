using DsfEMR.ServerModel;
using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DsfEMR.DalLayer
{
    public class QueueManagementDbContext : DbContext
    {
        
        private readonly string? _connectionString;

        public QueueManagementDbContext(DbContextOptions<QueueManagementDbContext> options)
            : base(options)
        {

        }

        public QueueManagementDbContext(string conn)
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

        public DbSet<DepartmentModel> Department { get; set; }
        public DbSet<VisitModel> Visits { get; set; }
        public DbSet<PatientModel> Patients { get; set; }
        public DbSet<EmployeeModel> Employees { get; set; }
        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);
            base.OnModelCreating(modelBuilder);
            modelBuilder.Entity<EmployeeModel>().ToTable("EMP_Employee");
            modelBuilder.Entity<DepartmentModel>().ToTable("MST_Department");
            modelBuilder.Entity<PatientModel>().ToTable("PAT_Patient");
            modelBuilder.Entity<VisitModel>().ToTable("PAT_PatientVisits");
            modelBuilder.Entity<VisitModel>()
            .HasOne(a => a.Patient)
            .WithMany(a => a.Visits)
            .HasForeignKey(s => s.PatientId);
            modelBuilder.Entity<VisitModel>()
            .HasOne(a => a.Admission)
            .WithOne(a => a.Visit);
        }
    }
}
