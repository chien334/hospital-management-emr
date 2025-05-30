using System;
using System.Linq;
using System.Data;
using System.Data.SqlClient;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;
using DanpheEMR.ServerModel;
using DanpheEMR.ServerModel.AccountingModels;
using DanpheEMR.ServerModel.AccountingModels.Config;

namespace DanpheEMR.DalLayer
{
    public class AccountingDbContextCore : DbContext
    {
        private readonly string _connectionString;

        public AccountingDbContextCore(string connectionString)
        {
            _connectionString = connectionString;
        }

        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
            if (!optionsBuilder.IsConfigured)
            {
                optionsBuilder.UseSqlServer(_connectionString);
            }
        }

        public DbSet<ChartOfAccountModel> ChartOfAccounts { get; set; }
        public DbSet<VoucherModel> Vouchers { get; set; }
        public DbSet<VoucherHeadModel> VoucherHeads { get; set; }
        public DbSet<LedgerGroupCategoryModel> LedgerGroupsCategory { get; set; }
        public DbSet<LedgerGroupModel> LedgerGroups { get; set; }
        public DbSet<LedgerModel> Ledgers { get; set; }
        public DbSet<TransactionModel> Transactions { get; set; }
        public DbSet<TransactionItemModel> TransactionItems { get; set; }
        public DbSet<TransactionItemDetailModel> TransactionItemDetails { get; set; }
        public DbSet<TransactionInventoryItemModel> TransactionInventoryItems { get; set; }
        public DbSet<FiscalYearModel> FiscalYears { get; set; }
        public DbSet<TransactionCostCenterItemModel> TransactionCostCenters { get; set; }
        public DbSet<CostCenterItemModel> CostCenterItems { get; set; }
        public DbSet<CostCenterModel> CostCenters { get; set; }
        public DbSet<TransactionLinkModel> TransactionLinks { get; set; }
        public DbSet<GroupMappingModel> GroupMapping { get; set; }
        public DbSet<MappingDetailModel> MappingDetail { get; set; }
        public DbSet<SyncBillingAccountingModel> SyncBillingAccounting { get; set; }
        public DbSet<MapTransactionItemCostCenterItemModel> MapTxnItemCostCenterItem { get; set; }
        public DbSet<LedgerBalanceHistoryModel> LedgerBalanceHistory { get; set; }
        public DbSet<PatientModel> PatientModel { get; set; }
        public DbSet<PHRMSupplierModel> PHRMSupplier { get; set; }
        public DbSet<LedgerMappingModel> LedgerMappings { get; set; }
        public DbSet<VendorMasterModel> InvVendors { get; set; }
        public DbSet<RbacUser> Users { get; set; }
        public DbSet<EmployeeModel> Emmployees { get; set; }
        public DbSet<CfgParameterModel> CFGParameters { get; set; }
        public DbSet<ItemMasterModel> InventoryItems { get; set; }
        public DbSet<HospitalModel> Hospitals { get; set; }
        public DbSet<HospitalTransferRuleMappingModel> HospitalTransferRuleMappings { get; set; }
        public DbSet<ReverseTransactionModel> ReverseTransaction { get; set; }
        public DbSet<AccountingBillLedgerMappingModel> AccountBillLedgerMapping { get; set; }
        public DbSet<AccountingCodeDetailsModel> ACCCodeDetails { get; set; }
        public DbSet<CreditOrganizationModel> BillCreditOrganizations { get; set; }
        public DbSet<PaymentInfoModel> PaymentInfo { get; set; }
        public DbSet<IncentiveFractionItemModel> IncentiveFractionItems { get; set; }
        public DbSet<AccSectionModel> Section { get; set; }
        public DbSet<ItemSubCategoryMasterModel> ItemSubCategoryMaster { get; set; }
        public DbSet<DepartmentModel> Departments { get; set; }
        public DbSet<FiscalYearLogModel> FiscalYearLog { get; set; }
        public DbSet<EditVoucherLogModel> EditVoucherLog { get; set; }
        public DbSet<ServiceDepartmentModel> ServiceDepartment { get; set; }
        public DbSet<BillServiceItemModel> ServiceItems { get; set; }
        public DbSet<AccountingTransactionHistoryModel> AccountingTransactionHistory { get; set; }
        public DbSet<PrimaryGroupModel> PrimaryGroup { get; set; }
        public DbSet<BankReconciliationModel> BankReconciliationModel { get; set; }
        public DbSet<BankReconciliationCategoryModel> BankReconciliationCategory { get; set; }
        public DbSet<GoodsReceiptModel> GoodsReceiptModels { get; set; }
        public DbSet<AccountingPaymentModel> AccountingPaymentModels { get; set; }
        public DbSet<PHRMGoodsReceiptModel> PHRMGoodsReceipt { get; set; }
        public DbSet<PaymentModes> PaymentMode { get; set; }
        public DbSet<PHRMCreditOrganizationsModel> PHRMCreditOrganization { get; set; }
        public DbSet<InventoryChargesMasterModel> InvCharges { get; set; }
        public DbSet<SubLedgerModel> SubLedger { get; set; }
        public DbSet<SubLedgerTransactionModel> SubLedgerRecord { get; set; }
        public DbSet<SubLedgerBalanceHistory> SubLedgerBalanceHistory { get; set; }
        public DbSet<MedicareTypes> MedicareType { get; set; }
        public DbSet<BankAndSuspenseAccountReconciliationMapModel> SuspenseAccountReconcileMap { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            // Configure mapping between tables and entities
            modelBuilder.Entity<ChartOfAccountModel>().ToTable("ACC_MST_ChartOfAccounts");
            modelBuilder.Entity<VoucherModel>().ToTable("ACC_MST_Voucher");
            modelBuilder.Entity<VoucherHeadModel>().ToTable("ACC_MST_VoucherHead");
            modelBuilder.Entity<LedgerGroupCategoryModel>().ToTable("ACC_MST_LedgerGroupCategory");
            modelBuilder.Entity<LedgerGroupModel>().ToTable("ACC_MST_LedgerGroup");
            modelBuilder.Entity<LedgerModel>().ToTable("ACC_Ledger");
            
            // Configure relationships with proper Delete Behavior
            modelBuilder.Entity<LedgerModel>()
                        .HasOne(l => l.LedgerGroup)
                        .WithMany(g => g.Ledgers)
                        .HasForeignKey(l => l.LedgerGroupId)
                        .OnDelete(DeleteBehavior.NoAction);
            
            // More table mappings
            modelBuilder.Entity<TransactionModel>().ToTable("ACC_TXN_Transaction");
            modelBuilder.Entity<TransactionItemModel>().ToTable("ACC_TXN_TransactionItem");
            modelBuilder.Entity<TransactionItemDetailModel>().ToTable("ACC_TXN_TransactionItemDetail");
            modelBuilder.Entity<TransactionInventoryItemModel>().ToTable("ACC_TXN_InventoryItems");
            modelBuilder.Entity<FiscalYearModel>().ToTable("ACC_MST_FiscalYear");
            modelBuilder.Entity<TransactionCostCenterItemModel>().ToTable("ACC_TXN_CostCenterItem");
            modelBuilder.Entity<CostCenterItemModel>().ToTable("ACC_MST_CostCenterItems");
            modelBuilder.Entity<CostCenterModel>().ToTable("ACC_MST_CostCenter");
            
            // Add any necessary indexes
            modelBuilder.Entity<TransactionModel>()
                        .HasIndex(t => t.VoucherNumber);
            
            // Configure many-to-many relationships if needed
            modelBuilder.Entity<MapTransactionItemCostCenterItemModel>()
                        .HasKey(map => new { map.TransactionItemId, map.CostCenterId });
        }
    }
}
