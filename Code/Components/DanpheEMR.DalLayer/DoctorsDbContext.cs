using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using DanpheEMR.ServerModel;
using DanpheEMR.ServerModel.ClinicalModels;

namespace DanpheEMR.DalLayer
{
    public class DoctorsDbContext : DbContext
    {
        public DbSet<VisitModel> Visits { get; set; }
        public DbSet<EmployeeModel> Employees { get; set; }
        public DbSet<PatientModel> Patients { get; set; }
        public DbSet<AdmissionModel> Admissions { get; set; }
        public DbSet<DepartmentModel> Departments { get; set; }
        public DbSet<BillServiceItemModel> BillItemPrice { get; set; }
        public DbSet<VisitSummaryModel> VisitSummary { get; set; }
        public DbSet<TemplateNoteModel> TemplateNotes { get; set; }
        
        private readonly string? _connectionString;

        public DoctorsDbContext(DbContextOptions<DoctorsDbContext> options)
            : base(options)
        {

        }

        public DoctorsDbContext(string conn)
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

            modelBuilder.Entity<PatientModel>().ToTable("PAT_Patient");
            modelBuilder.Entity<VisitModel>().ToTable("PAT_PatientVisits");
            modelBuilder.Entity<AdmissionModel>().ToTable("ADT_PatientAdmission");

            // Patient and visit mappings
            modelBuilder.Entity<VisitModel>()
                   .HasOne(a => a.Patient)
                   .WithMany(a => a.Visits)
                    .HasForeignKey(s => s.PatientId);



            //Admission and visit

            modelBuilder.Entity<AdmissionModel>()
                .HasKey(t => t.PatientVisitId);
            modelBuilder.Entity<VisitModel>()
                .HasOne(a => a.Admission)
                .WithOne(a => a.Visit);

            modelBuilder.Entity<EmployeeModel>().ToTable("EMP_Employee");
            modelBuilder.Entity<DepartmentModel>().ToTable("MST_Department");
            modelBuilder.Entity<BillServiceItemModel>().ToTable("BIL_MST_ServiceItem");
            modelBuilder.Entity<VisitSummaryModel>().ToTable("DOC_TXN_VisitSummary");
            modelBuilder.Entity<TemplateNoteModel>().ToTable("CLN_Template");
        }

    }

}

