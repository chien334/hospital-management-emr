using Microsoft.EntityFrameworkCore;
using DanpheEMR.ServerModel;
using DanpheEMR.ServerModel.BillingModels;
using DanpheEMR.ServerModel.PatientModels;
using DanpheEMR.ServerModel.BillingModels.Config;
using DanpheEMR.ServerModel.BillingModels.DischargeStatementModels;
using DanpheEMR.ServerModel.AdmissionModels.Config;
using DanpheEMR.ServerModel.MedicareModels;
using System.Data;
using System.Data.SqlClient;

namespace DanpheEMR.DalLayer
{
    public class BillingDbContextCore : DbContext
    {
        private readonly string _connectionString;

        public BillingDbContextCore(string connectionString)
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

        public DbSet<BillingTransactionModel> BillingTransactions { get; set; }
        public DbSet<ServiceDepartmentModel> ServiceDepartment { get; set; }
        public DbSet<BillItemRequisition> BillItemRequisitions { get; set; }
        public DbSet<BillingTransactionItemModel> BillingTransactionItems { get; set; }
        public DbSet<BillingDepositModel> BillingDeposits { get; set; }
        public DbSet<BillingCounter> BillingCounter { get; set; }
        public DbSet<BillItemPriceHistory> BillItemPriceHistory { get; set; }
        public DbSet<BillingPackageModel> BillingPackages { get; set; }
        public DbSet<LabRequisitionModel> LabRequisitions { get; set; }
        public DbSet<ImagingRequisitionModel> RadiologyImagingRequisitions { get; set; }
        public DbSet<PatientModel> Patient { get; set; }
        public DbSet<EmployeeModel> Employee { get; set; }
        public DbSet<VisitModel> Visit { get; set; }
        public DbSet<BillingSchemeModel> BillingSchemes { get; set; }
        public DbSet<CountrySubDivisionModel> CountrySubdivisions { get; set; }
        public DbSet<BillingFiscalYear> BillingFiscalYears { get; set; }
        public DbSet<BillInvoiceReturnModel> BillInvoiceReturns { get; set; }
        public DbSet<BillSettlementModel> BillSettlements { get; set; }
        public DbSet<SyncBillingAccountingModel> SyncBillingAccounting { get; set; }
        public DbSet<AdmissionModel> Admissions { get; set; }
        public DbSet<PatientBedInfo> PatientBedInfos { get; set; }
        public DbSet<DepartmentModel> Departments { get; set; }
        public DbSet<IRDLogModel> IRDLog { get; set; }
        public DbSet<BillServiceItemModel> BillServiceItems { get; set; }
        public DbSet<LabVendorModel> LabVendors { get; set; }
        public DbSet<BillInvoiceReturnItemsModel> BillInvoiceReturnItems { get; set; }
        public DbSet<BillMapPriceCategoryServiceItemModel> BillMapPriceCategoryServiceItems { get; set; }
        public DbSet<PriceCategoryModel> PriceCategories { get; set; }
        public DbSet<BillItemPrice> BillItemPrices { get; set; }
        public DbSet<PackageServiceItemsModel> PackageServiceItems { get; set; }
        public DbSet<PatientMembershipModel> PatientMemberships { get; set; }
        public DbSet<MembershipTypeModel> MembershipTypes { get; set; }
        public DbSet<BillingHandoverModel> BillingHandovers { get; set; }
        public DbSet<BillingHandoverTransactionModel> BillingHandoverTransactions { get; set; }
        public DbSet<DepositHeadModel> DepositHeads { get; set; }
        public DbSet<BillMapPriceCategoryServiceItemCostModel> MapPriceCategoryServiceItemCosts { get; set; }
        public DbSet<BillCreditOrganizationModel> CreditOrganizations { get; set; }
        public DbSet<InsuranceModel> Insurances { get; set; }
        public DbSet<BillingPackageServiceItemModel> BillingPackageServiceItems { get; set; }
        public DbSet<SchemeServiceIcdDiseaseGroupMapModel> SchemeServiceIcdDiseaseGroupMap { get; set; }
        public DbSet<PatientBillingContextVM> PatientBillingContexts { get; set; }
        public DbSet<ICD10CodeModel> ICDCodes { get; set; }
        public DbSet<DischargeStatementModel> DischargeStatements { get; set; }
        public DbSet<PatientSchemeMapModel> PatientSchemeMaps { get; set; }
        public DbSet<BillServiceItemSchemeSettingModel> ServiceItemSchemeSettings { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<BillingTransactionModel>().ToTable("BIL_TXN_BillingTransaction");
            modelBuilder.Entity<ServiceDepartmentModel>().ToTable("BIL_MST_ServiceDepartment");
            modelBuilder.Entity<BillItemRequisition>().ToTable("BIL_TXN_BillItemRequisition");
            modelBuilder.Entity<BillingTransactionItemModel>().ToTable("BIL_TXN_BillingTransactionItems");
            modelBuilder.Entity<BillingDepositModel>().ToTable("BIL_TXN_Deposit");
            modelBuilder.Entity<BillingCounter>().ToTable("BIL_CFG_Counter");
            modelBuilder.Entity<BillItemPriceHistory>().ToTable("BIL_HIST_ServiceItemPrice");
            modelBuilder.Entity<BillingPackageModel>().ToTable("BIL_CFG_Packages");
            modelBuilder.Entity<LabRequisitionModel>().ToTable("LAB_TestRequisition");
            modelBuilder.Entity<ImagingRequisitionModel>().ToTable("RAD_PatientImagingRequisition");
            modelBuilder.Entity<PatientModel>().ToTable("PAT_Patient");
            modelBuilder.Entity<EmployeeModel>().ToTable("EMP_Employee");
            modelBuilder.Entity<VisitModel>().ToTable("PAT_PatientVisits");
            modelBuilder.Entity<BillingSchemeModel>().ToTable("BIL_CFG_Scheme");
            modelBuilder.Entity<CountrySubDivisionModel>().ToTable("MST_CountrySubDivision");
            modelBuilder.Entity<BillingFiscalYear>().ToTable("BIL_CFG_FiscalYears");
            modelBuilder.Entity<BillInvoiceReturnModel>().ToTable("BIL_TXN_InvoiceReturn");
            modelBuilder.Entity<BillSettlementModel>().ToTable("BIL_TXN_Settlement");
            modelBuilder.Entity<SyncBillingAccountingModel>().ToTable("SYN_BIL_ACC");
            modelBuilder.Entity<AdmissionModel>().ToTable("ADT_PatientAdmission");
            modelBuilder.Entity<PatientBedInfo>().ToTable("ADT_TXN_PatientBedInfo");
            modelBuilder.Entity<DepartmentModel>().ToTable("MST_Department");
            modelBuilder.Entity<IRDLogModel>().ToTable("IRD_LOG");
            modelBuilder.Entity<BillServiceItemModel>().ToTable("BIL_MST_ServiceItem");
            modelBuilder.Entity<LabVendorModel>().ToTable("Lab_MST_LabVendor");
            modelBuilder.Entity<BillInvoiceReturnItemsModel>().ToTable("BIL_TXN_InvoiceReturnItems");
            modelBuilder.Entity<BillMapPriceCategoryServiceItemModel>().ToTable("BIL_MAP_PriceCategoryServiceItem");
            modelBuilder.Entity<PriceCategoryModel>().ToTable("BIL_CFG_PriceCategory");
            modelBuilder.Entity<BillItemPrice>().ToTable("BIL_TXN_BillItemPrice");
            modelBuilder.Entity<PackageServiceItemsModel>().ToTable("BIL_MAP_PackageServiceItems");
            modelBuilder.Entity<PatientMembershipModel>().ToTable("PAT_MAP_PatientMembership");
            modelBuilder.Entity<MembershipTypeModel>().ToTable("MST_MembershipType");
            modelBuilder.Entity<BillingHandoverModel>().ToTable("BIL_TXN_Handover");
            modelBuilder.Entity<BillingHandoverTransactionModel>().ToTable("BIL_TXN_HandoverTransaction");
            modelBuilder.Entity<DepositHeadModel>().ToTable("BIL_MST_DepositHead");
            modelBuilder.Entity<BillMapPriceCategoryServiceItemCostModel>().ToTable("BIL_MAP_PriceCategoryServiceItemCost");
            modelBuilder.Entity<BillCreditOrganizationModel>().ToTable("BIL_MST_Credit_Organization");
            modelBuilder.Entity<InsuranceModel>().ToTable("INS_Insurance");
            modelBuilder.Entity<BillingPackageServiceItemModel>().ToTable("BIL_MAP_PackageServiceItems");
            modelBuilder.Entity<SchemeServiceIcdDiseaseGroupMapModel>().ToTable("BIL_MAP_SchemeServiceIcdDiseaseGroup");
            modelBuilder.Entity<PatientBillingContextVM>().ToTable("PAT_MAP_BillingContext");
            modelBuilder.Entity<ICD10CodeModel>().ToTable("MST_ICD10");
            modelBuilder.Entity<DischargeStatementModel>().ToTable("BIL_TXN_DischargeStatement");
            modelBuilder.Entity<PatientSchemeMapModel>().ToTable("PAT_MAP_PatientSchemes");
            modelBuilder.Entity<BillServiceItemSchemeSettingModel>().ToTable("BIL_MAP_ServiceItemSchemeSetting");

            // Configure relationships if needed
            modelBuilder.Entity<BillingTransactionItemModel>()
                .HasOne(b => b.BillingTransaction)
                .WithMany(b => b.BillingTransactionItems)
                .HasForeignKey(b => b.BillingTransactionId)
                .OnDelete(DeleteBehavior.NoAction);

            // Add any other relationship configurations needed
        }

        // Example of a stored procedure method
        public DataTable GetAllBillingItems(int? serviceItemId, int? serviceDeptId)
        {
            DataTable result = new DataTable();
            
            using (var connection = new SqlConnection(_connectionString))
            {
                connection.Open();
                
                using (var command = new SqlCommand("SP_BIL_GetAllBillingItems", connection))
                {
                    command.CommandType = CommandType.StoredProcedure;
                    
                    command.Parameters.Add(new SqlParameter("@ServiceItemId", SqlDbType.Int) { Value = serviceItemId ?? (object)DBNull.Value });
                    command.Parameters.Add(new SqlParameter("@ServiceDeptId", SqlDbType.Int) { Value = serviceDeptId ?? (object)DBNull.Value });
                    
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
