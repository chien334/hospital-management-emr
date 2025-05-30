using System;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using Microsoft.EntityFrameworkCore;
using DanpheEMR.ServerModel;
using DanpheEMR.ServerModel.AdmissionModels;
using DanpheEMR.ServerModel.AdmissionModels.Config;
using DanpheEMR.ServerModel.BillingModels;
using DanpheEMR.ServerModel.BillingModels.DischargeStatementModels;
using DanpheEMR.ServerModel.MasterModels;
using DanpheEMR.ServerModel.PatientModels;
using DanpheEMR.ServerModel.Utilities;

namespace DanpheEMR.DalLayer
{
    // Lưu ý: Đây là phiên bản EF Core của AdmissionDbContext
    public class AdmissionDbContextCore : DbContext
    {
        // Bỏ constructor tĩnh vì không cần thiết trong EF Core
        
        public DbSet<AdmissionModel> Admissions { get; set; }
        public DbSet<MunicipalityModel> Municipalities { get; set; }
        public DbSet<CountrySubDivisionModel> CountrySubDivisions { get; set; }
        public DbSet<EmployeeModel> Employees { get; set; }
        public DbSet<EmployeePreferences> EmployeePreferences { get; set; }
        public DbSet<PatientBedInfo> PatientBedInfos { get; set; }
        public DbSet<WardModel> Wards { get; set; }
        public DbSet<BedModel> Beds { get; set; }
        public DbSet<BedFeature> BedFeatures { get; set; }
        public DbSet<BillServiceItemModel> BillServiceItems { get; set; }
        public DbSet<ServiceDepartmentModel> ServiceDepartment { get; set; }
        public DbSet<SmsModel> SmsService { get; set; }
        public DbSet<BillingFiscalYear> BillingFiscalYears { get; set; }
        public DbSet<DepartmentModel> Department { get; set; }
        public DbSet<BedFeaturesMap> BedFeaturesMaps { get; set; }
        public DbSet<VisitModel> Visits { get; set; }
        public DbSet<PatientModel> Patients { get; set; }
        public DbSet<DischargeSummaryModel> DischargeSummary { get; set; }
        public DbSet<DischargeTypeModel> DischargeType { get; set; }
        public DbSet<AddressModel> Address { get; set; }
        public DbSet<BillingDepositModel> BillDeposit { get; set; }
        public DbSet<BillingTransactionItemModel> BillTxnItem { get; set; }
        public DbSet<BillingTransactionModel> BillingTransactions { get; set; }
        public DbSet<LabRequisitionModel> LabRequisitions { get; set; }
        public DbSet<ImagingRequisitionModel> ImagingRequisitions { get; set; }
        public DbSet<CountryModel> Countries { get; set; }
        public DbSet<HemodialysisModel> HemodialysisReport { get; set; }
        public DbSet<DischargeCancelModel> DischargeCancel { get; set; }
        public DbSet<BillInvoiceReturnModel> BillReturns { get; set; }
        public DbSet<DischargeSummaryMedication> DischargeSummaryMedications { get; set; }
        public DbSet<MedicationFrequency> MedicationFrequencies { get; set; }
        public DbSet<DischargeConditionTypeModel> DischargeConditionTypes { get; set; }
        public DbSet<DeliveryTypeModel> DeliveryTypes { get; set; }
        public DbSet<BabyBirthConditionModel> BabyBirthConditions { get; set; }
        public DbSet<BabyBirthDetailsModel> BabyBirthDetails { get; set; }
        public DbSet<DeathTypeModel> DeathTypes { get; set; }
        public DbSet<PatientCertificateModel> PatientCertificate { get; set; }
        public DbSet<MedicalRecordModel> MedicalRecords { get; set; }
        public DbSet<ADTBedReservation> BedReservation { get; set; }
        public DbSet<EmergencyPatientModel> EmergencyPatient { get; set; }
        public DbSet<CfgParameterModel> CFGParameters { get; set; }
        public DbSet<NotesModel> Notes { get; set; }
        public DbSet<EmpCashTransactionModel> EmpCashTransactions { get; set; }
        public DbSet<ADTDischargeSummaryConsultantModel> DischargeSummaryConsultant { get; set; }
        public DbSet<PriceCategoryModel> PriceCategoryModels { get; set; }
        public DbSet<PatientSchemeMapModel> PatientSchemeMaps { get; set; }
        public DbSet<BillingSchemeModel> Schemes { get; set; }
        public DbSet<BillMapPriceCategoryServiceItemModel> BillPriceCategoryServiceItems { get; set; }
        public DbSet<DepositHeadModel> DepositHeadModels { get; set; }
        public DbSet<CreditOrganizationModel> CreditOrganizations { get; set; }
        public DbSet<AdtAutoBillingItemModel> AdtAutoBillingItems { get; set; }
        public DbSet<AdtDepositSettingsModel> AdtDepositSettings { get; set; }
        public DbSet<BillServiceItemSchemeSettingModel> ServiceItemSchemeSettings { get; set; }
        public DbSet<AdtBedFeatureSchemePriceCategoryMapModel> BedFeatureSchemePriceCategoryMaps { get; set; }
        public DbSet<VisitSchemeChangeHistoryModel> VisitSchemeChangeHistory { get; set; }
        public DbSet<BillInvoiceReturnItemsModel> BillInvoiceReturnItems { get; set; }
        public DbSet<DischargeStatementModel> DischargeStatements { get; set; }
        public DbSet<PaymentModes> PaymentModes { get; set; }
        public DbSet<GuarantorModel> Guarantor { get; set; }

        private readonly string _connectionString;

        public AdmissionDbContextCore(string connectionString)
        {
            _connectionString = connectionString;
        }

        // Phương thức này sẽ được gọi khi DbContext được khởi tạo
        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
            if (!optionsBuilder.IsConfigured)
            {
                optionsBuilder.UseSqlServer(_connectionString);
            }
        }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            // Cấu hình model cho EF Core
            modelBuilder.Entity<AdmissionModel>().ToTable("ADT_PatientAdmission");
            modelBuilder.Entity<CountrySubDivisionModel>().ToTable("MST_CountrySubDivision");
            modelBuilder.Entity<MunicipalityModel>().ToTable("MST_Municipality");
            modelBuilder.Entity<DischargeSummaryModel>().ToTable("ADT_DischargeSummary");
            modelBuilder.Entity<PatientBedInfo>().ToTable("ADT_TXN_PatientBedInfo");
            modelBuilder.Entity<VisitModel>().ToTable("PAT_PatientVisits");
            
            // Thiết lập mối quan hệ với EF Core
            modelBuilder.Entity<PatientBedInfo>()
                    .HasOne(a => a.Admission)
                    .WithMany(a => a.PatientBedInfos)
                    .HasForeignKey(s => s.PatientVisitId)
                    .IsRequired();
                    
            modelBuilder.Entity<BedFeature>().ToTable("ADT_MST_BedFeature");
            modelBuilder.Entity<BedFeaturesMap>().ToTable("ADT_MAP_BedFeaturesMap");
            modelBuilder.Entity<WardModel>().ToTable("ADT_MST_Ward");

            // Fix for foreign key constraint cycles
            modelBuilder.Entity<BedFeaturesMap>()
                   .HasOne(a => a.Ward)
                   .WithMany()
                   .HasForeignKey(s => s.WardId)
                   .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<BedFeaturesMap>()
                   .HasOne(a => a.BedFeature)
                   .WithMany()
                   .HasForeignKey(s => s.BedFeatureId)
                   .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<BedFeaturesMap>()
                   .HasOne(a => a.Bed)
                   .WithMany()
                   .HasForeignKey(s => s.BedId)
                   .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<BedModel>().ToTable("ADT_Bed");
            modelBuilder.Entity<DepartmentModel>().ToTable("MST_Department");

            modelBuilder.Entity<DischargeTypeModel>().ToTable("ADT_DischargeType");

            modelBuilder.Entity<EmployeeModel>().ToTable("EMP_Employee");
            modelBuilder.Entity<EmployeePreferences>().ToTable("EMP_EmployeePreferences");
            modelBuilder.Entity<VisitModel>().ToTable("PAT_PatientVisits");
            modelBuilder.Entity<PatientModel>().ToTable("PAT_Patient");
            modelBuilder.Entity<AddressModel>().ToTable("PAT_PatientAddress");
            modelBuilder.Entity<BillingDepositModel>().ToTable("BIL_TXN_Deposit");
            modelBuilder.Entity<BillingTransactionItemModel>().ToTable("BIL_TXN_BillingTransactionItems");
            modelBuilder.Entity<BillingTransactionModel>().ToTable("BIL_TXN_BillingTransaction");
            modelBuilder.Entity<BillServiceItemModel>().ToTable("BIL_MST_ServiceItem");
            modelBuilder.Entity<ServiceDepartmentModel>().ToTable("BIL_MST_ServiceDepartment");

            modelBuilder.Entity<LabRequisitionModel>().ToTable("LAB_TestRequisition");
            modelBuilder.Entity<ImagingRequisitionModel>().ToTable("RAD_PatientImagingRequisition");
            modelBuilder.Entity<SmsModel>().ToTable("TXN_Sms");

            modelBuilder.Entity<HemodialysisModel>().ToTable("NEPH_HemodialysisRecord");
            modelBuilder.Entity<DischargeCancelModel>().ToTable("ADT_DischargeCancel");

            modelBuilder.Entity<BillingFiscalYear>().ToTable("BIL_CFG_FiscalYears");
            modelBuilder.Entity<BillInvoiceReturnModel>().ToTable("BIL_TXN_InvoiceReturn");

            modelBuilder.Entity<DischargeSummaryMedication>().ToTable("ADT_DischargeSummaryMedication");
            modelBuilder.Entity<MedicationFrequency>().ToTable("CLN_MST_Frequency");
            modelBuilder.Entity<DischargeConditionTypeModel>().ToTable("ADT_MST_DischargeConditionType");
            modelBuilder.Entity<DeliveryTypeModel>().ToTable("ADT_MST_DeliveryType");
            modelBuilder.Entity<BabyBirthConditionModel>().ToTable("ADT_MST_BabyBirthCondition");
            modelBuilder.Entity<BabyBirthDetailsModel>().ToTable("ADT_BabyBirthDetails");
            modelBuilder.Entity<DeathTypeModel>().ToTable("ADT_MST_DeathType");
            modelBuilder.Entity<PatientCertificateModel>().ToTable("ADT_PatientCertificate");
            modelBuilder.Entity<MedicalRecordModel>().ToTable("MR_RecordSummary");
            modelBuilder.Entity<ADTBedReservation>().ToTable("ADT_BedReservation");
            modelBuilder.Entity<EmergencyPatientModel>().ToTable("ER_Patient");
            modelBuilder.Entity<CfgParameterModel>().ToTable("CORE_CFG_Parameters");
            modelBuilder.Entity<NotesModel>().ToTable("CLN_Notes");
            modelBuilder.Entity<EmpCashTransactionModel>().ToTable("TXN_EmpCashTransaction");
            modelBuilder.Entity<ADTDischargeSummaryConsultantModel>().ToTable("ADT_DischargeSummaryConsultant");
            modelBuilder.Entity<PriceCategoryModel>().ToTable("BIL_CFG_PriceCategory");
            modelBuilder.Entity<PatientSchemeMapModel>().ToTable("PAT_MAP_PatientSchemes");
            modelBuilder.Entity<BillingSchemeModel>().ToTable("BIL_CFG_Scheme");
            modelBuilder.Entity<CountryModel>().ToTable("MST_Country");
            modelBuilder.Entity<BillMapPriceCategoryServiceItemModel>().ToTable("BIL_MAP_PriceCategoryServiceItem");
            modelBuilder.Entity<DepositHeadModel>().ToTable("BIL_MST_DepositHead");
            modelBuilder.Entity<CreditOrganizationModel>().ToTable("BIL_MST_Credit_Organization");
            modelBuilder.Entity<AdtAutoBillingItemModel>().ToTable("ADT_CFG_AutoBillingItem");
            modelBuilder.Entity<AdtDepositSettingsModel>().ToTable("ADT_CFG_DepositSettings");
            modelBuilder.Entity<BillServiceItemSchemeSettingModel>().ToTable("BIL_MAP_ServiceItemSchemeSetting");
            modelBuilder.Entity<AdtBedFeatureSchemePriceCategoryMapModel>().ToTable("ADT_MAP_BedFeatureSchemePriceCategory");
            modelBuilder.Entity<VisitSchemeChangeHistoryModel>().ToTable("VIS_LOG_VisitSchemeChangeHistory");
            modelBuilder.Entity<GuarantorModel>().ToTable("PAT_PatientGurantorInfo");
            modelBuilder.Entity<BillInvoiceReturnItemsModel>().ToTable("BIL_TXN_InvoiceReturnItems");
            modelBuilder.Entity<DischargeStatementModel>().ToTable("BIL_TXN_DischargeStatement");
            modelBuilder.Entity<PaymentModes>().ToTable("MST_PaymentModes");
        }

        // Implement the stored procedure call method for EF Core
        public DataTable GetAllAdmittedPatients(string AdmissionStatus, int? PatientVisitId)
        {
            // Create the DataTable to return
            DataTable result = new DataTable();
            
            // Use ADO.NET directly for stored procedure with DataTable
            using (var connection = new SqlConnection(_connectionString))
            {
                connection.Open();
                
                using (var command = new SqlCommand("SP_ADT_GetAllAdmittedPatients", connection))
                {
                    command.CommandType = CommandType.StoredProcedure;
                    
                    // Add parameters
                    command.Parameters.Add(new SqlParameter("@AdmissionStatus", SqlDbType.VarChar) { Value = AdmissionStatus ?? (object)DBNull.Value });
                    command.Parameters.Add(new SqlParameter("@PatientVisitId", SqlDbType.Int) { Value = PatientVisitId ?? (object)DBNull.Value });
                    
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
