using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace DsfEMR.DalLayer.Migrations
{
    /// <inheritdoc />
    public partial class InitialPostgresSchema : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "ADT_MST_BedFeature",
                columns: table => new
                {
                    BedFeatureId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    BedFeatureCode = table.Column<string>(type: "text", nullable: false),
                    BedFeatureName = table.Column<string>(type: "text", nullable: false),
                    BedFeatureFullName = table.Column<string>(type: "text", nullable: false),
                    BedPrice = table.Column<double>(type: "double precision", nullable: true),
                    CreatedBy = table.Column<int>(type: "integer", nullable: false),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ADT_MST_BedFeature", x => x.BedFeatureId);
                });

            migrationBuilder.CreateTable(
                name: "ADT_MST_Ward",
                columns: table => new
                {
                    WardId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    StoreId = table.Column<int>(type: "integer", nullable: false),
                    WardCode = table.Column<string>(type: "text", nullable: false),
                    WardName = table.Column<string>(type: "text", nullable: false),
                    WardLocation = table.Column<string>(type: "text", nullable: false),
                    CreatedBy = table.Column<int>(type: "integer", nullable: false),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ADT_MST_Ward", x => x.WardId);
                });

            migrationBuilder.CreateTable(
                name: "BIL_CFG_PriceCategory",
                columns: table => new
                {
                    PriceCategoryId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    PriceCategoryName = table.Column<string>(type: "text", nullable: false),
                    Description = table.Column<string>(type: "text", nullable: false),
                    IsDefault = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    CreatedBy = table.Column<int>(type: "integer", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsPharmacyRateDifferent = table.Column<bool>(type: "boolean", nullable: true),
                    PriceCategoryCode = table.Column<string>(type: "text", nullable: false),
                    ShowInRegistration = table.Column<bool>(type: "boolean", nullable: false),
                    ShowInAdmission = table.Column<bool>(type: "boolean", nullable: false),
                    DisplaySequence = table.Column<int>(type: "integer", nullable: true),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_BIL_CFG_PriceCategory", x => x.PriceCategoryId);
                });

            migrationBuilder.CreateTable(
                name: "BIL_MAP_PriceCategoryServiceItem",
                columns: table => new
                {
                    PriceCategoryServiceItemMapId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    PriceCategoryId = table.Column<int>(type: "integer", nullable: false),
                    ServiceItemId = table.Column<int>(type: "integer", nullable: false),
                    ServiceDepartmentId = table.Column<int>(type: "integer", nullable: false),
                    IntegrationItemId = table.Column<int>(type: "integer", nullable: false),
                    Price = table.Column<decimal>(type: "numeric", nullable: false),
                    IsDiscountApplicable = table.Column<bool>(type: "boolean", nullable: false),
                    ItemLegalCode = table.Column<string>(type: "text", nullable: false),
                    ItemLegalName = table.Column<string>(type: "text", nullable: false),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    CreatedBy = table.Column<int>(type: "integer", nullable: false),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsPriceChangeAllowed = table.Column<bool>(type: "boolean", nullable: false),
                    IsZeroPriceAllowed = table.Column<bool>(type: "boolean", nullable: false),
                    HasAdditionalBillingItems = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_BIL_MAP_PriceCategoryServiceItem", x => x.PriceCategoryServiceItemMapId);
                });

            migrationBuilder.CreateTable(
                name: "BIL_MST_Credit_Organization",
                columns: table => new
                {
                    OrganizationId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    OrganizationName = table.Column<string>(type: "text", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    CreatedBy = table.Column<int>(type: "integer", nullable: false),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    IsDefault = table.Column<bool>(type: "boolean", nullable: false),
                    IsClaimManagementApplicable = table.Column<bool>(type: "boolean", nullable: false),
                    IsClaimCodeCompulsory = table.Column<bool>(type: "boolean", nullable: false),
                    IsClaimCodeAutoGenerate = table.Column<bool>(type: "boolean", nullable: false),
                    DisplayName = table.Column<string>(type: "text", nullable: false),
                    CreditOrganizationCode = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_BIL_MST_Credit_Organization", x => x.OrganizationId);
                });

            migrationBuilder.CreateTable(
                name: "CFG_PaymentModeSettings",
                columns: table => new
                {
                    PaymentModeSettingsId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    PaymentPageId = table.Column<int>(type: "integer", nullable: false),
                    PaymentModeSubCategoryName = table.Column<string>(type: "text", nullable: false),
                    PaymentModeSubCategoryId = table.Column<int>(type: "integer", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    DisplaySequence = table.Column<int>(type: "integer", nullable: true),
                    ShowPaymentDetails = table.Column<bool>(type: "boolean", nullable: false),
                    IsRemarksMandatory = table.Column<bool>(type: "boolean", nullable: false),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CFG_PaymentModeSettings", x => x.PaymentModeSettingsId);
                });

            migrationBuilder.CreateTable(
                name: "CFG_PrintExportSettings",
                columns: table => new
                {
                    PrintExportSettingsId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    SettingName = table.Column<string>(type: "text", nullable: false),
                    PageHeaderText = table.Column<string>(type: "text", nullable: false),
                    ReportDescription = table.Column<string>(type: "text", nullable: false),
                    ModuleName = table.Column<string>(type: "text", nullable: false),
                    ShowHeader = table.Column<bool>(type: "boolean", nullable: false),
                    ShowFooter = table.Column<bool>(type: "boolean", nullable: false),
                    ShowUserName = table.Column<bool>(type: "boolean", nullable: false),
                    ShowPrintExportDateTime = table.Column<bool>(type: "boolean", nullable: false),
                    ShowNpDate = table.Column<bool>(type: "boolean", nullable: false),
                    ShowEnDate = table.Column<bool>(type: "boolean", nullable: false),
                    ShowFilterDateRange = table.Column<bool>(type: "boolean", nullable: false),
                    ShowOtherFilterVariables = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedBy = table.Column<int>(type: "integer", nullable: true),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CFG_PrintExportSettings", x => x.PrintExportSettingsId);
                });

            migrationBuilder.CreateTable(
                name: "CORE_CFG_Parameters",
                columns: table => new
                {
                    ParameterId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    ParameterGroupName = table.Column<string>(type: "text", nullable: false),
                    ParameterName = table.Column<string>(type: "text", nullable: false),
                    ParameterValue = table.Column<string>(type: "text", nullable: false),
                    ValueDataType = table.Column<string>(type: "text", nullable: false),
                    Description = table.Column<string>(type: "text", nullable: false),
                    ParameterType = table.Column<string>(type: "text", nullable: false),
                    ValueLookUpList = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CORE_CFG_Parameters", x => x.ParameterId);
                });

            migrationBuilder.CreateTable(
                name: "CORE_LookupDetail",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Type = table.Column<int>(type: "integer", nullable: false),
                    Name = table.Column<string>(type: "text", nullable: false),
                    Description = table.Column<string>(type: "text", nullable: false),
                    DisplayName = table.Column<string>(type: "text", nullable: false),
                    DisplaySequence = table.Column<int>(type: "integer", nullable: true),
                    ParentId = table.Column<int>(type: "integer", nullable: true),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CORE_LookupDetail", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "EMP_EmployeePreferences",
                columns: table => new
                {
                    PreferenceId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    PreferenceName = table.Column<string>(type: "text", nullable: false),
                    PreferenceValue = table.Column<string>(type: "text", nullable: false),
                    EmployeeId = table.Column<int>(type: "integer", nullable: false),
                    CreatedBy = table.Column<int>(type: "integer", nullable: false),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_EMP_EmployeePreferences", x => x.PreferenceId);
                });

            migrationBuilder.CreateTable(
                name: "EMP_EmployeeRole",
                columns: table => new
                {
                    EmployeeRoleId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    EmployeeRoleName = table.Column<string>(type: "text", nullable: false),
                    Description = table.Column<string>(type: "text", nullable: false),
                    CreatedBy = table.Column<int>(type: "integer", nullable: false),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    IsActive = table.Column<bool>(type: "boolean", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_EMP_EmployeeRole", x => x.EmployeeRoleId);
                });

            migrationBuilder.CreateTable(
                name: "EMP_EmployeeType",
                columns: table => new
                {
                    EmployeeTypeId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    EmployeeTypeName = table.Column<string>(type: "text", nullable: false),
                    Description = table.Column<string>(type: "text", nullable: false),
                    CreatedBy = table.Column<int>(type: "integer", nullable: false),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    IsActive = table.Column<bool>(type: "boolean", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_EMP_EmployeeType", x => x.EmployeeTypeId);
                });

            migrationBuilder.CreateTable(
                name: "ICD_DiseaseGroup",
                columns: table => new
                {
                    DiseaseGroupId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    SerialNumber = table.Column<int>(type: "integer", nullable: false),
                    ReportingGroupId = table.Column<int>(type: "integer", nullable: false),
                    ICDCode = table.Column<string>(type: "text", nullable: false),
                    DiseaseGroupName = table.Column<string>(type: "text", nullable: false),
                    CreatedBy = table.Column<int>(type: "integer", nullable: false),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ICD_DiseaseGroup", x => x.DiseaseGroupId);
                });

            migrationBuilder.CreateTable(
                name: "ICD_ReportingGroup",
                columns: table => new
                {
                    ReportingGroupId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    SerialNumber = table.Column<int>(type: "integer", nullable: false),
                    GroupCode = table.Column<string>(type: "text", nullable: false),
                    ReportingGroupName = table.Column<string>(type: "text", nullable: false),
                    CreatedBy = table.Column<int>(type: "integer", nullable: false),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ICD_ReportingGroup", x => x.ReportingGroupId);
                });

            migrationBuilder.CreateTable(
                name: "LabReportTemplateModel",
                columns: table => new
                {
                    ReportTemplateID = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    ReportTemplateShortName = table.Column<string>(type: "text", nullable: false),
                    ReportTemplateName = table.Column<string>(type: "text", nullable: false),
                    TemplateFileName = table.Column<string>(type: "text", nullable: false),
                    NegativeTemplateFileName = table.Column<string>(type: "text", nullable: false),
                    IsDefault = table.Column<bool>(type: "boolean", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedBy = table.Column<int>(type: "integer", nullable: false),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    HeaderText = table.Column<string>(type: "text", nullable: false),
                    ColSettingsJSON = table.Column<string>(type: "text", nullable: false),
                    TemplateType = table.Column<string>(type: "text", nullable: false),
                    TemplateHTML = table.Column<string>(type: "text", nullable: false),
                    FooterText = table.Column<string>(type: "text", nullable: false),
                    Description = table.Column<string>(type: "text", nullable: false),
                    DisplaySequence = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LabReportTemplateModel", x => x.ReportTemplateID);
                });

            migrationBuilder.CreateTable(
                name: "MST_Bank",
                columns: table => new
                {
                    BankId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    BankShortName = table.Column<string>(type: "text", nullable: false),
                    BankName = table.Column<string>(type: "text", nullable: false),
                    Description = table.Column<string>(type: "text", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: true),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedBy = table.Column<int>(type: "integer", nullable: true),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MST_Bank", x => x.BankId);
                });

            migrationBuilder.CreateTable(
                name: "MST_Country",
                columns: table => new
                {
                    CountryId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    CountryShortName = table.Column<string>(type: "text", nullable: false),
                    CountryName = table.Column<string>(type: "text", nullable: false),
                    ISDCode = table.Column<string>(type: "text", nullable: false),
                    CountrySubDivisionType = table.Column<string>(type: "text", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedBy = table.Column<int>(type: "integer", nullable: true),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MST_Country", x => x.CountryId);
                });

            migrationBuilder.CreateTable(
                name: "MST_CountrySubDivision",
                columns: table => new
                {
                    CountrySubDivisionId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    CountryId = table.Column<int>(type: "integer", nullable: false),
                    CountrySubDivisionName = table.Column<string>(type: "text", nullable: false),
                    CountrySubDivisionCode = table.Column<string>(type: "text", nullable: false),
                    MapAreaCode = table.Column<string>(type: "text", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: true),
                    CreatedBy = table.Column<int>(type: "integer", nullable: true),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    IMU_CountrySubDivisonId = table.Column<int>(type: "integer", nullable: true),
                    IMU_ProvinceId = table.Column<int>(type: "integer", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MST_CountrySubDivision", x => x.CountrySubDivisionId);
                });

            migrationBuilder.CreateTable(
                name: "MST_Department",
                columns: table => new
                {
                    DepartmentId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    DepartmentCode = table.Column<string>(type: "text", nullable: false),
                    DepartmentName = table.Column<string>(type: "text", nullable: false),
                    Description = table.Column<string>(type: "text", nullable: false),
                    DepartmentHead = table.Column<int>(type: "integer", nullable: true),
                    NoticeText = table.Column<string>(type: "text", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsAppointmentApplicable = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedBy = table.Column<int>(type: "integer", nullable: true),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ParentDepartmentId = table.Column<int>(type: "integer", nullable: true),
                    RoomNumber = table.Column<string>(type: "text", nullable: false),
                    OpdNewPatientServiceItemId = table.Column<int>(type: "integer", nullable: true),
                    OpdOldPatientServiceItemId = table.Column<int>(type: "integer", nullable: true),
                    FollowupServiceItemId = table.Column<int>(type: "integer", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MST_Department", x => x.DepartmentId);
                });

            migrationBuilder.CreateTable(
                name: "MST_ICD10",
                columns: table => new
                {
                    ICD10ID = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    ICDShortCode = table.Column<string>(type: "text", nullable: false),
                    ICD10Code = table.Column<string>(type: "text", nullable: false),
                    ICD10Description = table.Column<string>(type: "text", nullable: false),
                    ValidForCoding = table.Column<bool>(type: "boolean", nullable: false),
                    Active = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MST_ICD10", x => x.ICD10ID);
                });

            migrationBuilder.CreateTable(
                name: "MST_MAP_StoreVerification",
                columns: table => new
                {
                    StoreVerificationMapId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    StoreId = table.Column<int>(type: "integer", nullable: false),
                    MaxVerificationLevel = table.Column<int>(type: "integer", nullable: false),
                    VerificationLevel = table.Column<int>(type: "integer", nullable: false),
                    PermissionId = table.Column<int>(type: "integer", nullable: false),
                    CreatedBy = table.Column<int>(type: "integer", nullable: false),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MST_MAP_StoreVerification", x => x.StoreVerificationMapId);
                });

            migrationBuilder.CreateTable(
                name: "MST_Municipality",
                columns: table => new
                {
                    MunicipalityId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    MunicipalityName = table.Column<string>(type: "text", nullable: false),
                    Type = table.Column<string>(type: "text", nullable: false),
                    CountryId = table.Column<int>(type: "integer", nullable: false),
                    CountrySubDivisionId = table.Column<int>(type: "integer", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedBy = table.Column<int>(type: "integer", nullable: true),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    IMU_CountrySubDivisionId = table.Column<int>(type: "integer", nullable: true),
                    IMU_MuncipalityId = table.Column<int>(type: "integer", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MST_Municipality", x => x.MunicipalityId);
                });

            migrationBuilder.CreateTable(
                name: "MST_PaymentModes",
                columns: table => new
                {
                    PaymentSubCategoryId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    PaymentSubCategoryName = table.Column<string>(type: "text", nullable: false),
                    PaymentMode = table.Column<string>(type: "text", nullable: false),
                    ShowInMultiplePaymentMode = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MST_PaymentModes", x => x.PaymentSubCategoryId);
                });

            migrationBuilder.CreateTable(
                name: "MST_PaymentPages",
                columns: table => new
                {
                    PaymentPageId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    ModuleName = table.Column<string>(type: "text", nullable: false),
                    PageName = table.Column<string>(type: "text", nullable: false),
                    Description = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MST_PaymentPages", x => x.PaymentPageId);
                });

            migrationBuilder.CreateTable(
                name: "MST_Reactions",
                columns: table => new
                {
                    ReactionId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    ReactionCode = table.Column<string>(type: "text", nullable: false),
                    ReactionName = table.Column<string>(type: "text", nullable: false),
                    CreatedBy = table.Column<int>(type: "integer", nullable: true),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MST_Reactions", x => x.ReactionId);
                });

            migrationBuilder.CreateTable(
                name: "MST_Tax",
                columns: table => new
                {
                    TaxId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    TaxName = table.Column<string>(type: "text", nullable: false),
                    TaxPercentage = table.Column<double>(type: "double precision", nullable: false),
                    TaxLabel = table.Column<string>(type: "text", nullable: false),
                    Description = table.Column<string>(type: "text", nullable: false),
                    CreatedBy = table.Column<int>(type: "integer", nullable: false),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MST_Tax", x => x.TaxId);
                });

            migrationBuilder.CreateTable(
                name: "MSTEmailSendDetail",
                columns: table => new
                {
                    SendId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    SendBy = table.Column<int>(type: "integer", nullable: false),
                    SendToEmail = table.Column<string>(type: "text", nullable: false),
                    EmailSubject = table.Column<string>(type: "text", nullable: false),
                    SendOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MSTEmailSendDetail", x => x.SendId);
                });

            migrationBuilder.CreateTable(
                name: "NUR_MAP_WardSubStoresMap",
                columns: table => new
                {
                    WardSubStoresMapId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    WardId = table.Column<int>(type: "integer", nullable: false),
                    StoreId = table.Column<int>(type: "integer", nullable: false),
                    IsDefault = table.Column<bool>(type: "boolean", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedBy = table.Column<int>(type: "integer", nullable: false),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_NUR_MAP_WardSubStoresMap", x => x.WardSubStoresMapId);
                });

            migrationBuilder.CreateTable(
                name: "PHRM_MST_Credit_Organization",
                columns: table => new
                {
                    OrganizationId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    OrganizationName = table.Column<string>(type: "text", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: true),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    CreatedBy = table.Column<int>(type: "integer", nullable: false),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    IsDefault = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PHRM_MST_Credit_Organization", x => x.OrganizationId);
                });

            migrationBuilder.CreateTable(
                name: "PHRM_MST_Item",
                columns: table => new
                {
                    ItemId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    ItemName = table.Column<string>(type: "text", nullable: false),
                    ItemCode = table.Column<string>(type: "text", nullable: false),
                    CompanyId = table.Column<int>(type: "integer", nullable: false),
                    ItemTypeId = table.Column<int>(type: "integer", nullable: false),
                    UOMId = table.Column<int>(type: "integer", nullable: false),
                    ReOrderQuantity = table.Column<double>(type: "double precision", nullable: false),
                    MinStockQuantity = table.Column<double>(type: "double precision", nullable: false),
                    BudgetedQuantity = table.Column<double>(type: "double precision", nullable: false),
                    PurchaseVATPercentage = table.Column<double>(type: "double precision", nullable: false),
                    SalesVATPercentage = table.Column<double>(type: "double precision", nullable: false),
                    IsVATApplicable = table.Column<bool>(type: "boolean", nullable: false),
                    PackingTypeId = table.Column<int>(type: "integer", nullable: true),
                    IsInternationalBrand = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedBy = table.Column<int>(type: "integer", nullable: false),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    Dosage = table.Column<string>(type: "text", nullable: false),
                    Frequency = table.Column<string>(type: "text", nullable: false),
                    Duration = table.Column<string>(type: "text", nullable: false),
                    GenericId = table.Column<int>(type: "integer", nullable: false),
                    ABCCategory = table.Column<string>(type: "text", nullable: false),
                    Rack = table.Column<int>(type: "integer", nullable: true),
                    StoreRackId = table.Column<int>(type: "integer", nullable: true),
                    SalesCategoryId = table.Column<int>(type: "integer", nullable: true),
                    VED = table.Column<string>(type: "text", nullable: false),
                    CCCharge = table.Column<double>(type: "double precision", nullable: false),
                    IsNarcotic = table.Column<bool>(type: "boolean", nullable: false),
                    IsInsuranceApplicable = table.Column<bool>(type: "boolean", nullable: false),
                    GovtInsurancePrice = table.Column<decimal>(type: "numeric", nullable: false),
                    PurchaseRate = table.Column<decimal>(type: "numeric", nullable: false),
                    SalesRate = table.Column<decimal>(type: "numeric", nullable: false),
                    PurchaseDiscount = table.Column<decimal>(type: "numeric", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PHRM_MST_Item", x => x.ItemId);
                });

            migrationBuilder.CreateTable(
                name: "PHRM_MST_Store",
                columns: table => new
                {
                    StoreId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Category = table.Column<string>(type: "text", nullable: false),
                    SubCategory = table.Column<string>(type: "text", nullable: false),
                    ParentStoreId = table.Column<int>(type: "integer", nullable: true),
                    Name = table.Column<string>(type: "text", nullable: false),
                    StoreDescription = table.Column<string>(type: "text", nullable: false),
                    PermissionId = table.Column<int>(type: "integer", nullable: false),
                    MaxVerificationLevel = table.Column<int>(type: "integer", nullable: false),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    CreatedBy = table.Column<int>(type: "integer", nullable: false),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    StoreLabel = table.Column<string>(type: "text", nullable: false),
                    PanNo = table.Column<string>(type: "text", nullable: false),
                    Code = table.Column<string>(type: "text", nullable: false),
                    Address = table.Column<string>(type: "text", nullable: false),
                    ContactNo = table.Column<string>(type: "text", nullable: false),
                    Email = table.Column<string>(type: "text", nullable: false),
                    UseSeparateInvoiceHeader = table.Column<bool>(type: "boolean", nullable: false),
                    PrintInvoiceHeaderInDotMatrix = table.Column<bool>(type: "boolean", nullable: false),
                    AvailablePaymentModesJSON = table.Column<string>(type: "text", nullable: false),
                    DefaultPaymentMode = table.Column<string>(type: "text", nullable: false),
                    INV_GRGroupId = table.Column<int>(type: "integer", nullable: true),
                    INV_POGroupId = table.Column<int>(type: "integer", nullable: true),
                    INV_PRGroupId = table.Column<int>(type: "integer", nullable: true),
                    INV_ReqDisGroupId = table.Column<int>(type: "integer", nullable: true),
                    INV_RFQGroupId = table.Column<int>(type: "integer", nullable: true),
                    INV_ReceiptDisplayName = table.Column<string>(type: "text", nullable: false),
                    INV_ReceiptNoCode = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PHRM_MST_Store", x => x.StoreId);
                });

            migrationBuilder.CreateTable(
                name: "PHRMGenericModel",
                columns: table => new
                {
                    GenericId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    GenericName = table.Column<string>(type: "text", nullable: false),
                    CategoryId = table.Column<int>(type: "integer", nullable: true),
                    GeneralCategory = table.Column<string>(type: "text", nullable: false),
                    TherapeuticCategory = table.Column<string>(type: "text", nullable: false),
                    Counseling = table.Column<string>(type: "text", nullable: false),
                    CreatedBy = table.Column<int>(type: "integer", nullable: false),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsAllergen = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PHRMGenericModel", x => x.GenericId);
                });

            migrationBuilder.CreateTable(
                name: "RAD_MST_ImagingType",
                columns: table => new
                {
                    ImagingTypeId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    ImagingTypeName = table.Column<string>(type: "text", nullable: false),
                    ProcedureCoding = table.Column<string>(type: "text", nullable: false),
                    CreatedBy = table.Column<int>(type: "integer", nullable: true),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    IsActive = table.Column<bool>(type: "boolean", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RAD_MST_ImagingType", x => x.ImagingTypeId);
                });

            migrationBuilder.CreateTable(
                name: "ServiceDepartment_MST_IntegrationName",
                columns: table => new
                {
                    IntegrationName = table.Column<string>(type: "text", nullable: false),
                    IntegrationNameID = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ServiceDepartment_MST_IntegrationName", x => x.IntegrationName);
                });

            migrationBuilder.CreateTable(
                name: "ADT_MAP_WardBedType",
                columns: table => new
                {
                    BedId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    BedCode = table.Column<string>(type: "text", nullable: false),
                    BedNumber = table.Column<string>(type: "text", nullable: false),
                    WardId = table.Column<int>(type: "integer", nullable: false),
                    IsOccupied = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedBy = table.Column<int>(type: "integer", nullable: false),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    HoldedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsReserved = table.Column<bool>(type: "boolean", nullable: false),
                    OnHold = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ADT_MAP_WardBedType", x => x.BedId);
                    table.ForeignKey(
                        name: "FK_ADT_MAP_WardBedType_ADT_MST_Ward_WardId",
                        column: x => x.WardId,
                        principalTable: "ADT_MST_Ward",
                        principalColumn: "WardId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "LabTestModel",
                columns: table => new
                {
                    LabTestId = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    LabTestCode = table.Column<string>(type: "text", nullable: false),
                    LabSequence = table.Column<int>(type: "integer", nullable: false),
                    ProcedureCode = table.Column<string>(type: "text", nullable: false),
                    LabTestName = table.Column<string>(type: "text", nullable: false),
                    LabTestSynonym = table.Column<string>(type: "text", nullable: false),
                    LabTestSpecimen = table.Column<string>(type: "text", nullable: false),
                    LabTestSpecimenSource = table.Column<string>(type: "text", nullable: false),
                    LOINC = table.Column<string>(type: "text", nullable: false),
                    ReportTemplateId = table.Column<int>(type: "integer", nullable: false),
                    IsValidForReporting = table.Column<bool>(type: "boolean", nullable: false),
                    Description = table.Column<string>(type: "text", nullable: false),
                    DisplaySequence = table.Column<int>(type: "integer", nullable: true),
                    RunNumberType = table.Column<string>(type: "text", nullable: false),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    CreatedBy = table.Column<int>(type: "integer", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    HasNegativeResults = table.Column<bool>(type: "boolean", nullable: false),
                    NegativeResultText = table.Column<string>(type: "text", nullable: false),
                    LabTestCategoryId = table.Column<int>(type: "integer", nullable: false),
                    SmsApplicable = table.Column<bool>(type: "boolean", nullable: false),
                    LabReportTemplateReportTemplateID = table.Column<int>(type: "integer", nullable: false),
                    ReportingName = table.Column<string>(type: "text", nullable: false),
                    Interpretation = table.Column<string>(type: "text", nullable: false),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    IsOutsourceTest = table.Column<bool>(type: "boolean", nullable: true),
                    DefaultOutsourceVendorId = table.Column<int>(type: "integer", nullable: true),
                    IsLISApplicable = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LabTestModel", x => x.LabTestId);
                    table.ForeignKey(
                        name: "FK_LabTestModel_LabReportTemplateModel_LabReportTemplateReport~",
                        column: x => x.LabReportTemplateReportTemplateID,
                        principalTable: "LabReportTemplateModel",
                        principalColumn: "ReportTemplateID",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "PAT_Patient",
                columns: table => new
                {
                    PatientId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    PatientNo = table.Column<int>(type: "integer", nullable: false),
                    EMPI = table.Column<string>(type: "text", nullable: false),
                    Salutation = table.Column<string>(type: "text", nullable: false),
                    FirstName = table.Column<string>(type: "text", nullable: false),
                    LastName = table.Column<string>(type: "text", nullable: false),
                    MiddleName = table.Column<string>(type: "text", nullable: false),
                    FatherName = table.Column<string>(type: "text", nullable: false),
                    MotherName = table.Column<string>(type: "text", nullable: false),
                    Gender = table.Column<string>(type: "text", nullable: false),
                    Age = table.Column<string>(type: "text", nullable: false),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    CreatedBy = table.Column<int>(type: "integer", nullable: false),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    DateOfBirth = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    PreviousLastName = table.Column<string>(type: "text", nullable: false),
                    MaritalStatus = table.Column<string>(type: "text", nullable: false),
                    Race = table.Column<string>(type: "text", nullable: false),
                    PhoneNumber = table.Column<string>(type: "text", nullable: false),
                    LandLineNumber = table.Column<string>(type: "text", nullable: false),
                    PassportNumber = table.Column<string>(type: "text", nullable: false),
                    Email = table.Column<string>(type: "text", nullable: false),
                    IDCardType = table.Column<string>(type: "text", nullable: false),
                    PhoneAcceptsText = table.Column<bool>(type: "boolean", nullable: false),
                    IDCardNumber = table.Column<string>(type: "text", nullable: false),
                    Occupation = table.Column<string>(type: "text", nullable: false),
                    EthnicGroup = table.Column<string>(type: "text", nullable: false),
                    BloodGroup = table.Column<string>(type: "text", nullable: false),
                    EmployerInfo = table.Column<string>(type: "text", nullable: false),
                    CountryId = table.Column<int>(type: "integer", nullable: false),
                    CountrySubDivisionId = table.Column<int>(type: "integer", nullable: true),
                    PatientCode = table.Column<string>(type: "text", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsOutdoorPat = table.Column<bool>(type: "boolean", nullable: false),
                    DialysisCode = table.Column<int>(type: "integer", nullable: true),
                    MunicipalityId = table.Column<int>(type: "integer", nullable: true),
                    WardNumber = table.Column<short>(type: "smallint", nullable: true),
                    ShortName = table.Column<string>(type: "text", nullable: false),
                    IsDobVerified = table.Column<bool>(type: "boolean", nullable: false),
                    Address = table.Column<string>(type: "text", nullable: false),
                    PANNumber = table.Column<string>(type: "text", nullable: false),
                    PatientNameLocal = table.Column<string>(type: "text", nullable: false),
                    Ins_HasInsurance = table.Column<bool>(type: "boolean", nullable: false),
                    Ins_NshiNumber = table.Column<string>(type: "text", nullable: false),
                    Ins_InsuranceBalance = table.Column<double>(type: "double precision", nullable: false),
                    Ins_LatestClaimCode = table.Column<long>(type: "bigint", nullable: true),
                    IsSSUPatient = table.Column<bool>(type: "boolean", nullable: false),
                    SSU_IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsVaccinationPatient = table.Column<bool>(type: "boolean", nullable: false),
                    IsVaccinationActive = table.Column<bool>(type: "boolean", nullable: false),
                    VaccinationRegNo = table.Column<int>(type: "integer", nullable: true),
                    VaccinationFiscalYearId = table.Column<int>(type: "integer", nullable: true),
                    Telmed_Patient_GUID = table.Column<string>(type: "text", nullable: false),
                    Posting = table.Column<string>(type: "text", nullable: false),
                    Rank = table.Column<string>(type: "text", nullable: false),
                    DependentId = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PAT_Patient", x => x.PatientId);
                    table.ForeignKey(
                        name: "FK_PAT_Patient_MST_CountrySubDivision_CountrySubDivisionId",
                        column: x => x.CountrySubDivisionId,
                        principalTable: "MST_CountrySubDivision",
                        principalColumn: "CountrySubDivisionId");
                });

            migrationBuilder.CreateTable(
                name: "BIL_MST_ServiceDepartment",
                columns: table => new
                {
                    ServiceDepartmentId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    ServiceDepartmentName = table.Column<string>(type: "text", nullable: false),
                    ServiceDepartmentShortName = table.Column<string>(type: "text", nullable: false),
                    DepartmentId = table.Column<int>(type: "integer", nullable: false),
                    CreatedBy = table.Column<int>(type: "integer", nullable: true),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    IntegrationName = table.Column<string>(type: "text", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: true),
                    ParentServiceDepartmentId = table.Column<int>(type: "integer", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_BIL_MST_ServiceDepartment", x => x.ServiceDepartmentId);
                    table.ForeignKey(
                        name: "FK_BIL_MST_ServiceDepartment_MST_Department_DepartmentId",
                        column: x => x.DepartmentId,
                        principalTable: "MST_Department",
                        principalColumn: "DepartmentId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "EMP_Employee",
                columns: table => new
                {
                    EmployeeId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    FirstName = table.Column<string>(type: "text", nullable: false),
                    MiddleName = table.Column<string>(type: "text", nullable: false),
                    LastName = table.Column<string>(type: "text", nullable: false),
                    ImageFullPath = table.Column<string>(type: "text", nullable: false),
                    ImageName = table.Column<string>(type: "text", nullable: false),
                    DateOfBirth = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    DateOfJoining = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ContactNumber = table.Column<string>(type: "text", nullable: false),
                    Email = table.Column<string>(type: "text", nullable: false),
                    ContactAddress = table.Column<string>(type: "text", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    Salutation = table.Column<string>(type: "text", nullable: false),
                    DepartmentId = table.Column<int>(type: "integer", nullable: true),
                    EmployeeRoleId = table.Column<int>(type: "integer", nullable: true),
                    EmployeeTypeId = table.Column<int>(type: "integer", nullable: true),
                    CreatedBy = table.Column<int>(type: "integer", nullable: true),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    Gender = table.Column<string>(type: "text", nullable: false),
                    FullName = table.Column<string>(type: "text", nullable: false),
                    Extension = table.Column<short>(type: "smallint", nullable: true),
                    SpeedDial = table.Column<short>(type: "smallint", nullable: true),
                    OfficeHour = table.Column<string>(type: "text", nullable: false),
                    RoomNo = table.Column<string>(type: "text", nullable: false),
                    MedCertificationNo = table.Column<string>(type: "text", nullable: false),
                    Signature = table.Column<string>(type: "text", nullable: false),
                    LongSignature = table.Column<string>(type: "text", nullable: false),
                    IsAppointmentApplicable = table.Column<bool>(type: "boolean", nullable: true),
                    LabSignature = table.Column<string>(type: "text", nullable: false),
                    RadiologySignature = table.Column<string>(type: "text", nullable: false),
                    BloodGroup = table.Column<string>(type: "text", nullable: false),
                    DriverLicenseNo = table.Column<string>(type: "text", nullable: false),
                    NursingCertificationNo = table.Column<string>(type: "text", nullable: false),
                    HealthProfessionalCertificationNo = table.Column<string>(type: "text", nullable: false),
                    DisplaySequence = table.Column<int>(type: "integer", nullable: true),
                    SignatoryImageName = table.Column<string>(type: "text", nullable: false),
                    IsExternal = table.Column<bool>(type: "boolean", nullable: false),
                    TDSPercent = table.Column<double>(type: "double precision", nullable: true),
                    IsIncentiveApplicable = table.Column<bool>(type: "boolean", nullable: true),
                    PANNumber = table.Column<string>(type: "text", nullable: false),
                    OpdNewPatientServiceItemId = table.Column<int>(type: "integer", nullable: true),
                    OpdOldPatientServiceItemId = table.Column<int>(type: "integer", nullable: true),
                    FollowupServiceItemId = table.Column<int>(type: "integer", nullable: true),
                    InternalReferralServiceItemId = table.Column<int>(type: "integer", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_EMP_Employee", x => x.EmployeeId);
                    table.ForeignKey(
                        name: "FK_EMP_Employee_EMP_EmployeeRole_EmployeeRoleId",
                        column: x => x.EmployeeRoleId,
                        principalTable: "EMP_EmployeeRole",
                        principalColumn: "EmployeeRoleId");
                    table.ForeignKey(
                        name: "FK_EMP_Employee_EMP_EmployeeType_EmployeeTypeId",
                        column: x => x.EmployeeTypeId,
                        principalTable: "EMP_EmployeeType",
                        principalColumn: "EmployeeTypeId");
                    table.ForeignKey(
                        name: "FK_EMP_Employee_MST_Department_DepartmentId",
                        column: x => x.DepartmentId,
                        principalTable: "MST_Department",
                        principalColumn: "DepartmentId");
                });

            migrationBuilder.CreateTable(
                name: "PHRM_MAP_MstItemsPriceCategory",
                columns: table => new
                {
                    PriceCategoryMapId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    PriceCategoryId = table.Column<int>(type: "integer", nullable: false),
                    ItemId = table.Column<int>(type: "integer", nullable: false),
                    Price = table.Column<decimal>(type: "numeric", nullable: true),
                    DiscountApplicable = table.Column<bool>(type: "boolean", nullable: false),
                    ItemLegalCode = table.Column<string>(type: "text", nullable: false),
                    ItemLegalName = table.Column<string>(type: "text", nullable: false),
                    Discount = table.Column<decimal>(type: "numeric", nullable: true),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedBy = table.Column<int>(type: "integer", nullable: true),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    ItemsItemId = table.Column<int>(type: "integer", nullable: false),
                    GenericId = table.Column<int>(type: "integer", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PHRM_MAP_MstItemsPriceCategory", x => x.PriceCategoryMapId);
                    table.ForeignKey(
                        name: "FK_PHRM_MAP_MstItemsPriceCategory_PHRMGenericModel_GenericId",
                        column: x => x.GenericId,
                        principalTable: "PHRMGenericModel",
                        principalColumn: "GenericId");
                    table.ForeignKey(
                        name: "FK_PHRM_MAP_MstItemsPriceCategory_PHRM_MST_Item_ItemsItemId",
                        column: x => x.ItemsItemId,
                        principalTable: "PHRM_MST_Item",
                        principalColumn: "ItemId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "RAD_MST_ImagingItem",
                columns: table => new
                {
                    ImagingItemId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    ImagingTypeId = table.Column<int>(type: "integer", nullable: false),
                    ImagingItemName = table.Column<string>(type: "text", nullable: false),
                    ProcedureCode = table.Column<string>(type: "text", nullable: false),
                    CreatedBy = table.Column<int>(type: "integer", nullable: true),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    IsActive = table.Column<bool>(type: "boolean", nullable: true),
                    IsValidForReporting = table.Column<bool>(type: "boolean", nullable: false),
                    TemplateId = table.Column<int>(type: "integer", nullable: true),
                    ImagingTypesImagingTypeId = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RAD_MST_ImagingItem", x => x.ImagingItemId);
                    table.ForeignKey(
                        name: "FK_RAD_MST_ImagingItem_RAD_MST_ImagingType_ImagingTypesImaging~",
                        column: x => x.ImagingTypesImagingTypeId,
                        principalTable: "RAD_MST_ImagingType",
                        principalColumn: "ImagingTypeId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ADT_MAP_BedFeaturesMap",
                columns: table => new
                {
                    BedFeatureCFGId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    BedId = table.Column<int>(type: "integer", nullable: false),
                    WardId = table.Column<int>(type: "integer", nullable: false),
                    BedFeatureId = table.Column<int>(type: "integer", nullable: false),
                    CreatedBy = table.Column<int>(type: "integer", nullable: false),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ADT_MAP_BedFeaturesMap", x => x.BedFeatureCFGId);
                    table.ForeignKey(
                        name: "FK_ADT_MAP_BedFeaturesMap_ADT_MAP_WardBedType_BedId",
                        column: x => x.BedId,
                        principalTable: "ADT_MAP_WardBedType",
                        principalColumn: "BedId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ADT_MAP_BedFeaturesMap_ADT_MST_BedFeature_BedFeatureId",
                        column: x => x.BedFeatureId,
                        principalTable: "ADT_MST_BedFeature",
                        principalColumn: "BedFeatureId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ADT_MAP_BedFeaturesMap_ADT_MST_Ward_WardId",
                        column: x => x.WardId,
                        principalTable: "ADT_MST_Ward",
                        principalColumn: "WardId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ActiveMedicalProblem",
                columns: table => new
                {
                    PatientProblemId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    CurrentStatus = table.Column<string>(type: "text", nullable: false),
                    Note = table.Column<string>(type: "text", nullable: false),
                    OnSetDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ResolvedDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    IsResolved = table.Column<bool>(type: "boolean", nullable: false),
                    PrincipleProblem = table.Column<bool>(type: "boolean", nullable: true),
                    PatientId = table.Column<int>(type: "integer", nullable: false),
                    ICD10Code = table.Column<string>(type: "text", nullable: false),
                    ICD10Description = table.Column<string>(type: "text", nullable: false),
                    CreatedBy = table.Column<int>(type: "integer", nullable: true),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ActiveMedicalProblem", x => x.PatientProblemId);
                    table.ForeignKey(
                        name: "FK_ActiveMedicalProblem_PAT_Patient_PatientId",
                        column: x => x.PatientId,
                        principalTable: "PAT_Patient",
                        principalColumn: "PatientId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "AddressModel",
                columns: table => new
                {
                    PatientAddressId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    PatientId = table.Column<int>(type: "integer", nullable: false),
                    AddressType = table.Column<string>(type: "text", nullable: false),
                    Street1 = table.Column<string>(type: "text", nullable: false),
                    Street2 = table.Column<string>(type: "text", nullable: false),
                    CountryId = table.Column<int>(type: "integer", nullable: false),
                    CountrySubDivisionId = table.Column<int>(type: "integer", nullable: true),
                    City = table.Column<string>(type: "text", nullable: false),
                    ZipCode = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AddressModel", x => x.PatientAddressId);
                    table.ForeignKey(
                        name: "FK_AddressModel_PAT_Patient_PatientId",
                        column: x => x.PatientId,
                        principalTable: "PAT_Patient",
                        principalColumn: "PatientId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "AllergyModel",
                columns: table => new
                {
                    PatientAllergyId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    PatientId = table.Column<int>(type: "integer", nullable: false),
                    AllergenAdvRecId = table.Column<int>(type: "integer", nullable: true),
                    AllergenAdvRecName = table.Column<string>(type: "text", nullable: false),
                    AllergyType = table.Column<string>(type: "text", nullable: false),
                    Severity = table.Column<string>(type: "text", nullable: false),
                    Verified = table.Column<bool>(type: "boolean", nullable: false),
                    Reaction = table.Column<string>(type: "text", nullable: false),
                    Comments = table.Column<string>(type: "text", nullable: false),
                    CreatedBy = table.Column<int>(type: "integer", nullable: true),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AllergyModel", x => x.PatientAllergyId);
                    table.ForeignKey(
                        name: "FK_AllergyModel_PAT_Patient_PatientId",
                        column: x => x.PatientId,
                        principalTable: "PAT_Patient",
                        principalColumn: "PatientId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "FamilyHistory",
                columns: table => new
                {
                    FamilyProblemId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Relationship = table.Column<string>(type: "text", nullable: false),
                    Note = table.Column<string>(type: "text", nullable: false),
                    PatientId = table.Column<int>(type: "integer", nullable: false),
                    ICD10Code = table.Column<string>(type: "text", nullable: false),
                    ICD10Description = table.Column<string>(type: "text", nullable: false),
                    CreatedBy = table.Column<int>(type: "integer", nullable: true),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_FamilyHistory", x => x.FamilyProblemId);
                    table.ForeignKey(
                        name: "FK_FamilyHistory_PAT_Patient_PatientId",
                        column: x => x.PatientId,
                        principalTable: "PAT_Patient",
                        principalColumn: "PatientId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "GuarantorModel",
                columns: table => new
                {
                    PatientId = table.Column<int>(type: "integer", nullable: false),
                    PatientGurantorInfo = table.Column<int>(type: "integer", nullable: true),
                    GuarantorSelf = table.Column<bool>(type: "boolean", nullable: false),
                    PatientRelationship = table.Column<string>(type: "text", nullable: false),
                    GuarantorName = table.Column<string>(type: "text", nullable: false),
                    GuarantorGender = table.Column<string>(type: "text", nullable: false),
                    GuarantorCountryId = table.Column<int>(type: "integer", nullable: true),
                    GuarantorPhoneNumber = table.Column<string>(type: "text", nullable: false),
                    GuarantorDateOfBirth = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    GuarantorStreet1 = table.Column<string>(type: "text", nullable: false),
                    GuarantorStreet2 = table.Column<string>(type: "text", nullable: false),
                    GuarantorCity = table.Column<string>(type: "text", nullable: false),
                    GuarantorCountrySubDivisionId = table.Column<int>(type: "integer", nullable: true),
                    GuarantorZIPCode = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_GuarantorModel", x => x.PatientId);
                    table.ForeignKey(
                        name: "FK_GuarantorModel_PAT_Patient_PatientId",
                        column: x => x.PatientId,
                        principalTable: "PAT_Patient",
                        principalColumn: "PatientId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "HomeMedicationModel",
                columns: table => new
                {
                    HomeMedicationId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    PatientId = table.Column<int>(type: "integer", nullable: false),
                    MedicationId = table.Column<int>(type: "integer", nullable: true),
                    Dose = table.Column<string>(type: "text", nullable: false),
                    Route = table.Column<string>(type: "text", nullable: false),
                    Frequency = table.Column<int>(type: "integer", nullable: false),
                    LastTaken = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Comments = table.Column<string>(type: "text", nullable: false),
                    MedicationType = table.Column<string>(type: "text", nullable: false),
                    CreatedBy = table.Column<int>(type: "integer", nullable: true),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_HomeMedicationModel", x => x.HomeMedicationId);
                    table.ForeignKey(
                        name: "FK_HomeMedicationModel_PAT_Patient_PatientId",
                        column: x => x.PatientId,
                        principalTable: "PAT_Patient",
                        principalColumn: "PatientId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "InsuranceModel",
                columns: table => new
                {
                    PatientInsuranceInfoId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    PatientId = table.Column<int>(type: "integer", nullable: false),
                    InsuranceNumber = table.Column<string>(type: "text", nullable: false),
                    InsuranceName = table.Column<string>(type: "text", nullable: false),
                    CardNumber = table.Column<string>(type: "text", nullable: false),
                    SubscriberFirstName = table.Column<string>(type: "text", nullable: false),
                    SubscriberLastName = table.Column<string>(type: "text", nullable: false),
                    SubscriberGender = table.Column<string>(type: "text", nullable: false),
                    SubscriberDOB = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    SubscriberIDCardNumber = table.Column<string>(type: "text", nullable: false),
                    SubscriberIDCardType = table.Column<string>(type: "text", nullable: false),
                    IMISCode = table.Column<string>(type: "text", nullable: false),
                    InitialBalance = table.Column<double>(type: "double precision", nullable: false),
                    CurrentBalance = table.Column<double>(type: "double precision", nullable: false),
                    InsuranceProviderId = table.Column<int>(type: "integer", nullable: false),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedBy = table.Column<int>(type: "integer", nullable: true),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    Ins_HasInsurance = table.Column<bool>(type: "boolean", nullable: true),
                    Ins_NshiNumber = table.Column<string>(type: "text", nullable: false),
                    Ins_InsuranceBalance = table.Column<double>(type: "double precision", nullable: true),
                    Ins_InsuranceProviderId = table.Column<int>(type: "integer", nullable: true),
                    Ins_IsFamilyHead = table.Column<bool>(type: "boolean", nullable: true),
                    Ins_FamilyHeadNshi = table.Column<string>(type: "text", nullable: false),
                    Ins_FamilyHeadName = table.Column<string>(type: "text", nullable: false),
                    Ins_IsFirstServicePoint = table.Column<bool>(type: "boolean", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_InsuranceModel", x => x.PatientInsuranceInfoId);
                    table.ForeignKey(
                        name: "FK_InsuranceModel_PAT_Patient_PatientId",
                        column: x => x.PatientId,
                        principalTable: "PAT_Patient",
                        principalColumn: "PatientId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "KinModel",
                columns: table => new
                {
                    PatientKinOrEmergencyContactId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    PatientId = table.Column<int>(type: "integer", nullable: false),
                    KinContactType = table.Column<string>(type: "text", nullable: false),
                    KinFirstName = table.Column<string>(type: "text", nullable: false),
                    KinLastName = table.Column<string>(type: "text", nullable: false),
                    KinPhoneNumber = table.Column<string>(type: "text", nullable: false),
                    RelationShip = table.Column<string>(type: "text", nullable: false),
                    KinComment = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_KinModel", x => x.PatientKinOrEmergencyContactId);
                    table.ForeignKey(
                        name: "FK_KinModel_PAT_Patient_PatientId",
                        column: x => x.PatientId,
                        principalTable: "PAT_Patient",
                        principalColumn: "PatientId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "LabRequisitionModel",
                columns: table => new
                {
                    RequisitionId = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    PatientVisitId = table.Column<int>(type: "integer", nullable: true),
                    PatientId = table.Column<int>(type: "integer", nullable: false),
                    PrescriberId = table.Column<int>(type: "integer", nullable: true),
                    LabTestId = table.Column<long>(type: "bigint", nullable: false),
                    ProcedureCode = table.Column<string>(type: "text", nullable: false),
                    LOINC = table.Column<string>(type: "text", nullable: false),
                    LabTestName = table.Column<string>(type: "text", nullable: false),
                    LabTestSpecimen = table.Column<string>(type: "text", nullable: false),
                    LabTestSpecimenSource = table.Column<string>(type: "text", nullable: false),
                    PatientName = table.Column<string>(type: "text", nullable: false),
                    Diagnosis = table.Column<string>(type: "text", nullable: false),
                    Urgency = table.Column<string>(type: "text", nullable: false),
                    OrderDateTime = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    PrescriberName = table.Column<string>(type: "text", nullable: false),
                    BillingStatus = table.Column<string>(type: "text", nullable: false),
                    OrderStatus = table.Column<string>(type: "text", nullable: false),
                    SampleCode = table.Column<int>(type: "integer", nullable: true),
                    RequisitionRemarks = table.Column<string>(type: "text", nullable: false),
                    SampleCreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    SampleCollectedOnDateTime = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    SampleCreatedBy = table.Column<int>(type: "integer", nullable: true),
                    Comments = table.Column<string>(type: "text", nullable: false),
                    RunNumberType = table.Column<string>(type: "text", nullable: false),
                    ExternalLabSampleStatus = table.Column<string>(type: "text", nullable: false),
                    IsSmsSend = table.Column<bool>(type: "boolean", nullable: false),
                    ReportTemplateId = table.Column<int>(type: "integer", nullable: false),
                    DiagnosisId = table.Column<int>(type: "integer", nullable: true),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    CreatedBy = table.Column<int>(type: "integer", nullable: false),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    VisitType = table.Column<string>(type: "text", nullable: false),
                    LabReportId = table.Column<int>(type: "integer", nullable: true),
                    BarCodeNumber = table.Column<long>(type: "bigint", nullable: true),
                    WardName = table.Column<string>(type: "text", nullable: false),
                    IsVerified = table.Column<bool>(type: "boolean", nullable: true),
                    VerifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    VerifiedBy = table.Column<int>(type: "integer", nullable: true),
                    ResultingVendorId = table.Column<int>(type: "integer", nullable: false),
                    HasInsurance = table.Column<bool>(type: "boolean", nullable: false),
                    ResultAddedBy = table.Column<int>(type: "integer", nullable: true),
                    ResultAddedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    PrintedBy = table.Column<int>(type: "integer", nullable: true),
                    PrintCount = table.Column<int>(type: "integer", nullable: true),
                    SampleCodeFormatted = table.Column<string>(type: "text", nullable: false),
                    BillCancelledBy = table.Column<int>(type: "integer", nullable: true),
                    BillCancelledOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    LabTypeName = table.Column<string>(type: "text", nullable: false),
                    GoogleFileIdForCovid = table.Column<string>(type: "text", nullable: false),
                    CovidFileName = table.Column<string>(type: "text", nullable: false),
                    IsFileUploaded = table.Column<bool>(type: "boolean", nullable: true),
                    UploadedBy = table.Column<int>(type: "integer", nullable: true),
                    UploadedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    IsFileUploadedToTeleMedicine = table.Column<bool>(type: "boolean", nullable: true),
                    UploadedByToTeleMedicine = table.Column<int>(type: "integer", nullable: true),
                    UploadedOnToTeleMedicine = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    IsUploadedToIMU = table.Column<bool>(type: "boolean", nullable: true),
                    IMUUploadedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    IMUUploadedBy = table.Column<int>(type: "integer", nullable: true),
                    BillingTransactionItemId = table.Column<int>(type: "integer", nullable: false),
                    ServiceItemId = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LabRequisitionModel", x => x.RequisitionId);
                    table.ForeignKey(
                        name: "FK_LabRequisitionModel_LabTestModel_LabTestId",
                        column: x => x.LabTestId,
                        principalTable: "LabTestModel",
                        principalColumn: "LabTestId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_LabRequisitionModel_PAT_Patient_PatientId",
                        column: x => x.PatientId,
                        principalTable: "PAT_Patient",
                        principalColumn: "PatientId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "MedicationPrescriptionModel",
                columns: table => new
                {
                    MedicationPrescriptionId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    PatientId = table.Column<int>(type: "integer", nullable: false),
                    MedicationId = table.Column<int>(type: "integer", nullable: false),
                    PerformerId = table.Column<int>(type: "integer", nullable: false),
                    Route = table.Column<string>(type: "text", nullable: false),
                    Duration = table.Column<int>(type: "integer", nullable: false),
                    DurationType = table.Column<string>(type: "text", nullable: false),
                    Dose = table.Column<string>(type: "text", nullable: false),
                    Frequency = table.Column<string>(type: "text", nullable: false),
                    Refill = table.Column<int>(type: "integer", nullable: true),
                    TypeofMedication = table.Column<string>(type: "text", nullable: false),
                    CreatedBy = table.Column<int>(type: "integer", nullable: true),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MedicationPrescriptionModel", x => x.MedicationPrescriptionId);
                    table.ForeignKey(
                        name: "FK_MedicationPrescriptionModel_PAT_Patient_PatientId",
                        column: x => x.PatientId,
                        principalTable: "PAT_Patient",
                        principalColumn: "PatientId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "PastMedicalProblem",
                columns: table => new
                {
                    PatientProblemId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    CurrentStatus = table.Column<string>(type: "text", nullable: false),
                    Note = table.Column<string>(type: "text", nullable: false),
                    OnSetDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ResolvedDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    PrincipleProblem = table.Column<bool>(type: "boolean", nullable: true),
                    PatientId = table.Column<int>(type: "integer", nullable: false),
                    ICD10Code = table.Column<string>(type: "text", nullable: false),
                    ICD10Description = table.Column<string>(type: "text", nullable: false),
                    CreatedBy = table.Column<int>(type: "integer", nullable: true),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PastMedicalProblem", x => x.PatientProblemId);
                    table.ForeignKey(
                        name: "FK_PastMedicalProblem_PAT_Patient_PatientId",
                        column: x => x.PatientId,
                        principalTable: "PAT_Patient",
                        principalColumn: "PatientId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "PatientFilesModel",
                columns: table => new
                {
                    PatientFileId = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    PatientId = table.Column<int>(type: "integer", nullable: false),
                    ROWGUID = table.Column<Guid>(type: "uuid", nullable: false),
                    FileType = table.Column<string>(type: "text", nullable: false),
                    Title = table.Column<string>(type: "text", nullable: false),
                    UploadedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UploadedBy = table.Column<int>(type: "integer", nullable: false),
                    Description = table.Column<string>(type: "text", nullable: false),
                    FileNo = table.Column<int>(type: "integer", nullable: false),
                    FileName = table.Column<string>(type: "text", nullable: false),
                    FileExtention = table.Column<string>(type: "text", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: true),
                    PatientModelPatientId = table.Column<int>(type: "integer", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PatientFilesModel", x => x.PatientFileId);
                    table.ForeignKey(
                        name: "FK_PatientFilesModel_PAT_Patient_PatientModelPatientId",
                        column: x => x.PatientModelPatientId,
                        principalTable: "PAT_Patient",
                        principalColumn: "PatientId");
                });

            migrationBuilder.CreateTable(
                name: "SocialHistory",
                columns: table => new
                {
                    SocialHistoryId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    PatientId = table.Column<int>(type: "integer", nullable: false),
                    SmokingHistory = table.Column<string>(type: "text", nullable: false),
                    AlcoholHistory = table.Column<string>(type: "text", nullable: false),
                    DrugHistory = table.Column<string>(type: "text", nullable: false),
                    Occupation = table.Column<string>(type: "text", nullable: false),
                    FamilySupport = table.Column<string>(type: "text", nullable: false),
                    Note = table.Column<string>(type: "text", nullable: false),
                    CreatedBy = table.Column<int>(type: "integer", nullable: true),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SocialHistory", x => x.SocialHistoryId);
                    table.ForeignKey(
                        name: "FK_SocialHistory_PAT_Patient_PatientId",
                        column: x => x.PatientId,
                        principalTable: "PAT_Patient",
                        principalColumn: "PatientId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "SurgicalHistory",
                columns: table => new
                {
                    SurgicalHistoryId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    SurgeryType = table.Column<string>(type: "text", nullable: false),
                    Note = table.Column<string>(type: "text", nullable: false),
                    SurgeryDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    PatientId = table.Column<int>(type: "integer", nullable: false),
                    ICD10Code = table.Column<string>(type: "text", nullable: false),
                    ICD10Description = table.Column<string>(type: "text", nullable: false),
                    CreatedBy = table.Column<int>(type: "integer", nullable: true),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SurgicalHistory", x => x.SurgicalHistoryId);
                    table.ForeignKey(
                        name: "FK_SurgicalHistory_PAT_Patient_PatientId",
                        column: x => x.PatientId,
                        principalTable: "PAT_Patient",
                        principalColumn: "PatientId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "VisitModel",
                columns: table => new
                {
                    PatientVisitId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    VisitCode = table.Column<string>(type: "text", nullable: false),
                    PatientId = table.Column<int>(type: "integer", nullable: false),
                    VisitDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    QueueStatus = table.Column<string>(type: "text", nullable: false),
                    PerformerId = table.Column<int>(type: "integer", nullable: true),
                    PerformerName = table.Column<string>(type: "text", nullable: false),
                    Comments = table.Column<string>(type: "text", nullable: false),
                    ReferredBy = table.Column<string>(type: "text", nullable: false),
                    VisitType = table.Column<string>(type: "text", nullable: false),
                    VisitStatus = table.Column<string>(type: "text", nullable: false),
                    VisitTime = table.Column<TimeSpan>(type: "interval", nullable: true),
                    VisitDuration = table.Column<int>(type: "integer", nullable: true),
                    AppointmentId = table.Column<int>(type: "integer", nullable: true),
                    BillingStatus = table.Column<string>(type: "text", nullable: false),
                    ReferredById = table.Column<int>(type: "integer", nullable: true),
                    AppointmentType = table.Column<string>(type: "text", nullable: false),
                    ParentVisitId = table.Column<int>(type: "integer", nullable: true),
                    IsVisitContinued = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    CreatedBy = table.Column<int>(type: "integer", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsTriaged = table.Column<bool>(type: "boolean", nullable: false),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    Remarks = table.Column<string>(type: "text", nullable: false),
                    ClaimCode = table.Column<long>(type: "bigint", nullable: true),
                    IsSignedVisitSummary = table.Column<bool>(type: "boolean", nullable: false),
                    PrescriberId = table.Column<int>(type: "integer", nullable: true),
                    ConcludeDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    DepartmentId = table.Column<int>(type: "integer", nullable: false),
                    QueueNo = table.Column<int>(type: "integer", nullable: true),
                    Ins_HasInsurance = table.Column<bool>(type: "boolean", nullable: false),
                    PriceCategoryId = table.Column<int>(type: "integer", nullable: false),
                    SchemeId = table.Column<int>(type: "integer", nullable: false),
                    TicketCharge = table.Column<decimal>(type: "numeric", nullable: false),
                    SubSchemeId = table.Column<int>(type: "integer", nullable: true),
                    IsFreeVisit = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_VisitModel", x => x.PatientVisitId);
                    table.ForeignKey(
                        name: "FK_VisitModel_PAT_Patient_PatientId",
                        column: x => x.PatientId,
                        principalTable: "PAT_Patient",
                        principalColumn: "PatientId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "BIL_MST_ServiceItem",
                columns: table => new
                {
                    ServiceItemId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    ServiceDepartmentId = table.Column<int>(type: "integer", nullable: false),
                    IntegrationItemId = table.Column<int>(type: "integer", nullable: false),
                    IntegrationName = table.Column<string>(type: "text", nullable: false),
                    ItemCode = table.Column<string>(type: "text", nullable: false),
                    ItemName = table.Column<string>(type: "text", nullable: false),
                    IsTaxApplicable = table.Column<bool>(type: "boolean", nullable: false),
                    Description = table.Column<string>(type: "text", nullable: false),
                    DisplaySeq = table.Column<int>(type: "integer", nullable: true),
                    IsDoctorMandatory = table.Column<bool>(type: "boolean", nullable: false),
                    IsOT = table.Column<bool>(type: "boolean", nullable: false),
                    IsProc = table.Column<bool>(type: "boolean", nullable: false),
                    ServiceCategoryId = table.Column<int>(type: "integer", nullable: true),
                    AllowMultipleQty = table.Column<bool>(type: "boolean", nullable: false),
                    DefaultDoctorList = table.Column<string>(type: "text", nullable: false),
                    IsValidForReporting = table.Column<bool>(type: "boolean", nullable: false),
                    IsErLabApplicable = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedBy = table.Column<int>(type: "integer", nullable: false),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsIncentiveApplicable = table.Column<bool>(type: "boolean", nullable: false),
                    ServiceDepartmentModelServiceDepartmentId = table.Column<int>(type: "integer", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_BIL_MST_ServiceItem", x => x.ServiceItemId);
                    table.ForeignKey(
                        name: "FK_BIL_MST_ServiceItem_BIL_MST_ServiceDepartment_ServiceDepart~",
                        column: x => x.ServiceDepartmentModelServiceDepartmentId,
                        principalTable: "BIL_MST_ServiceDepartment",
                        principalColumn: "ServiceDepartmentId");
                });

            migrationBuilder.CreateTable(
                name: "LabTestComponentResult",
                columns: table => new
                {
                    TestComponentResultId = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    RequisitionId = table.Column<long>(type: "bigint", nullable: false),
                    LabTestId = table.Column<long>(type: "bigint", nullable: false),
                    Value = table.Column<string>(type: "text", nullable: false),
                    Unit = table.Column<string>(type: "text", nullable: false),
                    Range = table.Column<string>(type: "text", nullable: false),
                    ComponentName = table.Column<string>(type: "text", nullable: false),
                    ComponentId = table.Column<int>(type: "integer", nullable: false),
                    Method = table.Column<string>(type: "text", nullable: false),
                    CreatedBy = table.Column<int>(type: "integer", nullable: false),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    Remarks = table.Column<string>(type: "text", nullable: false),
                    TemplateId = table.Column<int>(type: "integer", nullable: false),
                    RangeDescription = table.Column<string>(type: "text", nullable: false),
                    LabRequisitionRequisitionId = table.Column<long>(type: "bigint", nullable: false),
                    IsNegativeResult = table.Column<bool>(type: "boolean", nullable: false),
                    NegativeResultText = table.Column<string>(type: "text", nullable: false),
                    IsAbnormal = table.Column<bool>(type: "boolean", nullable: false),
                    LabReportId = table.Column<int>(type: "integer", nullable: true),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    AbnormalType = table.Column<string>(type: "text", nullable: false),
                    ResultGroup = table.Column<int>(type: "integer", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LabTestComponentResult", x => x.TestComponentResultId);
                    table.ForeignKey(
                        name: "FK_LabTestComponentResult_LabRequisitionModel_LabRequisitionRe~",
                        column: x => x.LabRequisitionRequisitionId,
                        principalTable: "LabRequisitionModel",
                        principalColumn: "RequisitionId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "AdmissionModel",
                columns: table => new
                {
                    PatientVisitId = table.Column<int>(type: "integer", nullable: false),
                    PatientAdmissionId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    PatientId = table.Column<int>(type: "integer", nullable: false),
                    AdmittingDoctorId = table.Column<int>(type: "integer", nullable: true),
                    AdmissionDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    DischargeDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    AdmissionNotes = table.Column<string>(type: "text", nullable: false),
                    AdmissionOrders = table.Column<string>(type: "text", nullable: false),
                    AdmissionStatus = table.Column<string>(type: "text", nullable: false),
                    CreatedBy = table.Column<int>(type: "integer", nullable: false),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    BillStatusOnDischarge = table.Column<string>(type: "text", nullable: false),
                    DischargeRemarks = table.Column<string>(type: "text", nullable: false),
                    DischargedBy = table.Column<int>(type: "integer", nullable: true),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CareOfPersonName = table.Column<string>(type: "text", nullable: false),
                    CareOfPersonPhoneNo = table.Column<string>(type: "text", nullable: false),
                    CareOfPersonRelation = table.Column<string>(type: "text", nullable: false),
                    CancelledOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CancelledBy = table.Column<int>(type: "integer", nullable: true),
                    CancelledRemark = table.Column<string>(type: "text", nullable: false),
                    ProcedureType = table.Column<string>(type: "text", nullable: false),
                    IsPoliceCase = table.Column<bool>(type: "boolean", nullable: false),
                    IsInsurancePatient = table.Column<bool>(type: "boolean", nullable: false),
                    DiscountSchemeId = table.Column<int>(type: "integer", nullable: true),
                    AdmissionCase = table.Column<string>(type: "text", nullable: false),
                    ProvisionalDiscPercent = table.Column<double>(type: "double precision", nullable: false),
                    IsItemDiscountEnabled = table.Column<bool>(type: "boolean", nullable: false),
                    IsProvisionalDischarge = table.Column<bool>(type: "boolean", nullable: false),
                    IsProvisionalDischargeCleared = table.Column<bool>(type: "boolean", nullable: false),
                    PatientModelPatientId = table.Column<int>(type: "integer", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AdmissionModel", x => x.PatientVisitId);
                    table.ForeignKey(
                        name: "FK_AdmissionModel_PAT_Patient_PatientModelPatientId",
                        column: x => x.PatientModelPatientId,
                        principalTable: "PAT_Patient",
                        principalColumn: "PatientId");
                    table.ForeignKey(
                        name: "FK_AdmissionModel_VisitModel_PatientVisitId",
                        column: x => x.PatientVisitId,
                        principalTable: "VisitModel",
                        principalColumn: "PatientVisitId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ImagingRequisitionModel",
                columns: table => new
                {
                    ImagingRequisitionId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    PatientVisitId = table.Column<int>(type: "integer", nullable: true),
                    PatientId = table.Column<int>(type: "integer", nullable: false),
                    PrescriberName = table.Column<string>(type: "text", nullable: false),
                    ImagingTypeId = table.Column<int>(type: "integer", nullable: true),
                    ImagingTypeName = table.Column<string>(type: "text", nullable: false),
                    ImagingItemId = table.Column<int>(type: "integer", nullable: true),
                    ImagingItemName = table.Column<string>(type: "text", nullable: false),
                    ProcedureCode = table.Column<string>(type: "text", nullable: false),
                    ImagingDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    RequisitionRemarks = table.Column<string>(type: "text", nullable: false),
                    OrderStatus = table.Column<string>(type: "text", nullable: false),
                    PrescriberId = table.Column<int>(type: "integer", nullable: true),
                    BillingStatus = table.Column<string>(type: "text", nullable: false),
                    Urgency = table.Column<string>(type: "text", nullable: false),
                    CreatedBy = table.Column<int>(type: "integer", nullable: true),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    DiagnosisId = table.Column<int>(type: "integer", nullable: true),
                    WardName = table.Column<string>(type: "text", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    BillCancelledBy = table.Column<int>(type: "integer", nullable: true),
                    BillCancelledOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    IsReportSaved = table.Column<bool>(type: "boolean", nullable: false),
                    VisitPatientVisitId = table.Column<int>(type: "integer", nullable: false),
                    HasInsurance = table.Column<bool>(type: "boolean", nullable: true),
                    IsScanned = table.Column<bool>(type: "boolean", nullable: true),
                    ScannedBy = table.Column<int>(type: "integer", nullable: true),
                    ScannedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ScanRemarks = table.Column<string>(type: "text", nullable: false),
                    FilmTypeId = table.Column<int>(type: "integer", nullable: true),
                    FilmQuantity = table.Column<int>(type: "integer", nullable: true),
                    BillingTransactionItemId = table.Column<int>(type: "integer", nullable: false),
                    ServiceItemId = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ImagingRequisitionModel", x => x.ImagingRequisitionId);
                    table.ForeignKey(
                        name: "FK_ImagingRequisitionModel_PAT_Patient_PatientId",
                        column: x => x.PatientId,
                        principalTable: "PAT_Patient",
                        principalColumn: "PatientId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ImagingRequisitionModel_RAD_MST_ImagingItem_ImagingItemId",
                        column: x => x.ImagingItemId,
                        principalTable: "RAD_MST_ImagingItem",
                        principalColumn: "ImagingItemId");
                    table.ForeignKey(
                        name: "FK_ImagingRequisitionModel_VisitModel_VisitPatientVisitId",
                        column: x => x.VisitPatientVisitId,
                        principalTable: "VisitModel",
                        principalColumn: "PatientVisitId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "InputOutputModel",
                columns: table => new
                {
                    InputOutputId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    PatientVisitId = table.Column<int>(type: "integer", nullable: false),
                    InputOutputParameterMainId = table.Column<int>(type: "integer", nullable: false),
                    InputOutputParameterChildId = table.Column<int>(type: "integer", nullable: true),
                    IntakeOutputValue = table.Column<double>(type: "double precision", nullable: false),
                    Unit = table.Column<string>(type: "text", nullable: false),
                    IntakeOutputType = table.Column<string>(type: "text", nullable: false),
                    CreatedBy = table.Column<int>(type: "integer", nullable: true),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    VisitPatientVisitId = table.Column<int>(type: "integer", nullable: false),
                    Contents = table.Column<string>(type: "text", nullable: false),
                    Remarks = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_InputOutputModel", x => x.InputOutputId);
                    table.ForeignKey(
                        name: "FK_InputOutputModel_VisitModel_VisitPatientVisitId",
                        column: x => x.VisitPatientVisitId,
                        principalTable: "VisitModel",
                        principalColumn: "PatientVisitId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "NotesModel",
                columns: table => new
                {
                    NotesId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    PatientVisitId = table.Column<int>(type: "integer", nullable: false),
                    PatientId = table.Column<int>(type: "integer", nullable: false),
                    PerformerId = table.Column<int>(type: "integer", nullable: false),
                    TemplateId = table.Column<int>(type: "integer", nullable: false),
                    SecondaryDoctorId = table.Column<int>(type: "integer", nullable: true),
                    NoteTypeId = table.Column<int>(type: "integer", nullable: true),
                    TemplateName = table.Column<string>(type: "text", nullable: false),
                    FollowUp = table.Column<int>(type: "integer", nullable: true),
                    FollowUpUnit = table.Column<string>(type: "text", nullable: false),
                    Remarks = table.Column<string>(type: "text", nullable: false),
                    IsPending = table.Column<bool>(type: "boolean", nullable: true),
                    CreatedBy = table.Column<int>(type: "integer", nullable: true),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    PatientModelPatientId = table.Column<int>(type: "integer", nullable: true),
                    VisitModelPatientVisitId = table.Column<int>(type: "integer", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_NotesModel", x => x.NotesId);
                    table.ForeignKey(
                        name: "FK_NotesModel_PAT_Patient_PatientModelPatientId",
                        column: x => x.PatientModelPatientId,
                        principalTable: "PAT_Patient",
                        principalColumn: "PatientId");
                    table.ForeignKey(
                        name: "FK_NotesModel_VisitModel_VisitModelPatientVisitId",
                        column: x => x.VisitModelPatientVisitId,
                        principalTable: "VisitModel",
                        principalColumn: "PatientVisitId");
                });

            migrationBuilder.CreateTable(
                name: "VitalsModel",
                columns: table => new
                {
                    PatientVitalId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    PatientVisitId = table.Column<int>(type: "integer", nullable: false),
                    Height = table.Column<double>(type: "double precision", nullable: true),
                    HeightUnit = table.Column<string>(type: "text", nullable: false),
                    Weight = table.Column<double>(type: "double precision", nullable: true),
                    WeightUnit = table.Column<string>(type: "text", nullable: false),
                    BMI = table.Column<double>(type: "double precision", nullable: true),
                    Temperature = table.Column<double>(type: "double precision", nullable: true),
                    TemperatureUnit = table.Column<string>(type: "text", nullable: false),
                    Pulse = table.Column<int>(type: "integer", nullable: true),
                    BPSystolic = table.Column<int>(type: "integer", nullable: true),
                    BPDiastolic = table.Column<int>(type: "integer", nullable: true),
                    RespiratoryRatePerMin = table.Column<string>(type: "text", nullable: false),
                    SpO2 = table.Column<double>(type: "double precision", nullable: true),
                    OxygenDeliveryMethod = table.Column<string>(type: "text", nullable: false),
                    PainScale = table.Column<int>(type: "integer", nullable: true),
                    BodyPart = table.Column<string>(type: "text", nullable: false),
                    VisitPatientVisitId = table.Column<int>(type: "integer", nullable: false),
                    Advice = table.Column<string>(type: "text", nullable: false),
                    FreeNotes = table.Column<string>(type: "text", nullable: false),
                    DiagnosisType = table.Column<string>(type: "text", nullable: false),
                    Diagnosis = table.Column<string>(type: "text", nullable: false),
                    CreatedBy = table.Column<int>(type: "integer", nullable: true),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    VitalsTakenOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_VitalsModel", x => x.PatientVitalId);
                    table.ForeignKey(
                        name: "FK_VitalsModel_VisitModel_VisitPatientVisitId",
                        column: x => x.VisitPatientVisitId,
                        principalTable: "VisitModel",
                        principalColumn: "PatientVisitId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "PatientBedInfo",
                columns: table => new
                {
                    PatientBedInfoId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    PatientVisitId = table.Column<int>(type: "integer", nullable: false),
                    PatientId = table.Column<int>(type: "integer", nullable: false),
                    WardId = table.Column<int>(type: "integer", nullable: false),
                    BedId = table.Column<int>(type: "integer", nullable: false),
                    BedFeatureId = table.Column<int>(type: "integer", nullable: false),
                    BedPrice = table.Column<decimal>(type: "numeric", nullable: false),
                    Action = table.Column<string>(type: "text", nullable: false),
                    OutAction = table.Column<string>(type: "text", nullable: false),
                    Remarks = table.Column<string>(type: "text", nullable: false),
                    StartedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    EndedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedBy = table.Column<int>(type: "integer", nullable: false),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    CancelledBy = table.Column<int>(type: "integer", nullable: true),
                    CancelledOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CancelRemarks = table.Column<string>(type: "text", nullable: false),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    BedOnHoldEnabled = table.Column<bool>(type: "boolean", nullable: false),
                    RequestingDeptId = table.Column<int>(type: "integer", nullable: true),
                    BedQuantity = table.Column<int>(type: "integer", nullable: false),
                    SecondaryDoctorId = table.Column<int>(type: "integer", nullable: true),
                    ReceivedBy = table.Column<int>(type: "integer", nullable: true),
                    ReceivedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PatientBedInfo", x => x.PatientBedInfoId);
                    table.ForeignKey(
                        name: "FK_PatientBedInfo_ADT_MAP_WardBedType_BedId",
                        column: x => x.BedId,
                        principalTable: "ADT_MAP_WardBedType",
                        principalColumn: "BedId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_PatientBedInfo_ADT_MST_BedFeature_BedFeatureId",
                        column: x => x.BedFeatureId,
                        principalTable: "ADT_MST_BedFeature",
                        principalColumn: "BedFeatureId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_PatientBedInfo_ADT_MST_Ward_WardId",
                        column: x => x.WardId,
                        principalTable: "ADT_MST_Ward",
                        principalColumn: "WardId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_PatientBedInfo_AdmissionModel_PatientVisitId",
                        column: x => x.PatientVisitId,
                        principalTable: "AdmissionModel",
                        principalColumn: "PatientVisitId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ImagingReportModel",
                columns: table => new
                {
                    ImagingRequisitionId = table.Column<int>(type: "integer", nullable: false),
                    ImagingReportId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    PatientVisitId = table.Column<int>(type: "integer", nullable: true),
                    PatientId = table.Column<int>(type: "integer", nullable: false),
                    PrescriberName = table.Column<string>(type: "text", nullable: false),
                    ImagingTypeId = table.Column<int>(type: "integer", nullable: true),
                    ImagingTypeName = table.Column<string>(type: "text", nullable: false),
                    ImagingItemId = table.Column<int>(type: "integer", nullable: true),
                    ImagingItemName = table.Column<string>(type: "text", nullable: false),
                    ImageFullPath = table.Column<string>(type: "text", nullable: false),
                    ImageName = table.Column<string>(type: "text", nullable: false),
                    ReportText = table.Column<string>(type: "text", nullable: false),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    Signatories = table.Column<string>(type: "text", nullable: false),
                    OrderStatus = table.Column<string>(type: "text", nullable: false),
                    PrescriberId = table.Column<int>(type: "integer", nullable: true),
                    CreatedBy = table.Column<int>(type: "integer", nullable: true),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ReportTemplateId = table.Column<int>(type: "integer", nullable: true),
                    PatientStudyId = table.Column<string>(type: "text", nullable: false),
                    VisitPatientVisitId = table.Column<int>(type: "integer", nullable: false),
                    Indication = table.Column<string>(type: "text", nullable: false),
                    RadiologyNo = table.Column<string>(type: "text", nullable: false),
                    PerformerId = table.Column<int>(type: "integer", nullable: true),
                    PerformerName = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ImagingReportModel", x => x.ImagingRequisitionId);
                    table.ForeignKey(
                        name: "FK_ImagingReportModel_ImagingRequisitionModel_ImagingRequisiti~",
                        column: x => x.ImagingRequisitionId,
                        principalTable: "ImagingRequisitionModel",
                        principalColumn: "ImagingRequisitionId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ImagingReportModel_PAT_Patient_PatientId",
                        column: x => x.PatientId,
                        principalTable: "PAT_Patient",
                        principalColumn: "PatientId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ImagingReportModel_VisitModel_VisitPatientVisitId",
                        column: x => x.VisitPatientVisitId,
                        principalTable: "VisitModel",
                        principalColumn: "PatientVisitId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ClinicalDiagnosisModel",
                columns: table => new
                {
                    DiagnosisId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    NotesId = table.Column<int>(type: "integer", nullable: false),
                    PatientId = table.Column<int>(type: "integer", nullable: false),
                    PatientVisitId = table.Column<int>(type: "integer", nullable: false),
                    ICD10ID = table.Column<int>(type: "integer", nullable: false),
                    ICD10Description = table.Column<string>(type: "text", nullable: false),
                    ICD10Code = table.Column<string>(type: "text", nullable: false),
                    CreatedBy = table.Column<int>(type: "integer", nullable: true),
                    ModifiedBy = table.Column<int>(type: "integer", nullable: true),
                    CreatedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ModifiedOn = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    IsActive = table.Column<bool>(type: "boolean", nullable: true),
                    NotesModelNotesId = table.Column<int>(type: "integer", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ClinicalDiagnosisModel", x => x.DiagnosisId);
                    table.ForeignKey(
                        name: "FK_ClinicalDiagnosisModel_NotesModel_NotesModelNotesId",
                        column: x => x.NotesModelNotesId,
                        principalTable: "NotesModel",
                        principalColumn: "NotesId");
                });

            migrationBuilder.CreateIndex(
                name: "IX_ActiveMedicalProblem_PatientId",
                table: "ActiveMedicalProblem",
                column: "PatientId");

            migrationBuilder.CreateIndex(
                name: "IX_AddressModel_PatientId",
                table: "AddressModel",
                column: "PatientId");

            migrationBuilder.CreateIndex(
                name: "IX_AdmissionModel_PatientModelPatientId",
                table: "AdmissionModel",
                column: "PatientModelPatientId");

            migrationBuilder.CreateIndex(
                name: "IX_ADT_MAP_BedFeaturesMap_BedFeatureId",
                table: "ADT_MAP_BedFeaturesMap",
                column: "BedFeatureId");

            migrationBuilder.CreateIndex(
                name: "IX_ADT_MAP_BedFeaturesMap_BedId",
                table: "ADT_MAP_BedFeaturesMap",
                column: "BedId");

            migrationBuilder.CreateIndex(
                name: "IX_ADT_MAP_BedFeaturesMap_WardId",
                table: "ADT_MAP_BedFeaturesMap",
                column: "WardId");

            migrationBuilder.CreateIndex(
                name: "IX_ADT_MAP_WardBedType_WardId",
                table: "ADT_MAP_WardBedType",
                column: "WardId");

            migrationBuilder.CreateIndex(
                name: "IX_AllergyModel_PatientId",
                table: "AllergyModel",
                column: "PatientId");

            migrationBuilder.CreateIndex(
                name: "IX_BIL_MST_ServiceDepartment_DepartmentId",
                table: "BIL_MST_ServiceDepartment",
                column: "DepartmentId");

            migrationBuilder.CreateIndex(
                name: "IX_BIL_MST_ServiceItem_ServiceDepartmentModelServiceDepartment~",
                table: "BIL_MST_ServiceItem",
                column: "ServiceDepartmentModelServiceDepartmentId");

            migrationBuilder.CreateIndex(
                name: "IX_ClinicalDiagnosisModel_NotesModelNotesId",
                table: "ClinicalDiagnosisModel",
                column: "NotesModelNotesId");

            migrationBuilder.CreateIndex(
                name: "IX_EMP_Employee_DepartmentId",
                table: "EMP_Employee",
                column: "DepartmentId");

            migrationBuilder.CreateIndex(
                name: "IX_EMP_Employee_EmployeeRoleId",
                table: "EMP_Employee",
                column: "EmployeeRoleId");

            migrationBuilder.CreateIndex(
                name: "IX_EMP_Employee_EmployeeTypeId",
                table: "EMP_Employee",
                column: "EmployeeTypeId");

            migrationBuilder.CreateIndex(
                name: "IX_FamilyHistory_PatientId",
                table: "FamilyHistory",
                column: "PatientId");

            migrationBuilder.CreateIndex(
                name: "IX_HomeMedicationModel_PatientId",
                table: "HomeMedicationModel",
                column: "PatientId");

            migrationBuilder.CreateIndex(
                name: "IX_ImagingReportModel_PatientId",
                table: "ImagingReportModel",
                column: "PatientId");

            migrationBuilder.CreateIndex(
                name: "IX_ImagingReportModel_VisitPatientVisitId",
                table: "ImagingReportModel",
                column: "VisitPatientVisitId");

            migrationBuilder.CreateIndex(
                name: "IX_ImagingRequisitionModel_ImagingItemId",
                table: "ImagingRequisitionModel",
                column: "ImagingItemId");

            migrationBuilder.CreateIndex(
                name: "IX_ImagingRequisitionModel_PatientId",
                table: "ImagingRequisitionModel",
                column: "PatientId");

            migrationBuilder.CreateIndex(
                name: "IX_ImagingRequisitionModel_VisitPatientVisitId",
                table: "ImagingRequisitionModel",
                column: "VisitPatientVisitId");

            migrationBuilder.CreateIndex(
                name: "IX_InputOutputModel_VisitPatientVisitId",
                table: "InputOutputModel",
                column: "VisitPatientVisitId");

            migrationBuilder.CreateIndex(
                name: "IX_InsuranceModel_PatientId",
                table: "InsuranceModel",
                column: "PatientId");

            migrationBuilder.CreateIndex(
                name: "IX_KinModel_PatientId",
                table: "KinModel",
                column: "PatientId");

            migrationBuilder.CreateIndex(
                name: "IX_LabRequisitionModel_LabTestId",
                table: "LabRequisitionModel",
                column: "LabTestId");

            migrationBuilder.CreateIndex(
                name: "IX_LabRequisitionModel_PatientId",
                table: "LabRequisitionModel",
                column: "PatientId");

            migrationBuilder.CreateIndex(
                name: "IX_LabTestComponentResult_LabRequisitionRequisitionId",
                table: "LabTestComponentResult",
                column: "LabRequisitionRequisitionId");

            migrationBuilder.CreateIndex(
                name: "IX_LabTestModel_LabReportTemplateReportTemplateID",
                table: "LabTestModel",
                column: "LabReportTemplateReportTemplateID");

            migrationBuilder.CreateIndex(
                name: "IX_MedicationPrescriptionModel_PatientId",
                table: "MedicationPrescriptionModel",
                column: "PatientId");

            migrationBuilder.CreateIndex(
                name: "IX_NotesModel_PatientModelPatientId",
                table: "NotesModel",
                column: "PatientModelPatientId");

            migrationBuilder.CreateIndex(
                name: "IX_NotesModel_VisitModelPatientVisitId",
                table: "NotesModel",
                column: "VisitModelPatientVisitId");

            migrationBuilder.CreateIndex(
                name: "IX_PastMedicalProblem_PatientId",
                table: "PastMedicalProblem",
                column: "PatientId");

            migrationBuilder.CreateIndex(
                name: "IX_PAT_Patient_CountrySubDivisionId",
                table: "PAT_Patient",
                column: "CountrySubDivisionId");

            migrationBuilder.CreateIndex(
                name: "IX_PatientBedInfo_BedFeatureId",
                table: "PatientBedInfo",
                column: "BedFeatureId");

            migrationBuilder.CreateIndex(
                name: "IX_PatientBedInfo_BedId",
                table: "PatientBedInfo",
                column: "BedId");

            migrationBuilder.CreateIndex(
                name: "IX_PatientBedInfo_PatientVisitId",
                table: "PatientBedInfo",
                column: "PatientVisitId");

            migrationBuilder.CreateIndex(
                name: "IX_PatientBedInfo_WardId",
                table: "PatientBedInfo",
                column: "WardId");

            migrationBuilder.CreateIndex(
                name: "IX_PatientFilesModel_PatientModelPatientId",
                table: "PatientFilesModel",
                column: "PatientModelPatientId");

            migrationBuilder.CreateIndex(
                name: "IX_PHRM_MAP_MstItemsPriceCategory_GenericId",
                table: "PHRM_MAP_MstItemsPriceCategory",
                column: "GenericId");

            migrationBuilder.CreateIndex(
                name: "IX_PHRM_MAP_MstItemsPriceCategory_ItemsItemId",
                table: "PHRM_MAP_MstItemsPriceCategory",
                column: "ItemsItemId");

            migrationBuilder.CreateIndex(
                name: "IX_RAD_MST_ImagingItem_ImagingTypesImagingTypeId",
                table: "RAD_MST_ImagingItem",
                column: "ImagingTypesImagingTypeId");

            migrationBuilder.CreateIndex(
                name: "IX_SocialHistory_PatientId",
                table: "SocialHistory",
                column: "PatientId");

            migrationBuilder.CreateIndex(
                name: "IX_SurgicalHistory_PatientId",
                table: "SurgicalHistory",
                column: "PatientId");

            migrationBuilder.CreateIndex(
                name: "IX_VisitModel_PatientId",
                table: "VisitModel",
                column: "PatientId");

            migrationBuilder.CreateIndex(
                name: "IX_VitalsModel_VisitPatientVisitId",
                table: "VitalsModel",
                column: "VisitPatientVisitId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ActiveMedicalProblem");

            migrationBuilder.DropTable(
                name: "AddressModel");

            migrationBuilder.DropTable(
                name: "ADT_MAP_BedFeaturesMap");

            migrationBuilder.DropTable(
                name: "AllergyModel");

            migrationBuilder.DropTable(
                name: "BIL_CFG_PriceCategory");

            migrationBuilder.DropTable(
                name: "BIL_MAP_PriceCategoryServiceItem");

            migrationBuilder.DropTable(
                name: "BIL_MST_Credit_Organization");

            migrationBuilder.DropTable(
                name: "BIL_MST_ServiceItem");

            migrationBuilder.DropTable(
                name: "CFG_PaymentModeSettings");

            migrationBuilder.DropTable(
                name: "CFG_PrintExportSettings");

            migrationBuilder.DropTable(
                name: "ClinicalDiagnosisModel");

            migrationBuilder.DropTable(
                name: "CORE_CFG_Parameters");

            migrationBuilder.DropTable(
                name: "CORE_LookupDetail");

            migrationBuilder.DropTable(
                name: "EMP_Employee");

            migrationBuilder.DropTable(
                name: "EMP_EmployeePreferences");

            migrationBuilder.DropTable(
                name: "FamilyHistory");

            migrationBuilder.DropTable(
                name: "GuarantorModel");

            migrationBuilder.DropTable(
                name: "HomeMedicationModel");

            migrationBuilder.DropTable(
                name: "ICD_DiseaseGroup");

            migrationBuilder.DropTable(
                name: "ICD_ReportingGroup");

            migrationBuilder.DropTable(
                name: "ImagingReportModel");

            migrationBuilder.DropTable(
                name: "InputOutputModel");

            migrationBuilder.DropTable(
                name: "InsuranceModel");

            migrationBuilder.DropTable(
                name: "KinModel");

            migrationBuilder.DropTable(
                name: "LabTestComponentResult");

            migrationBuilder.DropTable(
                name: "MedicationPrescriptionModel");

            migrationBuilder.DropTable(
                name: "MST_Bank");

            migrationBuilder.DropTable(
                name: "MST_Country");

            migrationBuilder.DropTable(
                name: "MST_ICD10");

            migrationBuilder.DropTable(
                name: "MST_MAP_StoreVerification");

            migrationBuilder.DropTable(
                name: "MST_Municipality");

            migrationBuilder.DropTable(
                name: "MST_PaymentModes");

            migrationBuilder.DropTable(
                name: "MST_PaymentPages");

            migrationBuilder.DropTable(
                name: "MST_Reactions");

            migrationBuilder.DropTable(
                name: "MST_Tax");

            migrationBuilder.DropTable(
                name: "MSTEmailSendDetail");

            migrationBuilder.DropTable(
                name: "NUR_MAP_WardSubStoresMap");

            migrationBuilder.DropTable(
                name: "PastMedicalProblem");

            migrationBuilder.DropTable(
                name: "PatientBedInfo");

            migrationBuilder.DropTable(
                name: "PatientFilesModel");

            migrationBuilder.DropTable(
                name: "PHRM_MAP_MstItemsPriceCategory");

            migrationBuilder.DropTable(
                name: "PHRM_MST_Credit_Organization");

            migrationBuilder.DropTable(
                name: "PHRM_MST_Store");

            migrationBuilder.DropTable(
                name: "ServiceDepartment_MST_IntegrationName");

            migrationBuilder.DropTable(
                name: "SocialHistory");

            migrationBuilder.DropTable(
                name: "SurgicalHistory");

            migrationBuilder.DropTable(
                name: "VitalsModel");

            migrationBuilder.DropTable(
                name: "BIL_MST_ServiceDepartment");

            migrationBuilder.DropTable(
                name: "NotesModel");

            migrationBuilder.DropTable(
                name: "EMP_EmployeeRole");

            migrationBuilder.DropTable(
                name: "EMP_EmployeeType");

            migrationBuilder.DropTable(
                name: "ImagingRequisitionModel");

            migrationBuilder.DropTable(
                name: "LabRequisitionModel");

            migrationBuilder.DropTable(
                name: "ADT_MAP_WardBedType");

            migrationBuilder.DropTable(
                name: "ADT_MST_BedFeature");

            migrationBuilder.DropTable(
                name: "AdmissionModel");

            migrationBuilder.DropTable(
                name: "PHRMGenericModel");

            migrationBuilder.DropTable(
                name: "PHRM_MST_Item");

            migrationBuilder.DropTable(
                name: "MST_Department");

            migrationBuilder.DropTable(
                name: "RAD_MST_ImagingItem");

            migrationBuilder.DropTable(
                name: "LabTestModel");

            migrationBuilder.DropTable(
                name: "ADT_MST_Ward");

            migrationBuilder.DropTable(
                name: "VisitModel");

            migrationBuilder.DropTable(
                name: "RAD_MST_ImagingType");

            migrationBuilder.DropTable(
                name: "LabReportTemplateModel");

            migrationBuilder.DropTable(
                name: "PAT_Patient");

            migrationBuilder.DropTable(
                name: "MST_CountrySubDivision");
        }
    }
}
