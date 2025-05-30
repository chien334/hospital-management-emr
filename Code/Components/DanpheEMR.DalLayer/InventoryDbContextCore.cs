using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using DanpheEMR.ServerModel;
using DanpheEMR.ServerModel.InventoryModels;
using Microsoft.EntityFrameworkCore;
using DanpheEMR.Security;
using DanpheEMR.ServerModel.WardSupplyModels;
using System.Data;
using System.Data.SqlClient;

namespace DanpheEMR.DalLayer
{
    public class InventoryDbContextCore : DbContext
    {
        private readonly string _connectionString;

        public InventoryDbContextCore(string connectionString)
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

        public DbSet<PurchaseOrderModel> PurchaseOrders { get; set; }
        public DbSet<ItemMasterModel> Items { get; set; }
        public DbSet<VendorMasterModel> Vendors { get; set; }
        public DbSet<PurchaseOrderItemsModel> PurchaseOrderItems { get; set; }
        public DbSet<GoodsReceiptModel> GoodsReceipts { get; set; }
        public DbSet<GoodsReceiptItemsModel> GoodsReceiptItems { get; set; }
        public DbSet<MAP_GoodsReceiptItems_OtherCharges> GoodsReceiptItemsOtherCharges { get; set; }
        public DbSet<MAP_GoodsReceipt_OtherCharges> GoodsReceiptOtherCharges { get; set; }
        public DbSet<RequisitionModel> Requisitions { get; set; }
        public DbSet<RequisitionItemsModel> RequisitionItems { get; set; }
        public DbSet<DispatchItemsModel> DispatchItems { get; set; }
        public DbSet<DispatchModel> Dispatches { get; set; }
        public DbSet<MAP_DispatchItems_FixedAssetStock> DispatchItemsFixedAssetStock { get; set; }
        public DbSet<WriteOffItemsModel> WriteOffItems { get; set; }
        public DbSet<CurrencyMasterModel> Currencies { get; set; }
        public DbSet<ItemCategoryMasterModel> ItemCategories { get; set; }
        public DbSet<UnitOfMeasurementMasterModel> UnitOfMeasurements { get; set; }
        public DbSet<PackagingTypeMasterModel> PackagingTypes { get; set; }
        public DbSet<AccountHeadMasterModel> AccountHeads { get; set; }
        public DbSet<ReturnToVendorItemsModel> ReturnToVendorItems { get; set; }
        public DbSet<ReturnToVendorModel> ReturnToVendor { get; set; }
        public DbSet<FixedAssetStockModel> FixedAssetStock { get; set; }
        public DbSet<FixedAssetLocationsModel> FixedAssetLocations { get; set; }
        public DbSet<FixedAssetContainerModel> FixedAssetContainers { get; set; }
        public DbSet<FixedAssetInsuranceViewModel> FixedAssetInsuranceModels { get; set; }
        public DbSet<VerificationModel> Verifications { get; set; }
        public DbSet<VerificationItemsModel> VerificationItems { get; set; }
        public DbSet<DepartmentModel> Departments { get; set; }
        public DbSet<EmployeeModel> Employees { get; set; }
        public DbSet<InternalConsumptionModel> InternalConsumption { get; set; }
        public DbSet<InternalConsumptionItemsModel> InternalConsumptionItems { get; set; }
        public DbSet<BarcodeModel> Barcodes { get; set; }
        public DbSet<InventoryFiscalYear> FiscalYears { get; set; }
        public DbSet<InventoryStockModel> InventoryStock { get; set; }
        public DbSet<InventoryStockTransactionModel> InventoryStockTransactions { get; set; }
        public DbSet<InventoryTermsModel> Terms { get; set; }
        public DbSet<GoodsReceiptItemsDTOModel> GoodsReceiptItemsDTO { get; set; }
        public DbSet<InventoryCompanyModel> Companies { get; set; }
        public DbSet<LedgerModel> Ledgers { get; set; }
        public DbSet<InventoryChargesList> ChargesList { get; set; }
        public DbSet<InventoryInventoryVendors> InventoryVendors { get; set; }
        public DbSet<WARDSupplyAssetRequisitionModel> WARDSupplyAssetRequisition { get; set; }
        public DbSet<WARDSupplyAssetRequisitionItemsModel> WARDSupplyAssetRequisitionItems { get; set; }
        public DbSet<INVPatientConsumptionReceiptModel> PatientConsumptionReceipt { get; set; }
        public DbSet<INVPatientConsumptionReceiptItemsModel> PatientConsumptionReceiptItems { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<PurchaseOrderModel>().ToTable("INV_TXN_PurchaseOrder");
            modelBuilder.Entity<ItemMasterModel>().ToTable("INV_MST_Item");
            modelBuilder.Entity<VendorMasterModel>().ToTable("INV_MST_Vendor");
            modelBuilder.Entity<PurchaseOrderItemsModel>().ToTable("INV_TXN_PurchaseOrderItems");
            modelBuilder.Entity<GoodsReceiptModel>().ToTable("INV_TXN_GoodsReceipt");
            modelBuilder.Entity<GoodsReceiptItemsModel>().ToTable("INV_TXN_GoodsReceiptItems");

            modelBuilder.Entity<MAP_GoodsReceiptItems_OtherCharges>().ToTable("INV_MAP_GoodsReceiptItems_OtherCharges");
            modelBuilder.Entity<MAP_GoodsReceipt_OtherCharges>().ToTable("INV_MAP_GoodsReceipt_OtherCharges");

            modelBuilder.Entity<RequisitionModel>().ToTable("INV_TXN_Requisition");
            modelBuilder.Entity<RequisitionItemsModel>().ToTable("INV_TXN_RequisitionItems");
            modelBuilder.Entity<DispatchItemsModel>().ToTable("INV_TXN_DispatchItems");
            modelBuilder.Entity<DispatchModel>().ToTable("INV_TXN_Dispatch");

            modelBuilder.Entity<MAP_DispatchItems_FixedAssetStock>()
                .ToTable("INV_MAP_DispatchItems_FixedAssetStock")
                .HasKey(a => new { a.DispatchItemsId, a.FixedAssetStockId });

            modelBuilder.Entity<MAP_DispatchItems_FixedAssetStock>()
                .HasOne(d => d.Asset)
                .WithMany()
                .IsRequired();

            modelBuilder.Entity<WriteOffItemsModel>().ToTable("INV_TXN_WriteOffItems");
            modelBuilder.Entity<CurrencyMasterModel>().ToTable("INV_MST_Currency");
            modelBuilder.Entity<ItemCategoryMasterModel>().ToTable("INV_MST_ItemCategory");
            modelBuilder.Entity<UnitOfMeasurementMasterModel>().ToTable("INV_MST_UnitOfMeasurement");
            modelBuilder.Entity<PackagingTypeMasterModel>().ToTable("INV_MST_PackagingType");
            modelBuilder.Entity<AccountHeadMasterModel>().ToTable("INV_MST_AccountHead");
            modelBuilder.Entity<ReturnToVendorItemsModel>().ToTable("INV_TXN_ReturnToVendorItems");
            modelBuilder.Entity<ReturnToVendorModel>().ToTable("INV_TXN_ReturnToVendor");
            modelBuilder.Entity<FixedAssetStockModel>().ToTable("INV_FixedAssetStock");
            modelBuilder.Entity<FixedAssetLocationsModel>().ToTable("INV_MST_FixedAssetLocations");
            modelBuilder.Entity<FixedAssetContainerModel>().ToTable("INV_MST_FixedAssetContainers");
            modelBuilder.Entity<FixedAssetInsuranceViewModel>().ToTable("INV_MAP_Insurance_Vendor_FixedAsset");
            modelBuilder.Entity<DepartmentModel>().ToTable("MST_Department");
            modelBuilder.Entity<EmployeeModel>().ToTable("EMP_Employee");
            modelBuilder.Entity<VerificationModel>().ToTable("INV_TXN_Verification");
            modelBuilder.Entity<VerificationItemsModel>().ToTable("INV_TXN_VerificationItems");
            modelBuilder.Entity<InternalConsumptionModel>().ToTable("INV_TXN_InternalConsumption");
            modelBuilder.Entity<InternalConsumptionItemsModel>().ToTable("INV_TXN_InternalConsumptionItems");
            modelBuilder.Entity<BarcodeModel>().ToTable("INV_MST_Barcode");
            modelBuilder.Entity<InventoryFiscalYear>().ToTable("INV_CFG_FiscalYears");
            modelBuilder.Entity<InventoryStockModel>().ToTable("INV_TXN_Stock");
            modelBuilder.Entity<InventoryStockTransactionModel>().ToTable("INV_StockTransaction");
            modelBuilder.Entity<InventoryTermsModel>().ToTable("INV_CFG_Terms");
            modelBuilder.Entity<InventoryCompanyModel>().ToTable("INV_MST_Company");
            modelBuilder.Entity<LedgerModel>().ToTable("INV_MST_Ledger");
            modelBuilder.Entity<InventoryChargesList>().ToTable("INV_MST_ChargesList");
            modelBuilder.Entity<InventoryInventoryVendors>().ToTable("INV_MAP_InventoryVendors");
            modelBuilder.Entity<WARDSupplyAssetRequisitionModel>().ToTable("WRD_TXN_SupplyAssetRequisition");
            modelBuilder.Entity<WARDSupplyAssetRequisitionItemsModel>().ToTable("WRD_TXN_SupplyAssetRequisitionItems");
            modelBuilder.Entity<INVPatientConsumptionReceiptModel>().ToTable("INV_TXN_PatientConsumptionReceipt");
            modelBuilder.Entity<INVPatientConsumptionReceiptItemsModel>().ToTable("INV_TXN_PatientConsumptionReceiptItems");
        }

        // Replace stored procedure calls with ADO.NET or EF Core methods
        public DataTable GetInventoryStockDetail(int? ItemId, int? StoreId, DateTime? FromDate, DateTime? ToDate)
        {
            // Create the DataTable to return
            DataTable result = new DataTable();
            
            // Use ADO.NET directly for stored procedure with DataTable
            using (var connection = new SqlConnection(_connectionString))
            {
                connection.Open();
                
                using (var command = new SqlCommand("SP_INV_GetInventoryStockDetail", connection))
                {
                    command.CommandType = CommandType.StoredProcedure;
                    
                    // Add parameters
                    command.Parameters.Add(new SqlParameter("@ItemId", SqlDbType.Int) { Value = ItemId ?? (object)DBNull.Value });
                    command.Parameters.Add(new SqlParameter("@StoreId", SqlDbType.Int) { Value = StoreId ?? (object)DBNull.Value });
                    command.Parameters.Add(new SqlParameter("@FromDate", SqlDbType.DateTime) { Value = FromDate ?? (object)DBNull.Value });
                    command.Parameters.Add(new SqlParameter("@ToDate", SqlDbType.DateTime) { Value = ToDate ?? (object)DBNull.Value });
                    
                    // Execute the command and fill the DataTable
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
