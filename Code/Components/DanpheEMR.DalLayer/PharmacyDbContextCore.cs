using Audit.EntityFramework;
using DanpheEMR.Security;
using DanpheEMR.ServerModel;
using DanpheEMR.ServerModel.BillingModels;
using DanpheEMR.ServerModel.CommonModels;
using DanpheEMR.ServerModel.MasterModels;
using DanpheEMR.ServerModel.MedicareModels;
using DanpheEMR.ServerModel.PatientModels;
using DanpheEMR.ServerModel.PharmacyModels;
using DanpheEMR.ServerModel.PharmacyModels.Provisional;
using DanpheEMR.ServerModel.VerificationModels.Pharmacy;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

namespace DanpheEMR.DalLayer
{
    public class PharmacyDbContextCore : DbContext
    {
        private readonly string _connectionString;

        public PharmacyDbContextCore(string connectionString)
        {
            _connectionString = connectionString;
        }

        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
            if (!optionsBuilder.IsConfigured)
            {
                optionsBuilder.UseSqlServer(_connectionString, 
                    options => options.CommandTimeout(180)); // Set the command timeout
            }
        }

        public DbSet<PHRMRackModel> PHRMRack { get; set; }
        public DbSet<PHRM_MAP_ItemToRack> PHRMRackItem { get; set; }
        public DbSet<RbacUser> Users { get; set; }
        public DbSet<PHRMSupplierModel> PHRMSupplier { get; set; }
        public DbSet<PHRMCompanyModel> PHRMCompany { get; set; }
        public DbSet<PHRMCategoryModel> PHRMCategory { get; set; }
        public DbSet<PHRMUnitOfMeasurementModel> PHRMUnitOfMeasurement { get; set; }
        public DbSet<PHRMItemMasterModel> PHRMItemMaster { get; set; }
        public DbSet<PHRM_MAP_MstItemsPriceCategory> PHRM_MAP_MstItemsPriceCategories { get; set; }
        public DbSet<PHRMTAXModel> PHRMTAX { get; set; }
        public DbSet<PHRMItemTypeModel> PHRMItemType { get; set; }
        public DbSet<PHRMPackingTypeModel> PHRMPackingType { get; set; }
        public DbSet<PHRMPurchaseOrderModel> PHRMPurchaseOrder { get; set; }
        public DbSet<PHRMPurchaseOrderItemsModel> PHRMPurchaseOrderItems { get; set; }
        public DbSet<PHRMGoodsReceiptModel> PHRMGoodsReceipt { get; set; }
        public DbSet<PHRMGoodsReceiptItemsModel> PHRMGoodsReceiptItems { get; set; }
        public DbSet<PHRMPatient> PHRMPatient { get; set; }
        public DbSet<VisitModel> PHRMPatientVisit { get; set; }
        public DbSet<PHRMPrescriptionModel> PHRMPrescription { get; set; }
        public DbSet<PHRMPrescriptionItemModel> PHRMPrescriptionItems { get; set; }
        public DbSet<PHRMBillTransactionModel> PHRMBillTransaction { get; set; }
        public DbSet<PHRMBillTransactionItem> PHRMBillTransactionItems { get; set; }
        public DbSet<PHRMInvoiceTransactionModel> PHRMInvoiceTransaction { get; set; }
        public DbSet<PHRMTransactionCreditBillStatus> PHRMTransactionCreditBillStatus { get; set; }
        public DbSet<PHRMInvoiceTransactionItemsModel> PHRMInvoiceTransactionItems { get; set; }
        public DbSet<PHRMReturnToSupplierModel> PHRMReturnToSupplier { get; set; }
        public DbSet<PHRMReturnToSupplierItemsModel> PHRMReturnToSupplierItem { get; set; }
        public DbSet<PHRMWriteOffModel> PHRMWriteOff { get; set; }
        public DbSet<PHRMStoreSalesCategoryModel> PHRMStoreSalesCategory { get; set; }
        public DbSet<PHRMWriteOffItemsModel> PHRMWriteOffItem { get; set; }
        public DbSet<PHRMInvoiceReturnItemsModel> PHRMInvoiceReturnItemsModel { get; set; }
        public DbSet<PHRMInvoiceReturnModel> PHRMInvoiceReturnModel { get; set; }
        public DbSet<EmployeePreferences> EmployeePreferences { get; set; }
        public DbSet<PHRMGenericModel> PHRMGenericModel { get; set; }
        public DbSet<PHRMNarcoticRecord> PHRMNarcoticRecord { get; set; }
        public DbSet<PHRMStoreModel> PHRMStore { get; set; }
        public DbSet<PHRMCounter> PHRMCounters { get; set; }
        public DbSet<PHRMGenericDosageNFreqMap> GenericDosageMaps { get; set; }
        public DbSet<IRDLogModel> IRDLog { get; set; }
        public DbSet<PHRMDrugsRequistionModel> DrugRequistion { get; set; }
        public DbSet<PHRMDrugsRequistionItemsModel> DrugRequistionItem { get; set; }
        public DbSet<PHRMDepositModel> DepositModel { get; set; }
        public DbSet<PharmacyFiscalYear> PharmacyFiscalYears { get; set; }
        public DbSet<PHRMSettlementModel> PHRMSettlements { get; set; }
        public DbSet<WARDRequisitionModel> WardRequisition { get; set; }
        public DbSet<WARDRequisitionItemsModel> WardRequisitionItem { get; set; }
        public DbSet<WardModel> WardModel { get; set; }
        public DbSet<WARDStockModel> WardStock { get; set; }
        public DbSet<WARDDispatchModel> WardDisapatch { get; set; }
        public DbSet<WARDDispatchItemsModel> WardDispatchItems { get; set; }
        public DbSet<EmployeeModel> Employees { get; set; }
        public DbSet<WARDConsumptionModel> WardConsumption { get; set; }
        public DbSet<CountrySubDivisionModel> CountrySubDivision { get; set; }
        public DbSet<DepartmentModel> Departments { get; set; }
        public DbSet<PHRMStoreRequisitionModel> StoreRequisition { get; set; }
        public DbSet<PHRMStoreRequisitionItemsModel> StoreRequisitionItems { get; set; }
        public DbSet<PHRMDispatchItemsModel> StoreDispatchItems { get; set; }
        public DbSet<WARDTransactionModel> WardTransactionModel { get; set; }
        public DbSet<InventoryTermsModel> Terms { get; set; }
        public DbSet<PHRMCreditOrganizationsModel> CreditOrganizations { get; set; }
        public DbSet<PHRMMRPHistoryModel> MRPHistories { get; set; }
        public DbSet<InvoiceHeaderModel> InvoiceHeader { get; set; }
        public DbSet<CfgParameterModel> CFGParameters { get; set; }
        public DbSet<PHRMExpiryDateBatchNoHistoryModel> ExpiryDateBatchNoHistories { get; set; }
        public DbSet<PHRMStockMaster> StockMasters { get; set; }
        public DbSet<PHRMStoreStockModel> StoreStocks { get; set; }
        public DbSet<PHRMStockTransactionModel> StockTransactions { get; set; }
        public DbSet<PHRMGenericDosageNFreqMap> GenericDosageNFreqMap { get; set; }
        public DbSet<PHRMStockTransactionCustomDetailsModel> StockTransactionCustomDetails { get; set; }
        public DbSet<PatientModel> Patients { get; set; }
        public DbSet<PHRMNotification> PHRMNotification { get; set; }
        public DbSet<CountryModel> Country { get; set; }
        public DbSet<PriceCategoryModel> PriceCategory { get; set; }
        public DbSet<PHRMMapPatientConsumptionItem> PatientConsumptionItems { get; set; }
        public DbSet<PHRMBillTransactionReturnItemsModel> PHRMBillTransactionReturnItems { get; set; }
        public DbSet<PHRMMapSupplierVsItemViewModel> PHRMMapSupplierVsItem { get; set; }
        public DbSet<PHRMBillTransactionReturnModel> PHRMTransactionReturn { get; set; }
        public DbSet<PHRMDispatchModel> PHRMDispatch { get; set; }
        public DbSet<PHRMSupplierLedgerTransactionModel> PHRMSupplierLedgerTransaction { get; set; }
        public DbSet<PHRMPaymentModel> PaymentModel { get; set; }
        public DbSet<PHRMInvoiceTransactionCreditNoteItemsModel> PHRMInvoiceTransactionCreditNoteItems { get; set; }
        public DbSet<PHRMInvoiceTransactionCreditNoteModel> PHRMInvoiceTransactionCreditNote { get; set; }
        public DbSet<PHRMFrequencyModel> PHRMFrequency { get; set; }
        public DbSet<PHRMSupplierPOModel> PHRMSupplierPO { get; set; }
        public DbSet<PHRMSupplierPOItemsModel> PHRMSupplierPOItems { get; set; }

        // Audit related tables
        public DbSet<PHRMAuditModel> PHRMAudit { get; set; }
        public DbSet<PHRMAuditPrescriptionItemsModel> PHRMAuditPrescriptionItems { get; set; }
        public DbSet<PHRMAuditTrailModel> PHRMAuditTrail { get; set; }
        public DbSet<PHRMAuditDetailModel> PHRMAuditDetails { get; set; }

        // Verification related tables
        public DbSet<PHRMVerificationModel> PHRMVerification { get; set; }
        public DbSet<PHRMGoodReceiptVerificationMapModel> PHRMGoodReceiptVerificationMap { get; set; }

        // Provisional related tables
        public DbSet<PHRMProvisionalItemModel> PHRMProvisionalItem { get; set; }
        public DbSet<PHRMProvisionalBillingTransactionModel> PHRMProvisionalBillingTransaction { get; set; }
        public DbSet<PHRMProvisionalItemPriceCategoryMap> PHRMProvisionalItemPriceCategoryMap { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            // Map entities to tables
            modelBuilder.Entity<PHRMRackModel>().ToTable("PHRM_MST_Rack");
            modelBuilder.Entity<PHRM_MAP_ItemToRack>().ToTable("PHRM_MAP_ItemToRack");
            modelBuilder.Entity<RbacUser>().ToTable("RBAC_User");
            modelBuilder.Entity<PHRMSupplierModel>().ToTable("PHRM_MST_Supplier");
            modelBuilder.Entity<PHRMCompanyModel>().ToTable("PHRM_MST_Company");
            modelBuilder.Entity<PHRMCategoryModel>().ToTable("PHRM_MST_Category");
            modelBuilder.Entity<PHRMUnitOfMeasurementModel>().ToTable("PHRM_MST_UnitOfMeasurement");
            modelBuilder.Entity<PHRMItemMasterModel>().ToTable("PHRM_MST_Item");
            modelBuilder.Entity<PHRM_MAP_MstItemsPriceCategory>().ToTable("PHRM_MAP_MstItemsPriceCategory");
            modelBuilder.Entity<PHRMTAXModel>().ToTable("PHRM_MST_Tax");
            modelBuilder.Entity<PHRMItemTypeModel>().ToTable("PHRM_MST_ItemType");
            modelBuilder.Entity<PHRMPackingTypeModel>().ToTable("PHRM_MST_PackingType");
            modelBuilder.Entity<PHRMPurchaseOrderModel>().ToTable("PHRM_TXN_PurchaseOrder");
            modelBuilder.Entity<PHRMPurchaseOrderItemsModel>().ToTable("PHRM_TXN_PurchaseOrderItems");
            modelBuilder.Entity<PHRMGoodsReceiptModel>().ToTable("PHRM_TXN_GoodsReceipt");
            modelBuilder.Entity<PHRMGoodsReceiptItemsModel>().ToTable("PHRM_TXN_GoodsReceiptItems");
            modelBuilder.Entity<PHRMPatient>().ToTable("PAT_Patient");
            modelBuilder.Entity<VisitModel>().ToTable("PAT_PatientVisits");
            modelBuilder.Entity<PHRMPrescriptionModel>().ToTable("PHRM_TXN_Prescription");
            modelBuilder.Entity<PHRMPrescriptionItemModel>().ToTable("PHRM_TXN_PrescriptionItems");
            modelBuilder.Entity<PHRMBillTransactionModel>().ToTable("PHRM_TXN_BillTransaction");
            modelBuilder.Entity<PHRMBillTransactionItem>().ToTable("PHRM_TXN_BillTransactionItem");
            modelBuilder.Entity<PHRMInvoiceTransactionModel>().ToTable("PHRM_TXN_InvoiceTransaction");
            modelBuilder.Entity<PHRMTransactionCreditBillStatus>().ToTable("PHRM_TXN_TransactionCreditBillStatus");
            modelBuilder.Entity<PHRMInvoiceTransactionItemsModel>().ToTable("PHRM_TXN_InvoiceTransactionItems");
            modelBuilder.Entity<PHRMReturnToSupplierModel>().ToTable("PHRM_TXN_ReturnToSupplier");
            modelBuilder.Entity<PHRMReturnToSupplierItemsModel>().ToTable("PHRM_TXN_ReturnToSupplierItems");
            modelBuilder.Entity<PHRMWriteOffModel>().ToTable("PHRM_TXN_WriteOff");
            modelBuilder.Entity<PHRMStoreSalesCategoryModel>().ToTable("PHRM_MST_StoreSalesCategory");
            modelBuilder.Entity<PHRMWriteOffItemsModel>().ToTable("PHRM_TXN_WriteOffItems");
            modelBuilder.Entity<PHRMInvoiceReturnItemsModel>().ToTable("PHRM_TXN_InvoiceReturnItems");
            modelBuilder.Entity<PHRMInvoiceReturnModel>().ToTable("PHRM_TXN_InvoiceReturn");
            modelBuilder.Entity<EmployeePreferences>().ToTable("EMP_EmployeePreferences");
            modelBuilder.Entity<PHRMGenericModel>().ToTable("PHRM_MST_Generic");
            modelBuilder.Entity<PHRMNarcoticRecord>().ToTable("PHRM_MST_NarcoticRecord");
            modelBuilder.Entity<PHRMStoreModel>().ToTable("PHRM_MST_Store");
            modelBuilder.Entity<PHRMCounter>().ToTable("PHRM_CFG_Counter");
            modelBuilder.Entity<PHRMGenericDosageNFreqMap>().ToTable("PHRM_MAP_GenericDosageNFreq");
            modelBuilder.Entity<IRDLogModel>().ToTable("IRD_LOG");
            modelBuilder.Entity<PHRMDrugsRequistionModel>().ToTable("PHRM_TXN_DrugsRequisition");
            modelBuilder.Entity<PHRMDrugsRequistionItemsModel>().ToTable("PHRM_TXN_DrugsRequisitionItems");
            modelBuilder.Entity<PHRMDepositModel>().ToTable("PHRM_TXN_Deposit");
            modelBuilder.Entity<PharmacyFiscalYear>().ToTable("PHRM_CFG_FiscalYears");
            modelBuilder.Entity<PHRMSettlementModel>().ToTable("PHRM_TXN_Settlement");

            // Handle relationships and configuration that needs special attention
            modelBuilder.Entity<PHRM_MAP_ItemToRack>()
                .HasKey(a => new { a.ItemId, a.StoreId, a.RackId });

            // Add more configurations as needed for complex relationships or special cases
            
            // Implement any OnDelete behavior configurations here
            // Example:
            // modelBuilder.Entity<PHRMGoodsReceiptItemsModel>()
            //     .HasOne(g => g.GoodsReceipt)
            //     .WithMany(g => g.GoodsReceiptItemsList)
            //     .HasForeignKey(g => g.GoodReceiptId)
            //     .OnDelete(DeleteBehavior.NoAction);
        }

        // Method to execute a stored procedure and return DataTable
        public DataTable GetStoreStockDetails(int? StoreId, int? ItemId, DateTime? FromDate, DateTime? ToDate)
        {
            DataTable result = new DataTable();
            
            using (var connection = new SqlConnection(_connectionString))
            {
                connection.Open();
                
                using (var command = new SqlCommand("SP_PHRM_GetStoreStockDetails", connection))
                {
                    command.CommandType = CommandType.StoredProcedure;
                    
                    command.Parameters.Add(new SqlParameter("@StoreId", SqlDbType.Int) { Value = StoreId ?? (object)DBNull.Value });
                    command.Parameters.Add(new SqlParameter("@ItemId", SqlDbType.Int) { Value = ItemId ?? (object)DBNull.Value });
                    command.Parameters.Add(new SqlParameter("@FromDate", SqlDbType.DateTime) { Value = FromDate ?? (object)DBNull.Value });
                    command.Parameters.Add(new SqlParameter("@ToDate", SqlDbType.DateTime) { Value = ToDate ?? (object)DBNull.Value });
                    
                    using (var adapter = new SqlDataAdapter(command))
                    {
                        adapter.Fill(result);
                    }
                }
            }
            
            return result;
        }
    }
}
