using System;
using System.Collections.Generic;
using System.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using DsfEMR.ServerModel;
using DsfEMR.ServerModel.BillingModels;

namespace DsfEMR.DalLayer
{
    public class FractionDbContext : DbContext
    {

        public DbSet<DesignationModel> Designation { get; set; }
        public DbSet<FractionCalculationModel> FractionCalculation { get; set; }
        public DbSet<BillingTransactionItemModel> BillingTransactionItems { get; set; }
        public DbSet<BillServiceItemModel> BillItemPrice { get; set; }
        public DbSet<FractionPercentModel> FractionPercent { get; set; }
        public DbSet<PatientModel> Patient { get; set; }
        public DbSet<EmployeeModel> Employee { get; set; }
        public DbSet<BillMapPriceCategoryServiceItemModel> BillPriceCategoryServiceItems { get; set; }

        
        private readonly string? _connectionString;

        public FractionDbContext(DbContextOptions<FractionDbContext> options)
            : base(options)
        {

        }

        public FractionDbContext(string conn)
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


        public DataTable GetFractionApplicable()
        {
            DataTable result = DALFunctions.GetDataTableFromStoredProc("SP_FRC_GetFractionApplicableList", this);
            return result;
        }
        public DataTable GetFractionReportByItemList()
        {
            DataTable result = DALFunctions.GetDataTableFromStoredProc("SP_FRC_GetTotalFractionbyItem", this);
            return result;
        }
        public DataTable GetFractionReportByDoctorList(DateTime FromDate, DateTime ToDate)
        {
            List<SqlParameter> paramList = new List<SqlParameter>() { new SqlParameter("@FromDate", FromDate), new SqlParameter("@ToDate", ToDate) };
            DataTable result = DALFunctions.GetDataTableFromStoredProc("SP_FRC_GetTotalFractionbyDoctor", paramList,  this);
            return result;
        }
        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);
            base.OnModelCreating(modelBuilder);
            modelBuilder.Entity<DesignationModel>().ToTable("FRC_Designation");
            modelBuilder.Entity<FractionPercentModel>().ToTable("FRC_PercentSetting");
            modelBuilder.Entity<BillServiceItemModel>().ToTable("BIL_MST_ServiceItem");
            modelBuilder.Entity<PatientModel>().ToTable("PAT_Patient");


            modelBuilder.Entity<FractionCalculationModel>().ToTable("FRC_FractionCalculation");
            modelBuilder.Entity<BillingTransactionItemModel>().ToTable("BIL_TXN_BillingTransactionItems");
            modelBuilder.Entity<BillServiceItemModel>().ToTable("BIL_MST_ServiceItem");
            modelBuilder.Entity<PatientModel>().ToTable("PAT_Patient");

            modelBuilder.Entity<EmployeeModel>().ToTable("EMP_Employee");
            modelBuilder.Entity<BillMapPriceCategoryServiceItemModel>().ToTable("BIL_MAP_PriceCategoryServiceItem");

        }


    }
}
