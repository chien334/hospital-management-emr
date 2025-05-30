using DanpheEMR.ServerModel;
using DanpheEMR.ServerModel.BillingModels;
using DanpheEMR.ServerModel.MedicareModels;
using DanpheEMR.ServerModel.PatientModels;
using Microsoft.EntityFrameworkCore;

namespace DanpheEMR.DalLayer
{
    public class PatientDbContext : DbContext
    {
        public DbSet<PatientModel> Patients { get; set; }
        public DbSet<BillingSchemeModel> Schemes { get; set; }
        //public DbSet<PatientMembershipModel> PatientMemberships { get; set; }
        public DbSet<AppointmentModel> Appointments { get; set; }
        public DbSet<VisitModel> Visits { get; set; }
        public DbSet<PatientFilesModel> PatientFiles { get; set; }
        public DbSet<CountrySubDivisionModel> CountrySubdivisions { get; set; }//sud:14May'18
        public DbSet<CountryModel> Countries { get; set; }//sud:14May'18

        public DbSet<DepartmentModel> Department { get; set; }

        public DbSet<AdmissionModel> Admissions { get; set; }//sud:3June'18
        public DbSet<HealthCardInfoModel> PATHealthCard { get; set; }
        public DbSet<NeighbourhoodCardModel> PATNeighbourhoodCard { get; set; }
        public DbSet<EmployeeModel> Employee { get; set; }
        public DbSet<InsuranceProviderModel> InsuranceProviders { get; set; } //Yubraj:22nd Feb 2019
        public DbSet<InsuranceModel> Insurances { get; set; } //Yubraj:22nd Feb 2019
        public DbSet<ADTBedReservation> BedReservation { get; set; }
        public DbSet<CfgParameterModel> CFGParameters { get; set; }
        public DbSet<EmergencyPatientModel> EmergencyPatient { get; set; }

        public DbSet<PatientBedInfo> PatientBedInfos { get; set; }
        public DbSet<WardModel> Wards { get; set; }
        public DbSet<BedModel> Beds { get; set; }
        public DbSet<MunicipalityModel> Municipalities { get; set; }
        public DbSet<MedicareMember> MedicareMembers { get; set; }
        public DbSet<MedicareMemberBalance> MedicareMemberBalances { get; set; }
        public DbSet<PatientSchemeMapModel> PatientMapPriceCategories { get; set; }
        public PatientDbContext(DbContextOptions<PatientDbContext> options) : base(options)
        {
            this.Database.SetCommandTimeout(180);
        }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<PatientFilesModel>().ToTable("PAT_PatientFiles");

            // Patient mapping
            modelBuilder.Entity<PatientModel>().ToTable("PAT_Patient");
            // Patient address mapping
            modelBuilder.Entity<AddressModel>().ToTable("PAT_PatientAddress");
            modelBuilder.Entity<AddressModel>()
                .HasOne(s => s.Patient)
                .WithMany(s => s.Addresses)
                .HasForeignKey(s => s.PatientId);

            // Patient and insurance mapping
            modelBuilder.Entity<InsuranceModel>().ToTable("PAT_PatientInsuranceInfo");
            modelBuilder.Entity<InsuranceModel>()
                .HasOne(a => a.Patient)
                .WithMany(a => a.Insurances)
                .HasForeignKey(s => s.PatientId);

            modelBuilder.Entity<KinModel>().ToTable("PAT_PatientKinOrEmergencyContacts");
            modelBuilder.Entity<KinModel>()
                .HasOne(a => a.Patient)
                .WithMany(a => a.KinEmergencyContacts)
                .HasForeignKey(s => s.PatientId);

            // Patient and Gurantor 
            modelBuilder.Entity<GuarantorModel>().ToTable("PAT_PatientGurantorInfo");
            modelBuilder.Entity<GuarantorModel>()
                .HasKey(t => t.PatientId);
            modelBuilder.Entity<PatientModel>()
                .HasOne(a => a.Guarantor)
                .WithOne()
                .HasForeignKey<GuarantorModel>(g => g.PatientId)
                .IsRequired(false);

            //Patient with Visit
            modelBuilder.Entity<VisitModel>().ToTable("PAT_PatientVisits");
            modelBuilder.Entity<AdmissionModel>().ToTable("ADT_PatientAdmission");
            // Patient and visit mappings
            modelBuilder.Entity<VisitModel>()
                .HasOne(a => a.Patient)
                .WithMany(a => a.Visits)
                .HasForeignKey(s => s.PatientId);

            // Patient and Allergy mapping
            modelBuilder.Entity<AllergyModel>().ToTable("CLN_Allergies");
            modelBuilder.Entity<AllergyModel>()
                .HasOne(a => a.Patient)
                .WithMany(a => a.Allergies)
                .HasForeignKey(s => s.PatientId);

            // Patient and problem list mappings
            modelBuilder.Entity<ActiveMedicalProblem>().ToTable("CLN_ActiveMedicals");
            modelBuilder.Entity<ActiveMedicalProblem>()
                .HasOne(a => a.Patient)
                .WithMany(a => a.Problems)
                .HasForeignKey(s => s.PatientId);

            // Patient and pastMedical list mappings
            modelBuilder.Entity<PastMedicalProblem>().ToTable("CLN_PastMedicals");
            modelBuilder.Entity<PastMedicalProblem>()
                .HasOne(a => a.Patient)
                .WithMany(a => a.PastMedicals)
                .HasForeignKey(s => s.PatientId);

            modelBuilder.Entity<ImagingReportModel>().ToTable("RAD_PatientImagingReport");
            modelBuilder.Entity<ImagingReportModel>()
                .HasOne(a => a.Patient)
                .WithMany(a => a.ImagingReports)
                .HasForeignKey(s => s.PatientId);

            modelBuilder.Entity<ImagingRequisitionModel>().ToTable("RAD_PatientImagingRequisition");
            modelBuilder.Entity<ImagingRequisitionModel>()
                .HasOne(a => a.Patient)
                .WithMany(a => a.ImagingItemRequisitions)
                .HasForeignKey(s => s.PatientId);
            //LAB Results
            modelBuilder.Entity<LabRequisitionModel>().ToTable("LAB_TestRequisition");

            // Patient and vitals mapping
            modelBuilder.Entity<VitalsModel>().ToTable("CLN_PatientVitals");
            modelBuilder.Entity<VitalsModel>()
                .HasOne(a => a.Visit)
                .WithMany(a => a.Vitals)
                .HasForeignKey(s => s.PatientVisitId);

            modelBuilder.Entity<NotesModel>().ToTable("CLN_Notes");

            modelBuilder.Entity<MedicationPrescriptionModel>().ToTable("CLN_MedicationPrescription");
            modelBuilder.Entity<MedicationPrescriptionModel>()
                .HasOne(a => a.Patient)
                .WithMany(a => a.MedicationPrescriptions)
                .HasForeignKey(s => s.PatientId);

            modelBuilder.Entity<HomeMedicationModel>().ToTable("CLN_HomeMedications");
            modelBuilder.Entity<HomeMedicationModel>()
                .HasOne(a => a.Patient)
                .WithMany(a => a.HomeMedication)
                .HasForeignKey(s => s.PatientId);

            modelBuilder.Entity<SocialHistory>().ToTable("CLN_SocialHistory");
            modelBuilder.Entity<SocialHistory>()
                .HasOne(a => a.Patient)
                .WithMany(a => a.SocialHistory)
                .HasForeignKey(s => s.PatientId);

            modelBuilder.Entity<BillingSchemeModel>().ToTable("BIL_CFG_Scheme");
            modelBuilder.Entity<AppointmentModel>().ToTable("PAT_Appointment");
            modelBuilder.Entity<CountrySubDivisionModel>().ToTable("MST_CountrySubDivision");
            modelBuilder.Entity<CountryModel>().ToTable("MST_Country");
            modelBuilder.Entity<HealthCardInfoModel>().ToTable("PAT_HealthCardInfo");
            modelBuilder.Entity<InsuranceProviderModel>().ToTable("INS_CFG_InsuranceProviders");
            modelBuilder.Entity<EmployeeModel>().ToTable("EMP_Employee");
            modelBuilder.Entity<DepartmentModel>().ToTable("MST_Department");
            modelBuilder.Entity<NeighbourhoodCardModel>().ToTable("PAT_NeighbourhoodCardDetail");
            modelBuilder.Entity<ADTBedReservation>().ToTable("ADT_BedReservation");
            modelBuilder.Entity<CfgParameterModel>().ToTable("CORE_CFG_Parameters");
            modelBuilder.Entity<EmergencyPatientModel>().ToTable("ER_Patient");
            modelBuilder.Entity<PatientBedInfo>().ToTable("ADT_TXN_PatientBedInfo");
            modelBuilder.Entity<WardModel>().ToTable("ADT_MST_Ward");
            modelBuilder.Entity<BedModel>().ToTable("ADT_Bed");
            modelBuilder.Entity<MunicipalityModel>().ToTable("MST_Municipality");
            modelBuilder.Entity<MedicareMember>().ToTable("INS_MedicareMember");
            modelBuilder.Entity<MedicareMemberBalance>().ToTable("INS_MedicareMemberBalance");
            modelBuilder.Entity<PatientSchemeMapModel>().ToTable("PAT_MAP_PatientSchemes");
        }
    }
}