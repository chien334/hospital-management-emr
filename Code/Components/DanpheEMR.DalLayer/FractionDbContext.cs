using System;
using System.Collections.Generic;
using System.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using DanpheEMR.ServerModel;
using DanpheEMR.ServerModel.BillingModels;

namespace DanpheEMR.DalLayer
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

        public FractionDbContext(DbContextOptions<FractionDbContext> options) : base(options)
        {
            //this.Configuration.LazyLoadingEnabled = true;
            //this.Configuration.ProxyCreationEnabled = false;
        }

        public DataTable GetFractionApplicable()
        {
            DataTable result = DALFunctions.GetDataTableFromStoredProc("SP_FRC_GetFractionApplicableList", this as Microsoft.EntityFrameworkCore.DbContext);
            return result;
        }
        public DataTable GetFractionReportByItemList()
        {
            DataTable result = DALFunctions.GetDataTableFromStoredProc("SP_FRC_GetTotalFractionbyItem", this as Microsoft.EntityFrameworkCore.DbContext);
            return result;
        }
        public DataTable GetFractionReportByDoctorList(DateTime FromDate, DateTime ToDate)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() { new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate), new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate) };
            DataTable result = DALFunctions.GetDataTableFromStoredProc("SP_FRC_GetTotalFractionbyDoctor", paramList,  this as Microsoft.EntityFrameworkCore.DbContext);
            return result;
        }
        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
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
