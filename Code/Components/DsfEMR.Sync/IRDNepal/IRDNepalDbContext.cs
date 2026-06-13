using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using DsfEMR.Sync.IRDNepal.Models;
using DsfEMR.ServerModel;

namespace DsfEMR.Sync.IRDNepal
{
    class IRDNepalDbContext : DbContext
    {
        private readonly string? _connectionString;

        public IRDNepalDbContext(DbContextOptions<IRDNepalDbContext> options)
            : base(options)
        {
        }

        public IRDNepalDbContext(string conn)
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

        public DbSet<BillingTransactionModel> BillingTransactions { get; set; }
        public DbSet<BillInvoiceReturnModel> BillInvoiceReturns { get; set; }
        public DbSet<PatientModel> Patients { get; set; }
        public DbSet<BillingFiscalYear> BillingFiscalYears { get; set; }
        public DbSet<TaxModel> Taxes { get; set; }
        public DbSet<IRDLogModel> IRDLog { get; set; }
        public DbSet<PHRMInvoiceTransactionModel> PhrmInvoiceSale { get; set; }
        public DbSet<PHRMInvoiceReturnItemsModel> PhrmInvoiceReturnItems { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.Entity<BillingTransactionModel>().ToTable("BIL_TXN_BillingTransaction");
            modelBuilder.Entity<BillInvoiceReturnModel>().ToTable("BIL_TXN_InvoiceReturn");
            modelBuilder.Entity<PatientModel>().ToTable("PAT_Patient");
            modelBuilder.Entity<BillingFiscalYear>().ToTable("BIL_CFG_FiscalYears");
            modelBuilder.Entity<TaxModel>().ToTable("MST_Tax");
            modelBuilder.Entity<IRDLogModel>().ToTable("IRD_Log");
            modelBuilder.Entity<PHRMInvoiceTransactionModel>().ToTable("PHRM_TXN_Invoice");
            modelBuilder.Entity<PHRMInvoiceReturnItemsModel>().ToTable("PHRM_TXN_InvoiceReturnItems");
        }
    }
}
