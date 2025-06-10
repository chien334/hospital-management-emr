using DanpheEMR.ServerModel;
using DanpheEMR.ServerModel.ReportingModels;
using DanpheEMR.ServerModel.SystemAdminModels;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.Data.SqlClient;
using Newtonsoft.Json;
using Newtonsoft.Json.Converters;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Common;
using System.Linq;
using System.Reflection;
using Microsoft.EntityFrameworkCore;

namespace DanpheEMR.DalLayer
{
    public class ReportingDbContext : DbContext
    {
         private readonly DbContextOptions<ReportingDbContext> _options;
        public ReportingDbContext(DbContextOptions<ReportingDbContext> options) : base(options)
        {
            _options = options;
        }

        #region Doctor Report
        public DataTable DoctorReport(DateTime FromDate, DateTime ToDate, string ProviderName)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() { new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate), new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate) };
            if (ProviderName != null)
            {
                var providerParameter = new Microsoft.Data.SqlClient.SqlParameter("@ProviderName", ProviderName);
                paramList.Add(providerParameter);
            }
            DataTable doctorReportData = DALFunctions.GetDataTableFromStoredProc("SP_Report_BIL_DoctorReport", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return doctorReportData;
        }
        #endregion

        #region Doctor Revenue Report        
        public DataTable DoctorRevenue(DateTime FromDate, DateTime ToDate, string PerformerName)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() { new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate), new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate) };
            if (PerformerName != null)
            {
                SqlParameter providerParameter = new SqlParameter("@PerformerName", PerformerName);
                paramList.Add(providerParameter);
            }
            DataTable doctorRevenue = DALFunctions.GetDataTableFromStoredProc("SP_Report_BIL_DoctorRevenue", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return doctorRevenue;
        }
        #endregion

        #region BilDenomination Report        
        public DataTable BilDenomination(DateTime FromDate, DateTime ToDate, int UserId)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() { new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate), new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate) };
            if (UserId != 0)
            {
                SqlParameter providerParameter = new SqlParameter("@UserId", UserId);
                paramList.Add(providerParameter);
            }
            DataTable billdenomination = DALFunctions.GetDataTableFromStoredProc("SP_Report_Bill_BillDenomination", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return billdenomination;
        }
        #endregion

        #region BilDenomination All Report        
        public DataTable BilDenominationAllList(DateTime FromDate, DateTime ToDate)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate)
            };
            //SqlParameter providerParameter = new SqlParameter();
            //paramList.Add(providerParameter);
            DataTable billdenomination = DALFunctions.GetDataTableFromStoredProc("SP_Report_Bill_BillDenominationAllList", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return billdenomination;
        }

        #endregion
        #region Doctor Summary Report        
        public DataTable DoctorSummary(DateTime FromDate, DateTime ToDate, int ProviderId)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() { new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate), new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate) };
            if (ProviderId != 0)
            {
                SqlParameter providerParameter = new SqlParameter("@ProviderId", ProviderId);
                paramList.Add(providerParameter);
            }
            DataTable doctorSummary = DALFunctions.GetDataTableFromStoredProc("SP_Report_DOC_DoctorSummary", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return doctorSummary;
        }
        #endregion

        #region Deposit Balance Report
        public DataTable DepositBalanceReport()
        {
            DataTable depositBalanceRptData = DALFunctions.GetDataTableFromStoredProc("SP_Report_Deposit_Balance", (Microsoft.EntityFrameworkCore.DbContext)this);
            return depositBalanceRptData;
        }
        #endregion        

        #region Daily Sales Report
        public DynamicReport DailySalesReport(DateTime FromDate, DateTime ToDate, int? CounterId, string CreatedBy, bool? IsInsurance)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() {  new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                            new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate),
                            new Microsoft.Data.SqlClient.SqlParameter("@CounterId", CounterId),
                            new Microsoft.Data.SqlClient.SqlParameter("@CreatedBy", CreatedBy == null ? string.Empty : CreatedBy),
                             new Microsoft.Data.SqlClient.SqlParameter("@IsInsurance", IsInsurance) };

            DataSet dataSet = DALFunctions.GetDatasetFromStoredProc("SP_Report_BIL_DailySales", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            DynamicReport dReport = new DynamicReport();
            if (dataSet.Tables.Count > 0)
            {
                var data = new
                {
                    SalesData = dataSet.Tables[0],
                    SettlementData = dataSet.Tables[1]//sud:7Aug'18
                };
                dReport.Schema = null;
                dReport.JsonData = JsonConvert.SerializeObject(data);
            }
            return dReport;
        }
        #endregion

        public DataTable DiscountReport(DateTime FromDate, DateTime ToDate, int? CounterId, int? CreatedBy)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() {  new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                            new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate),
                            new Microsoft.Data.SqlClient.SqlParameter("@CounterId", CounterId),
                            new Microsoft.Data.SqlClient.SqlParameter("@CreatedBy", CreatedBy) };
            DataTable discountReportData = DALFunctions.GetDataTableFromStoredProc("SP_Report_Discount", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return discountReportData;
        }

        public DataTable SchemeWiseDiscountReport(DateTime FromDate, DateTime ToDate, int SchemeId)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() {  new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                            new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate),
                            new Microsoft.Data.SqlClient.SqlParameter("@SchemeId", SchemeId) };
            DataTable discountReportData = DALFunctions.GetDataTableFromStoredProc("SP_Report_SchemeWiseDiscountReport", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return discountReportData;
        }
        public DataTable DepartmentWiseDiscountSchemeReport(DateTime FromDate, DateTime ToDate, object MembershipTypeId, object ServiceDepartmentId, object PaymentMode)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() {  new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                            new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate),
                            new Microsoft.Data.SqlClient.SqlParameter("@MembershipTypeId", (MembershipTypeId != null) ? MembershipTypeId : DBNull.Value),
                            new Microsoft.Data.SqlClient.SqlParameter("@ServiceDepartmentId", (ServiceDepartmentId != null) ? ServiceDepartmentId : DBNull.Value),
                            new Microsoft.Data.SqlClient.SqlParameter("@PaymentMode", (PaymentMode != null) ? PaymentMode : DBNull.Value)
                            };
            DataTable discountReportData = DALFunctions.GetDataTableFromStoredProc("SP_Report_DepartmentWiseDiscountSchemeReport", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return discountReportData;
        }

        public DataTable ItemLevelDepartmentWiseDiscountSchemeReport(object BillingTransactionId, object MembershipTypeId, object ServiceDepartmentId)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() {
                            new Microsoft.Data.SqlClient.SqlParameter("@BillingTransactionId", (BillingTransactionId != null) ? BillingTransactionId : DBNull.Value),
                            new Microsoft.Data.SqlClient.SqlParameter("@MembershipTypeId", (MembershipTypeId != null) ? MembershipTypeId : DBNull.Value),
                            new Microsoft.Data.SqlClient.SqlParameter("@ServiceDepartmentId", (ServiceDepartmentId != null) ? ServiceDepartmentId : DBNull.Value),
                            };
            DataTable itemLevelReportData = DALFunctions.GetDataTableFromStoredProc("SP_Report_ItemLevelDepartmentWiseDiscountSchemeReport", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return itemLevelReportData;
        }

        #region Daily MIS Report
        public DynamicReport DailyMISReport(DateTime FromDate, DateTime ToDate)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() { new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate), new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate) };
            DataSet dataSet = DALFunctions.GetDatasetFromStoredProc("SP_Report_BILL_DailyMISReport", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            DynamicReport dReport = new DynamicReport();
            if (dataSet.Tables.Count > 1)
            {
                var data = new
                {
                    ReportData = dataSet.Tables[0],
                    OPDData = dataSet.Tables[1],
                    HealthCardData = dataSet.Tables[2],
                    LabData = dataSet.Tables[3],
                    RadiologyData = dataSet.Tables[4],
                    HealthClinicData = dataSet.Tables[5],
                    OTData = dataSet.Tables[6],
                    LaborData = dataSet.Tables[7],
                    IPDData = dataSet.Tables[8],
                    OtherServiceDept = dataSet.Tables[9],
                    PharmacyData = dataSet.Tables[10]
                };
                dReport.Schema = null;
                dReport.JsonData = JsonConvert.SerializeObject(data);
            }
            return dReport;
            //DataTable dailyMISData = DALFunctions.GetDataTableFromStoredProc("SP_Report_BILL_DailyMISReport", paramList, this);
            //return dailyMISData;
        }
        public DataTable DoctorPatientCount(DateTime FromDate, DateTime ToDate)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() { new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate), new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate) };
            DataTable drPatCount = DALFunctions.GetDataTableFromStoredProc("SP_Report_BIL_DailyMISDrPatientCount", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return drPatCount;
        }
        #endregion
        #region BillDocSummaryReport
        public DataTable BillDocSummary(DateTime FromDate, DateTime ToDate)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() { new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate), new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate) };
            DataTable dtBilDocSummary = DALFunctions.GetDataTableFromStoredProc("SP_Report_BIL_DoctorSummary", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);

            return dtBilDocSummary;
        }
        #endregion


        #region BillDocDeptSummary
        public DataTable BillDocDeptSummary(DateTime FromDate, DateTime ToDate, int DoctorId)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate),
                new Microsoft.Data.SqlClient.SqlParameter("@DoctorId", DoctorId)
            };
            DataTable dtDoctorDeptSummary = DALFunctions.GetDataTableFromStoredProc("SP_Report_BIL_DoctorDeptSummary", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);

            return dtDoctorDeptSummary;
        }
        #endregion
        #region BillDocDeptItemSummary
        public DataTable BillDocDeptItemSummary(DateTime FromDate, DateTime ToDate, int DoctorId, string SrvDeptName)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate),
                new Microsoft.Data.SqlClient.SqlParameter("@DoctorId", DoctorId),
                new Microsoft.Data.SqlClient.SqlParameter("@SrvDeptName", SrvDeptName)
            };
            DataTable rData = DALFunctions.GetDataTableFromStoredProc("SP_Report_BIL_DoctorDeptItemsSummary", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            //DynamicReport dReport = new DynamicReport();
            //if (rData.Tables.Count > 1)
            //{
            //    var data = new
            //    {
            //        ReportData = rData.Tables[0],
            //        Summary = rData.Tables[1]
            //    };
            //    dReport.Schema = null;
            //    dReport.JsonData = JsonConvert.SerializeObject(data);
            //}
            return rData;
        }
        #endregion

        #region Bill- Department Summary report
        public DynamicReport BillDepartmentSummary(DateTime FromDate, DateTime ToDate)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate)
            };
            DataSet rData = DALFunctions.GetDatasetFromStoredProc("SP_Report_BIL_DepartmentSummary", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            DynamicReport dReport = new DynamicReport();
            if (rData.Tables.Count > 1)
            {
                var data = new
                {
                    ReportData = rData.Tables[0],
                    Summary = rData.Tables[1]
                };
                dReport.Schema = null;
                dReport.JsonData = JsonConvert.SerializeObject(data);
            }
            return dReport;
        }
        #endregion
        #region Department Revenue Report
        public DynamicReport DepartmentRevenueReport(DateTime FromDate, DateTime ToDate)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() { new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate), new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate) };
            DataSet dataSet = DALFunctions.GetDatasetFromStoredProc("SP_Report_BIL_DepartmentRevenue", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            DynamicReport dReport = new DynamicReport();
            if (dataSet.Tables.Count > 0)
            {
                var data = new
                {
                    ReportData = dataSet.Tables[0]
                };
                dReport.Schema = null;
                dReport.JsonData = JsonConvert.SerializeObject(data);
            }
            return dReport;
        }
        #endregion
        #region BillDeptItemSummary
        public DynamicReport BillDeptItemSummary(DateTime FromDate, DateTime ToDate, string SrvDeptName)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate),
                new Microsoft.Data.SqlClient.SqlParameter("@SrvDeptName",SrvDeptName)
            };
            DataSet rData = DALFunctions.GetDatasetFromStoredProc("SP_Report_BIL_DepartmentItemSummary", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            DynamicReport dReport = new DynamicReport();
            if (rData.Tables.Count > 1)
            {
                var data = new
                {
                    ReportData = rData.Tables[0],
                    Summary = rData.Tables[1]
                };
                dReport.Schema = null;
                dReport.JsonData = JsonConvert.SerializeObject(data);
            }
            return dReport;
        }
        #endregion
        #region Service Department Names (list of srvDeptNames from Function)
        public DataTable LoadServDeptsNameFromFN()
        {
            DataTable servDeptsName = DALFunctions.GetDataTableFromStoredProc("SP_BILL_GetServiceDepartmentsName", (Microsoft.EntityFrameworkCore.DbContext)this);
            return servDeptsName;
        }
        #endregion

        public DynamicReport CustomReport(DateTime FromDate, DateTime ToDate, string ReportName)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ReportName", ReportName) };
            DataSet customReportData = DALFunctions.GetDatasetFromStoredProc("SP_Report_BILL_CustomReport", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            DynamicReport dReport = new DynamicReport();
            if (customReportData.Tables.Count > 1)
            {
                var data = new
                {
                    PatientCount = customReportData.Tables[0],
                    Data = customReportData.Tables[1]
                };
                dReport.Schema = null;
                dReport.JsonData = JsonConvert.SerializeObject(data);
            }
            return dReport;
        }

        #region Doctorwise OutPatient Report
        public DataTable DoctorWisePatientReport(DateTime fromDate, DateTime toDate)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() { new Microsoft.Data.SqlClient.SqlParameter("@FromDate", fromDate), new Microsoft.Data.SqlClient.SqlParameter("@ToDate", toDate) };
            DataTable reportTable = DALFunctions.GetDataTableFromStoredProc("SP_Report_Appointment_DoctorWiseOutPatientReport", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return reportTable;
        }
        #endregion

        #region DoctorwiseIncomeSummaryOpIpReport
        public DynamicReport DoctorwiseIncomeSummaryOpIpReport(DateTime fromDate, DateTime toDate, int? PerformerId)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", fromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", toDate),
                new Microsoft.Data.SqlClient.SqlParameter("@PerformerId", PerformerId)
            };
            DataSet rData = DALFunctions.GetDatasetFromStoredProc("SP_Report_BILL_DoctorWiseIncomeSummary_OPIP", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            DynamicReport dReport = new DynamicReport();
            if (rData.Tables.Count > 1)
            {
                var data = new
                {
                    ReportData = rData.Tables[0],
                    Summary = rData.Tables[1]
                };
                dReport.Schema = null;
                dReport.JsonData = JsonConvert.SerializeObject(data);
            }
            return dReport;
        }
        #endregion

        #region Total Item Bill Report
        public DataTable TotalItemsBill(DateTime FromDate, DateTime ToDate, string billingType, string ServiceDepartmentName, string ItemName)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() {  new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                           new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate),
                           new Microsoft.Data.SqlClient.SqlParameter("@billingType", billingType),
                           new Microsoft.Data.SqlClient.SqlParameter("@ServiceDepartmentName", ServiceDepartmentName == null ? string.Empty : ServiceDepartmentName),
                           new Microsoft.Data.SqlClient.SqlParameter("@ItemName", ItemName == null ? string.Empty : ItemName)};

            DataTable totalItemBillData = DALFunctions.GetDataTableFromStoredProc("SP_Report_BILL_TotalItemsBill", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return totalItemBillData;
        }
        #endregion
        #region EHS Bill Report
        public DataTable EHSBillReport(DateTime FromDate, DateTime ToDate, string ServiceDepartmentName, string ItemName, int? PerformerId, int? PrescriberId, int? UserId)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() {  new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                           new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate),
                           new Microsoft.Data.SqlClient.SqlParameter("@ServiceDepartmentName", ServiceDepartmentName == null ? string.Empty : ServiceDepartmentName),
                           new Microsoft.Data.SqlClient.SqlParameter("@ItemName", ItemName == null ? string.Empty : ItemName),
                           new Microsoft.Data.SqlClient.SqlParameter("@PerformerId", PerformerId),
                           new Microsoft.Data.SqlClient.SqlParameter("@PrescriberId", PrescriberId),
                           new Microsoft.Data.SqlClient.SqlParameter("@UserId", UserId)
            };

            DataTable totalItemBillData = DALFunctions.GetDataTableFromStoredProc("SP_RPT_Bil_EHSBillingReport", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return totalItemBillData;
        }
        #endregion
        #region Daily Sales Book
        public DataTable SalesDaybook(DateTime FromDate, DateTime ToDate, bool IsInsurance)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() { new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate)
                , new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate) , new Microsoft.Data.SqlClient.SqlParameter("@IsInsurance", IsInsurance)};

            DataTable salesDaybookData = DALFunctions.GetDataTableFromStoredProc("SP_Report_BILL_SalesDaybook", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return salesDaybookData;
        }
        #endregion

        #region PatientCensusReport
        public DynamicReport PatientCensusReport(DateTime FromDate, DateTime ToDate, int? ProviderId, int? DepartmentId)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate),
                new Microsoft.Data.SqlClient.SqlParameter("@PerformerId",ProviderId),
                new Microsoft.Data.SqlClient.SqlParameter("@DepartmentId",DepartmentId)
            };
            DataSet patientCensusData = DALFunctions.GetDatasetFromStoredProc("SP_Report_BILL_PatientCensus", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            DynamicReport dReport = new DynamicReport();
            if (patientCensusData.Tables.Count > 1)
            {
                var data = new
                {
                    ReportData = patientCensusData.Tables[0],
                    Summary = patientCensusData.Tables[1]
                };
                dReport.Schema = null;
                dReport.JsonData = JsonConvert.SerializeObject(data);
            }
            return dReport;
        }
        #endregion

        #region Department Sales Daybook
        public DataTable DepartmentSalesDaybook(DateTime FromDate, DateTime ToDate, bool IsInsurance)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate),
                new Microsoft.Data.SqlClient.SqlParameter("@IsInsurance", IsInsurance) };

            DataTable deptSalesDaybookData = DALFunctions.GetDataTableFromStoredProc("SP_Report_BILL_DepartmentSalesDaybook", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return deptSalesDaybookData;
        }
        #endregion

        #region Patient Neighbourhood Card Details Report
        public DataTable PatientNeighbourhoodCardDetail(DateTime FromDate, DateTime ToDate)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate) };
            DataTable patneighbourcardData = DALFunctions.GetDataTableFromStoredProc("SP_Report_BIL_PAT_NeighbourhoodCardDetail", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return patneighbourcardData;
        }
        #endregion
        #region Package Sales Detail Report
        public DataTable PackageSalesDetail(DateTime FromDate, DateTime ToDate)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate) };
            DataTable patneighbourcardData = DALFunctions.GetDataTableFromStoredProc("SP_Report_BIL_PAT_PackageSalesDetail", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return patneighbourcardData;
        }
        #endregion

        #region Dialysis Patient Details Report
        public DataTable DialysisPatientDetail(DateTime FromDate, DateTime ToDate)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate)
                };

            DataTable dialysispatientData = DALFunctions.GetDataTableFromStoredProc("SP_Report_BIL_DialysisPatientDetail", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return dialysispatientData;
        }
        #endregion

        #region Patient Bill History
        public PatientBillHistoryMaster PatientBillHistory(DateTime? FromDate, DateTime? ToDate, string PatientCode)
        {

            DataSet dsPatBillHistories = GetPatientBillHistory2(FromDate, ToDate, PatientCode, connStr);

            PatientBillHistoryMaster retVal = new PatientBillHistoryMaster();

            retVal.paidBill = ConvertDataTable<PaidBillHistory>(dsPatBillHistories.Tables[0]);
            retVal.unpaidBill = ConvertDataTable<UnpaidBillHistory>(dsPatBillHistories.Tables[1]);
            retVal.returnBill = ConvertDataTable<ReturnedBillHistory>(dsPatBillHistories.Tables[2]);
            retVal.deposits = ConvertDataTable<Deposit>(dsPatBillHistories.Tables[3]);
            retVal.cancelBill = ConvertDataTable<CancelBillHistory>(dsPatBillHistories.Tables[4]);
            return retVal;
        }

        private DataSet GetPatientBillHistory2(DateTime? FromDate, DateTime? ToDate, string PatientCode, string connString)
        {
            // creates resulting dataset
            var result = new DataSet();
            var context = new ReportingDbContext(_options);


            // creates a Command 
            var cmd = context.Database.GetDbConnection().CreateCommand();
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.CommandText = "SP_Report_BILL_PatientBillHistory";
            cmd.Parameters.Add(new SqlParameter("@FromDate", FromDate));
            cmd.Parameters.Add(new SqlParameter("@ToDate", ToDate));
            cmd.Parameters.Add(new SqlParameter("@PatientCode", PatientCode));



            try
            {
                // executes
                if (context.Database.GetDbConnection().State == ConnectionState.Closed)
                {
                    context.Database.GetDbConnection().Open();
                    var reader = cmd.ExecuteReader();

                    // loop through all resultsets (considering that it's possible to have more than one)
                    do
                    {
                        // loads the DataTable (schema will be fetch automatically)
                        var tb = new DataTable();
                        tb.Load(reader);
                        result.Tables.Add(tb);

                    } while (!reader.IsClosed);

                    return result;
                }
                return null;
            }
            finally
            {
                // closes the connection
                context.Database.GetDbConnection().Close();
            }
        }

        private static List<T> ConvertDataTable<T>(DataTable dt)
        {
            List<T> data = new List<T>();
            foreach (DataRow row in dt.Rows)
            {
                T item = GetItem<T>(row);
                data.Add(item);
            }
            return data;
        }
        private static T GetItem<T>(DataRow dr)
        {
            Type temp = typeof(T);
            T obj = Activator.CreateInstance<T>();

            foreach (DataColumn column in dr.Table.Columns)
            {
                foreach (PropertyInfo pro in temp.GetProperties())
                {
                    //If current value is DBNull.Value then set it to null (C# wala NULL)... 
                    if (pro.Name == column.ColumnName)
                        pro.SetValue(obj, dr[column.ColumnName] == DBNull.Value ? null : dr[column.ColumnName], null);
                    else
                        continue;
                }
            }
            return obj;
        }
        #endregion

        #region Daily Appointment Report
        public DataTable DailyAppointmentReport(DateTime FromDate, DateTime ToDate, string Doctor_Name, string AppointmentType)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate),
                new Microsoft.Data.SqlClient.SqlParameter("@Doctor_Name", Doctor_Name),
                new Microsoft.Data.SqlClient.SqlParameter("@AppointmentType", AppointmentType)
            };
            DataTable dailyAppointmentRptData = DALFunctions.GetDataTableFromStoredProc("SP_Report_Appointment_DailyAppointmentReport", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return dailyAppointmentRptData;
        }
        #endregion

        #region Rankwise Daily Appointment Report
        public DataTable RankwiseDailyAppointmentReport(DateTime FromDate, DateTime ToDate, string Rank, string Membership, string AppointmentType)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate),
                new Microsoft.Data.SqlClient.SqlParameter("@Rank", Rank),
                new Microsoft.Data.SqlClient.SqlParameter("@Membership", Membership),
                new Microsoft.Data.SqlClient.SqlParameter("@AppointmentType", AppointmentType)
            };
            DataTable dailyAppointmentRptData = DALFunctions.GetDataTableFromStoredProc("SP_Report_Appointment_RankwiseDailyAppointmentReport", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return dailyAppointmentRptData;
        }
        #endregion

        #region PhoneBook Appointment Report
        public DataTable PhoneBookAppointmentReport(DateTime FromDate, DateTime ToDate, string Doctor_Name, string AppointmentStatus)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate),
                new Microsoft.Data.SqlClient.SqlParameter("@Doctor_Name", Doctor_Name),
                new Microsoft.Data.SqlClient.SqlParameter("@AppointmentStatus", AppointmentStatus)
            };
            DataTable phonebookAppointmentRptData = DALFunctions.GetDataTableFromStoredProc("SP_Report_Appointment_PhoneBookAppointmentReport", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return phonebookAppointmentRptData;
        }
        #endregion
        #region Diagnosis Wise Patient Report 
        public DataTable DiagnosisWisePatientReport(DateTime FromDate, DateTime ToDate, string Diagnosis)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate),
                new Microsoft.Data.SqlClient.SqlParameter("@Diagnosis", Diagnosis)
            };
            DataTable diagnosiswisePtReportData = DALFunctions.GetDataTableFromStoredProc("SP_Report_ADT_DiagnosisWiseReport", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return diagnosiswisePtReportData;
        }
        #endregion
        #region Get Billing IncomeSegregation Report
        public DataTable Get_Bill_IncomeSegregationStaticReport(DateTime FromDate, DateTime ToDate, string billingType)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() { new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate), new Microsoft.Data.SqlClient.SqlParameter("@billingType", billingType)};
            DataTable incomeSegregationStaticRptData = DALFunctions.GetDataTableFromStoredProc("SP_Report_BIL_IncomeSegregation", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return incomeSegregationStaticRptData;
        }
        #endregion

        #region Get Billing IncomeSegregation Report
        public DynamicReport GetSalesPurchaseTrainedCompanion(DateTime FromDate, DateTime ToDate, string Status, string ItemIdCommaSeprated)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramsList = new List<Microsoft.Data.SqlClient.SqlParameter>();
            paramsList.Add(new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate));
            paramsList.Add(new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate));
            paramsList.Add(new Microsoft.Data.SqlClient.SqlParameter("@Status", Status));
            paramsList.Add(new Microsoft.Data.SqlClient.SqlParameter("@ItemIdCommaSeprated", ItemIdCommaSeprated));

            ReportingDbContext reportingDbContext = new ReportingDbContext(_options);
            DataSet salesPurchase = DALFunctions.GetDatasetFromStoredProc("SP_DSB_Pharmacy_SalesPurchaseGraph_DashboardStatistics", paramsList, reportingDbContext);
            DynamicReport dReport = new DynamicReport();
            dReport.Schema = JsonConvert.SerializeObject(salesPurchase.Tables[0]);
            //wee need datetime in yyyy-MM-dd format.
            dReport.JsonData = salesPurchase.Tables.Count > 1 ? JsonConvert.SerializeObject(salesPurchase.Tables[1],
                                         new IsoDateTimeConverter() { DateTimeFormat = "yyyy-MM-dd" }) : null;

            return dReport;
        }
        #endregion



        #region Total Admitted Patients
        public DataTable TotalAdmittedPatient(DateTime FromDate, DateTime ToDate)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() { new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate), new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate) };
            DataTable data = DALFunctions.GetDataTableFromStoredProc("SP_Report_ADT_TotalAdmittedPatient", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return data;
        }
        #endregion
        #region Admission And Discharge List
        public DataTable AdmissionAndDischargeList(DateTime FromDate, DateTime ToDate, int WardId, int DepartmentId, int BedFeatureId, string AdmissionStatus, string SearchText)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate),
                new Microsoft.Data.SqlClient.SqlParameter("@WardId", WardId),
                new Microsoft.Data.SqlClient.SqlParameter("@DepartmentId", DepartmentId),
                new Microsoft.Data.SqlClient.SqlParameter("@BedFeatureId", BedFeatureId),
                new Microsoft.Data.SqlClient.SqlParameter("@AdmissionStatus", AdmissionStatus),
                new Microsoft.Data.SqlClient.SqlParameter("@SearchText", SearchText)
            };

            ReportingDbContext reportingDbContext = new ReportingDbContext(_options);
            DataTable data = DALFunctions.GetDataTableFromStoredProc("SP_Report_ADT_AdmissionAndDischargeReport", paramList, reportingDbContext);
            return data;
        }
        #endregion
        
        #region RankMembersipwiseAdmittedPatientReport
        public DataTable RankMembershipwiseAdmittedPatientReport(string fromDate, string toDate, string memberships, string ranks)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            {
                           new Microsoft.Data.SqlClient.SqlParameter("@FromDate", fromDate),
                           new Microsoft.Data.SqlClient.SqlParameter("@ToDate", toDate),
                           new Microsoft.Data.SqlClient.SqlParameter("@Memberships", memberships),
                           new Microsoft.Data.SqlClient.SqlParameter("@Ranks", ranks)
            };
            DataTable schemeDetailInvoiceReport = DALFunctions.GetDataTableFromStoredProc("RPT_SP_ADT_RankMembershipwiseAdmittedPatientReport", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return schemeDetailInvoiceReport;
        }
        #endregion

        #region Total Discharged Patients
        public DataTable DischargedPatient(DateTime FromDate, DateTime ToDate)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() { new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate), new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate) };
            DataTable data = DALFunctions.GetDataTableFromStoredProc("SP_Report_ADT_DischargedPatient", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return data;
        }
        #endregion

        #region Transferred Patients
        public DataTable TransferredPatient(DateTime FromDate, DateTime ToDate)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() { new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate), new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate) };
            DataTable data = DALFunctions.GetDataTableFromStoredProc("sp_Report_TransferredPatient", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return data;
        }
        #endregion

        #region Radiology Revenue Generated
        public DataTable RevenueGenerated(DateTime FromDate, DateTime ToDate)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> ipParam = new List<Microsoft.Data.SqlClient.SqlParameter>() { new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate), new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate) };
            DataTable data = DALFunctions.GetDataTableFromStoredProc("SP_Report_Radiology_RevenueGenerated", ipParam, (Microsoft.EntityFrameworkCore.DbContext)this);
            return data;
        }
        #endregion

        #region Category Wise Imaging Report
        public DynamicReport CategoryWiseImagingReport(DateTime FromDate, DateTime ToDate)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramsList = new List<Microsoft.Data.SqlClient.SqlParameter>();
            paramsList.Add(new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate));
            paramsList.Add(new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate));

            ReportingDbContext reportingDbContext = new ReportingDbContext(_options);
            DataSet dsCategoryWiseImagingReport = DALFunctions.GetDatasetFromStoredProc("SP_Report_Radiology_CategoryWiseImagingReport", paramsList, reportingDbContext);

            DynamicReport dReport = new DynamicReport();
            dReport.Schema = JsonConvert.SerializeObject(dsCategoryWiseImagingReport.Tables[0]);
            //wee need datetime in yyyy-MM-dd format.
            if (dsCategoryWiseImagingReport.Tables.Count > 1)
            {
                dReport.JsonData = JsonConvert.SerializeObject(dsCategoryWiseImagingReport.Tables[1],
                                      new IsoDateTimeConverter() { DateTimeFormat = "yyyy-MM-dd" });
            }


            return dReport;
        }
        #endregion

        #region Category Wise Lab Report

        public DataTable CategoryWiseLabReport(DateTime FromDate, DateTime ToDate, String orderStatus)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            { new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate), new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate),new Microsoft.Data.SqlClient.SqlParameter("@OrderStatus",orderStatus)};
            DataTable CategoryWiseLabData = DALFunctions.GetDataTableFromStoredProc("SP_Report_Lab_CategoryWiseLabReport", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return CategoryWiseLabData;
        }
        //public DynamicReport CategoryWiseLabReport(DateTime FromDate, DateTime ToDate)
        //{
        //    List<SqlParameter> paramsList = new List<SqlParameter>();
        //    paramsList.Add(new SqlParameter("@FromDate", FromDate));
        //    paramsList.Add(new SqlParameter("@ToDate", ToDate));
        //    //cmd.Parameters.Add();
        //    //cmd.Parameters.Add(new SqlParameter("@ToDate", ToDate));

        //    DataSet dsCategoryWiseLabReport = GetDatasetFromStoredProc2("SP_Report_Lab_CategoryWiseLabReport_old", paramsList, _options);
        //    DynamicReport dReport = new DynamicReport();
        //    dReport.Schema = JsonConvert.SerializeObject(dsCategoryWiseLabReport.Tables[0]);
        //    //wee need datetime in yyyy-MM-dd format.
        //    //sud: 5June'18-- it was crashing when only one table comes from db.
        //    if (dsCategoryWiseLabReport.Tables.Count > 1)
        //    {
        //        dReport.JsonData = JsonConvert.SerializeObject(dsCategoryWiseLabReport.Tables[1],
        //                                            new IsoDateTimeConverter() { DateTimeFormat = "yyyy-MM-dd" });
        //    }


        //    return dReport;
        //}
        #endregion

        public DataTable DoctorWisePatientCountLabReport(DateTime FromDate, DateTime ToDate)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            { new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate), new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate) };
            DataTable DoctorWiseLabData = DALFunctions.GetDataTableFromStoredProc("SP_Report_Lab_DoctorWisePatientCountLabReport", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return DoctorWiseLabData;
        }


        #region Category wise total Item Count Lab Report
        public DataTable CategoryWiseLabItemCountLabReport(DateTime FromDate, DateTime ToDate, String orderStatus)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            { new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate), new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate),
            new Microsoft.Data.SqlClient.SqlParameter("@OrderStatus",orderStatus)};
            DataTable CategoryWiseLabItem = DALFunctions.GetDataTableFromStoredProc("SP_LAB_CategoryWiseLabTestTotalCount", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return CategoryWiseLabItem;
        }
        #endregion   

        #region Item wise total Count Lab Report
        public DataTable ItemWiseLabItemCountLabReport(DateTime FromDate, DateTime ToDate, int? categoryId, String orderStatus)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            { new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate), new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate), new Microsoft.Data.SqlClient.SqlParameter("@catId", categoryId),
            new Microsoft.Data.SqlClient.SqlParameter("@OrderStatus",orderStatus)};
            DataTable ItemWiseData = DALFunctions.GetDataTableFromStoredProc("SP_LAB_TestWiseTotalCount", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return ItemWiseData;
        }
        #endregion

        #region Test Status wise detail report
        public DataTable TestStatusDetailReport(DateTime FromDate, DateTime ToDate, String orderStatus)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate),
                new Microsoft.Data.SqlClient.SqlParameter("@OrderStatus",orderStatus)
            };
            DataTable TestStatusWiseData = DALFunctions.GetDataTableFromStoredProc("SP_LAB_Statuswise_Test_Detail", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return TestStatusWiseData;
        }

        #endregion


        #region Doctor Wise patient report
        public DynamicReport DoctorWisePatientReport(DateTime FromDate, DateTime ToDate, string PerformerName)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramsList = new List<Microsoft.Data.SqlClient.SqlParameter>();
            paramsList.Add(new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate));
            paramsList.Add(new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate));
            paramsList.Add(new Microsoft.Data.SqlClient.SqlParameter("@PerformerName", PerformerName));

            ReportingDbContext reportingDbContext = new ReportingDbContext(_options);
            DataSet dsDoctorWisepatientRevenue = DALFunctions.GetDatasetFromStoredProc("SP_Report_Scheduling_DoctorWisePatientReport", paramsList, reportingDbContext);
            DynamicReport dReport = new DynamicReport();
            dReport.Schema = JsonConvert.SerializeObject(dsDoctorWisepatientRevenue.Tables[0]);
            dReport.JsonData = dsDoctorWisepatientRevenue.Tables.Count > 1 ? JsonConvert.SerializeObject(dsDoctorWisepatientRevenue.Tables[1],
                                         new IsoDateTimeConverter() { DateTimeFormat = "yyyy-MM-dd" }) : null;
            //return Data.ToList<PatientBillHistoryMaster>();
            return dReport;
        }
        #endregion

        #region Department Wise Appointment report
        public DynamicReport DepartmentWiseAppointmentReport(DateTime FromDate, DateTime ToDate, int DepartmentId)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramsList = new List<Microsoft.Data.SqlClient.SqlParameter>();
            paramsList.Add(new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate));
            paramsList.Add(new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate));
            paramsList.Add(new Microsoft.Data.SqlClient.SqlParameter("@DepartmentId", DepartmentId));

            ReportingDbContext reportingDbContext = new ReportingDbContext(_options);
            DataSet depatwiseappointmentdata = DALFunctions.GetDatasetFromStoredProc("SP_Report_Appointment_DepartmentWiseAppointmentReport", paramsList, reportingDbContext);
            DynamicReport dReport = new DynamicReport();
            dReport.Schema = JsonConvert.SerializeObject(depatwiseappointmentdata.Tables[0]);
            dReport.JsonData = depatwiseappointmentdata.Tables.Count > 1 ? JsonConvert.SerializeObject(depatwiseappointmentdata.Tables[1],
                                         new IsoDateTimeConverter() { DateTimeFormat = "yyyy-MM-dd" }) : null;
            //return Data.ToList<PatientBillHistoryMaster>();
            return dReport;
        }
        #endregion

        #region Patient Wise Credit Report

        public DataTable BIL_PatientCreditSummary(DateTime FromDate, DateTime ToDate)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() { new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate), new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate) };
            DataTable patientCreditSummaryData = DALFunctions.GetDataTableFromStoredProc("SP_Report_BIL_PatientCreditSummary", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return patientCreditSummaryData;
        }


        #endregion

        #region BIL Cancel Summary
        public DataTable BIL_BillCancelSummary(DateTime FromDate, DateTime ToDate)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate)
               , new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate)
            };
            DataTable billCancelSummaryData = DALFunctions.GetDataTableFromStoredProc("SP_Report_BILL_BillCancelReport", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return billCancelSummaryData;
        }
        #endregion

        #region Credit Settlement Report
        public DataTable BIL_CreditSettlementReport(DateTime FromDate, DateTime ToDate)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate)
               , new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate)
            };
            DataTable dtCreditSettlementReport = DALFunctions.GetDataTableFromStoredProc("SP_BIL_GetSettlementSummaryReport", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return dtCreditSettlementReport;
        }
        #endregion

        #region Bill Return Report

        public DataTable BIL_ReturnReport(DateTime FromDate, DateTime ToDate)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate)
               , new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate)
            };
            DataTable returnBillData = DALFunctions.GetDataTableFromStoredProc("SP_Report_BILL_Invoice_Return", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return returnBillData;

        }
        #endregion

        public DataTable BIL_ReturnReportDetail(int BillReturnId)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() {
                new Microsoft.Data.SqlClient.SqlParameter("@BillReturnId", BillReturnId)

            };
            DataTable returnBillData = DALFunctions.GetDataTableFromStoredProc("SP_Report_BILL_Invoice_Return_Detail", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return returnBillData;

        }

        #region Doctor Referral Report
        public DataTable DoctorReferral(DateTime FromDate, DateTime ToDate, string ProviderName)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            {
                 new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate), new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate)
            };
            if (ProviderName != null)
            {
                SqlParameter providerParameter = new SqlParameter("@ProviderName", ProviderName);
                paramList.Add(providerParameter);
            }
            DataTable DoctorReferralData = DALFunctions.GetDataTableFromStoredProc("SP_Report_BIL_DoctorReferrals", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return DoctorReferralData;
        }
        #endregion

        //private DataSet GetTestWiseRevenue2(DateTime FromDate, DateTime ToDate, string connString)
        //{
        //    // creates resulting dataset
        //    var result = new DataSet();
        //    var context = new ReportingDbContext(connString);


        //    // creates a Command 
        //    var cmd = context.Database.Connection.CreateCommand();
        //    cmd.CommandType = CommandType.StoredProcedure;
        //    cmd.CommandText = "sp_Report_TestWiseRevenue";

        //    //List<SqlParameter> paramsList = new List<SqlParameter>();
        //    //paramsList.Add(new SqlParameter("@FromDate", FromDate));




        //    cmd.Parameters.Add(new SqlParameter("@FromDate", FromDate));
        //    cmd.Parameters.Add(new SqlParameter("@ToDate", ToDate));




        //    try
        //    {
        //        // executes
        //        context.Database.Connection.Open();
        //        var reader = cmd.ExecuteReader();

        //        // loop through all resultsets (considering that it's possible to have more than one)
        //        do
        //        {
        //            // loads the DataTable (schema will be fetch automatically)
        //            var tb = new DataTable();
        //            tb.Load(reader);
        //            result.Tables.Add(tb);

        //        } while (!reader.IsClosed);

        //        return result;
        //    }
        //    finally
        //    {
        //        // closes the connection
        //        context.Database.Connection.Close();
        //    }
        //}

        private DataSet GetDatasetFromStoredProc2(string storedProcName, List<Microsoft.Data.SqlClient.SqlParameter> ipParams)
        {
            // creates resulting dataset
            var result = new DataSet();
            var cmd = this.Database.GetDbConnection().CreateCommand();
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.CommandText = storedProcName;

            if (ipParams != null && ipParams.Count > 0)
            {
                foreach (var param in ipParams)
                {
                    cmd.Parameters.Add(param);
                }
            }

            try
            {
                // executes
                if (this.Database.GetDbConnection().State == ConnectionState.Closed)
                {
                    this.Database.GetDbConnection().Open();
                    var reader = cmd.ExecuteReader();

                    // loop through all resultsets (considering that it's possible to have more than one)
                    do
                    {
                        // loads the DataTable (schema will be fetch automatically)
                        var tb = new DataTable();
                        tb.Load(reader);
                        result.Tables.Add(tb);

                    } while (!reader.IsClosed);

                    return result;
                }
                return null;
            }
            finally
            {
                // closes the connection
                this.Database.GetDbConnection().Close();
            }

        }

        #region Total Revenue From Lab
        public DataTable TotalRevenueFromLab(DateTime FromDate, DateTime ToDate)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate), new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate)
            };
            DataTable data = DALFunctions.GetDataTableFromStoredProc("SP_Report_TotalRevenueFromLab", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return data;
        }
        #endregion

        #region Item Wise From Lab
        public DataTable ItemWiseFromLab(DateTime FromDate, DateTime ToDate)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate), new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate)
            };
            DataTable data = DALFunctions.GetDataTableFromStoredProc("SP_Report_ItemwiseFromLab", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return data;
        }
        #endregion

        #region For Dashboards
        public DynamicReport BIL_Daily_IncomeSegregation(DateTime FromDate, DateTime ToDate)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramsList = new List<Microsoft.Data.SqlClient.SqlParameter>();
            paramsList.Add(new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate));
            paramsList.Add(new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate));

            ReportingDbContext reportingDbContext = new ReportingDbContext(_options);
            DataSet dsIncomeSegReport = DALFunctions.GetDatasetFromStoredProc("SP_Report_BIL_IncomeSegregation", paramsList, reportingDbContext);
            DynamicReport dReport = new DynamicReport();

            //dReport.Schema = dReport.Schema = JsonConvert.SerializeObject(dsIncomeSegReport.Tables[0]); ;
            dReport.Schema = null;//we have only one table returning from the database.. 
            //wee need datetime in yyyy-MM-dd format.
            dReport.JsonData = JsonConvert.SerializeObject(dsIncomeSegReport.Tables[0],
                                         new IsoDateTimeConverter() { DateTimeFormat = "yyyy-MM-dd" });

            return dReport;
        }

        public DynamicReport BIL_Daily_RevenueTrend()
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramsList = new List<Microsoft.Data.SqlClient.SqlParameter>();
            ReportingDbContext reportingDbContext = new ReportingDbContext(_options);
            DataSet dsDailyRev = DALFunctions.GetDatasetFromStoredProc("SP_Report_BILDSB_DailyRevenueTrend", paramsList, reportingDbContext);

            DynamicReport dReport = new DynamicReport();

            dReport.Schema = null;//we have only one table returning from the database.. 
            //wee need datetime in yyyy-MM-dd format.
            dReport.JsonData = JsonConvert.SerializeObject(dsDailyRev.Tables[0],
                                         new IsoDateTimeConverter() { DateTimeFormat = "yyyy-MM-dd" });
            return dReport;
        }

        public DynamicReport BIL_Monthly_BillingTrend()
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramsList = new List<Microsoft.Data.SqlClient.SqlParameter>();
            ReportingDbContext reportingDbContext = new ReportingDbContext(_options);
            DataSet dsMthBillTrend = DALFunctions.GetDatasetFromStoredProc("SP_Report_BILDSB_MonthlyBillingTrend", paramsList, reportingDbContext);
            DynamicReport dReport = new DynamicReport();

            dReport.Schema = null;//we have only one table returning from the database.. 
            //wee need datetime in yyyy-MM-dd format.
            dReport.JsonData = JsonConvert.SerializeObject(dsMthBillTrend.Tables[0],
                                         new IsoDateTimeConverter() { DateTimeFormat = "yyyy-MM-dd" });
            return dReport;
        }

        public DynamicReport BIL_Daily_CounterNUsersCollection(DateTime FromDate, DateTime ToDate)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramsList = new List<Microsoft.Data.SqlClient.SqlParameter>();
            paramsList.Add(new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate));
            paramsList.Add(new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate));

            ReportingDbContext reportingDbContext = new ReportingDbContext(_options);
            DataSet dsCtrUsrs = DALFunctions.GetDatasetFromStoredProc("SP_Report_BILL_CounterNUsersCollectionDaily", paramsList, reportingDbContext);

            if (dsCtrUsrs != null && dsCtrUsrs.Tables.Count > 0)
            {
                DynamicReport dReport = new DynamicReport();

                //return an anonymous type with counter and user collection..
                var dailyCollection = new { UserCollection = dsCtrUsrs.Tables[0], CounterCollection = dsCtrUsrs.Tables[1] };
                dReport.JsonData = JsonConvert.SerializeObject(dailyCollection,
                                                 new IsoDateTimeConverter() { DateTimeFormat = "yyyy-MM-dd" });
                return dReport;


            }
            return null;
        }

        public DynamicReport Home_DashboardStatistics()
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramsList = new List<Microsoft.Data.SqlClient.SqlParameter>();
            ReportingDbContext reportingDbContext = new ReportingDbContext(_options);
            DataSet dsHomeDsbStats = DALFunctions.GetDatasetFromStoredProc("SP_DSB_Home_DashboardStatistics", paramsList, reportingDbContext);

            DynamicReport dReport = new DynamicReport();
            dReport.Schema = null;//we have only one table returning from the database.. 
            dReport.JsonData = JsonConvert.SerializeObject(dsHomeDsbStats.Tables[0]);
            return dReport;
        }
        public DataTable Home_DashinvboardStatistics(int SourceStoreId)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            {
                new Microsoft.Data.SqlClient.SqlParameter("@SourceStoreId", SourceStoreId),
            };
            DataTable rData = DALFunctions.GetDataTableFromStoredProc("SP_DBS_Home_InvDashboardStats", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return rData;
        }
        public DataTable Home_Dashboard_DepartmentWiseConsumerItems(int SourceStoreId)
        {

            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            {
                new Microsoft.Data.SqlClient.SqlParameter("@SourceStoreId", SourceStoreId),
            };
            DataTable rData = DALFunctions.GetDataTableFromStoredProc("SP_DSB_Home_DeptWiseConsumerItems", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return rData;

        }

        public DataTable Home_Dashboard_SubCategoryWiseInventoryStockValue(int SourceStoreId)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            {
                new Microsoft.Data.SqlClient.SqlParameter("@SourceStoreId", SourceStoreId),
            };
            DataTable rData = DALFunctions.GetDataTableFromStoredProc("SP_DSB_Home_SubCategoryWiseInventoryStockValue", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return rData;

        }

        public DataTable Home_Dashboard_MonthlyWisePurchaseOrdervsGoodsReceiptValue(int SourceStoreId)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            {
                new Microsoft.Data.SqlClient.SqlParameter("@SourceStoreId", SourceStoreId),
            };
            DataTable rData = DALFunctions.GetDataTableFromStoredProc("SP_DSB_Home_MonthlyWisePurchaseOrdervsGoodsReceiptValue", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);

            return rData;

        }
        public DynamicReport Home_PatientZoneMap()
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramsList = new List<Microsoft.Data.SqlClient.SqlParameter>();
            ReportingDbContext reportingDbContext = new ReportingDbContext(_options);
            DataSet dsHomeDsbStats = DALFunctions.GetDatasetFromStoredProc("SP_DSB_Home_PatientDistributionMap_Nepal", paramsList, reportingDbContext);

            DynamicReport dReport = new DynamicReport();

            dReport.Schema = null;//we have only one table returning from the database.. 
            dReport.JsonData = JsonConvert.SerializeObject(dsHomeDsbStats.Tables[0],
                                         new IsoDateTimeConverter() { DateTimeFormat = "yyyy-MM-dd" });
            return dReport;
        }
        public DynamicReport Home_DeptWise_TotalAppointmentCount()
        {
            /////This TodaysDate is Required Because We Want Data of PerDay DepartmentWise Appointment Count
            var TodaysDate = DateTime.Now.Date;
            List<Microsoft.Data.SqlClient.SqlParameter> paramsList = new List<Microsoft.Data.SqlClient.SqlParameter>();
            paramsList.Add(new Microsoft.Data.SqlClient.SqlParameter("@TodaysDate", TodaysDate));
            ReportingDbContext reportingDbContext = new ReportingDbContext(_options);
            DataSet dsHomeDsbStats = DALFunctions.GetDatasetFromStoredProc("SP_DSB_Home_DeptWiseAppointmentCount", paramsList, reportingDbContext);

            DynamicReport dReport = new DynamicReport();

            dReport.Schema = null;//we have only one table returning from the database.. 
            dReport.JsonData = JsonConvert.SerializeObject(dsHomeDsbStats.Tables[0],
                                         new IsoDateTimeConverter() { DateTimeFormat = "yyyy-MM-dd" });
            return dReport;
        }

        public DynamicReport Patient_GenderWiseCount()
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramsList = new List<Microsoft.Data.SqlClient.SqlParameter>();
            ReportingDbContext reportingDbContext = new ReportingDbContext(_options);
            DataSet dsPatCounts = DALFunctions.GetDatasetFromStoredProc("SP_DSB_Patient_GenderWiseCount", paramsList, reportingDbContext);

            DynamicReport dReport = new DynamicReport();

            dReport.Schema = null;//we have only one table returning from the database.. 
            dReport.JsonData = JsonConvert.SerializeObject(dsPatCounts.Tables[0]);
            return dReport;
        }

        public DynamicReport Patient_AgeRangeNGenderWiseCount()
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramsList = new List<Microsoft.Data.SqlClient.SqlParameter>();
            ReportingDbContext reportingDbContext = new ReportingDbContext(_options);
            DataSet dsPatCounts = DALFunctions.GetDatasetFromStoredProc("SP_DSB_Patient_AgeRangeNGender", paramsList, reportingDbContext);

            DynamicReport dReport = new DynamicReport();
            dReport.Schema = null;//we have only one table returning from the database.. 
            dReport.JsonData = JsonConvert.SerializeObject(dsPatCounts.Tables[0]);
            return dReport;
        }

        public DynamicReport Lab_DashboardStatistics()
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramsList = new List<Microsoft.Data.SqlClient.SqlParameter>();
            ReportingDbContext reportingDbContext = new ReportingDbContext(_options);
            DataSet dsLabDsbStats = DALFunctions.GetDatasetFromStoredProc("SP_DSB_Lab_DashboardStatistics", paramsList, reportingDbContext);
            DynamicReport dReport = new DynamicReport();
            //return an anonymous type - when mutliple table are received
            var labDashboard = new
            {
                LabelData = dsLabDsbStats.Tables[0],
                TestTrendsData = dsLabDsbStats.Tables[1],
                TestCompletedData = dsLabDsbStats.Tables[2]
            };
            dReport.Schema = null;
            dReport.JsonData = JsonConvert.SerializeObject(labDashboard);
            return dReport;
        }

        public DynamicReport Emergency_DashboardStatistics()
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramsList = new List<Microsoft.Data.SqlClient.SqlParameter>();
            ReportingDbContext reportingDbContext = new ReportingDbContext(_options);
            DataSet dsLabDsbStats = DALFunctions.GetDatasetFromStoredProc("SP_DSB_Emergency_DashboardStatistics", paramsList, reportingDbContext);
            DynamicReport dReport = new DynamicReport();
            //return an anonymous type - when mutliple table are received
            var ERDashboard = new
            {
                LabelData = dsLabDsbStats.Tables[0]
            };
            dReport.Schema = null;
            dReport.JsonData = JsonConvert.SerializeObject(ERDashboard);
            return dReport;
        }

        #endregion

        #region IRD Related reporting methods

        //IRD Invoice Details 
        public List<InvoiceDetailsModel> InvoiceDetails(DateTime FromDate, DateTime ToDate)
        {
            // EF Core does not support Database.SqlQuery<T>, use FromSqlRaw or ADO.NET
            return this.Set<InvoiceDetailsModel>()
                .FromSqlRaw("exec SP_IRD_InvoiceDetails @FromDate,@ToDate", new SqlParameter("@FromDate", FromDate), new SqlParameter("@ToDate", ToDate))
                .ToList();
        }

        //All IRD Invoice Details 
        public List<InvoiceDetailsModel> GetAllInvoiceDetails(DateTime fromDate, DateTime toDate)
        {
            return this.Set<InvoiceDetailsModel>()
                .FromSqlRaw("exec SP_All_IRD_InvoiceDetails @FromDate,@ToDate", new SqlParameter("@FromDate", fromDate), new SqlParameter("@ToDate", toDate))
                .ToList();
        }


        // IRD Pharmacy Invoice Details
        public List<PhrmInvoiceDetails> PhrmInvoiceDetails(DateTime FromDate, DateTime ToDate)
        {
            return this.Set<PhrmInvoiceDetails>()
                .FromSqlRaw("exec SP_IRD_PHRM_InvoiceDetails @FromDate,@ToDate", new SqlParameter("@FromDate", FromDate), new SqlParameter("@ToDate", ToDate))
                .ToList();
        }


        //IRD - SQL Audit details
        public List<SqlAuditModel> SqlAuditDetails(DateTime FromDate, DateTime ToDate, string LogType)
        {
            return this.Set<SqlAuditModel>()
                .FromSqlRaw("exec SP_Danphe_SQLAudit @FromDate,@ToDate,@LogType", new SqlParameter("@FromDate", FromDate), new SqlParameter("@ToDate", ToDate), new SqlParameter("@LogType", LogType))
                .ToList();
        }
        #endregion
        #region Patient Discharge bill breakup report        
        public DataTable BillDischargeBreakup(int PatientVisitId, int PatientId)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() {
                new Microsoft.Data.SqlClient.SqlParameter("@PatientVisitId",PatientVisitId),
                new Microsoft.Data.SqlClient.SqlParameter("@PatientId",PatientId)
            };
            DataTable returnBillData = DALFunctions.GetDataTableFromStoredProc("SP_Report_BIL_DischargeBreakup", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return returnBillData;
        }
        #endregion
        #region AuditTrailList Details        
        public List<AuditTrailModel> AuditTrailList()
        {
            var data = Database.SqlQuery<AuditTrailModel>("exec SP_Danphe_Audit_List ").ToList();

            return data.ToList<AuditTrailModel>();
        }
        #endregion
        #region AuditTrail Details        
        public DataTable AuditTrails(DateTime FromDate, DateTime ToDate, string Table_Name, string UserName, string ActionName)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate),
                new Microsoft.Data.SqlClient.SqlParameter("@UserName", UserName),
                new Microsoft.Data.SqlClient.SqlParameter("@Table_Name", Table_Name),
                new Microsoft.Data.SqlClient.SqlParameter("@Action", ActionName)

            };
            DataTable returnAuditData = DALFunctions.GetDataTableFromStoredProc("SP_Danphe_Audit", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return returnAuditData;
        }
        #endregion



        #region BillReferralSummaryReport
        public DynamicReport Bill_ReferralSummary(DateTime FromDate, DateTime ToDate, bool? isExternal)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate),
                new Microsoft.Data.SqlClient.SqlParameter("@isExternal", isExternal)
            };
            DataSet rData = DALFunctions.GetDatasetFromStoredProc("SP_Report_BIL_ReferralSummary", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            DynamicReport dReport = new DynamicReport();
            if (rData.Tables.Count > 1)
            {
                var data = new
                {
                    ReportData = rData.Tables[0],
                    Summary = rData.Tables[1]
                };
                dReport.Schema = null;
                dReport.JsonData = JsonConvert.SerializeObject(data);
            }
            return dReport;
        }
        #endregion



        #region Referral Item Summary
        public DynamicReport Bill_ReferralItemSumamry(DateTime FromDate, DateTime ToDate, int PrescriberId)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate),
                new Microsoft.Data.SqlClient.SqlParameter("@PrescriberId", PrescriberId)
            };
            DataSet rData = DALFunctions.GetDatasetFromStoredProc("SP_Report_BIL_ReferralItemsSummary", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            DynamicReport dReport = new DynamicReport();
            if (rData.Tables.Count > 1)
            {
                var data = new
                {
                    ReportData = rData.Tables[0],
                    Summary = rData.Tables[1]
                };
                dReport.Schema = null;
                dReport.JsonData = JsonConvert.SerializeObject(data);
            }
            return dReport;
        }
        #endregion


        #region IncentiveSummaryReport
        public DynamicReport INCTV_DoctorSummary(DateTime FromDate, DateTime ToDate, Boolean IsRefferalOnly)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate),
                new Microsoft.Data.SqlClient.SqlParameter("@IsRefferalOnly", IsRefferalOnly)
            };
            DataTable rptDataTable = DALFunctions.GetDataTableFromStoredProc("SP_Report_INCTV_DoctorSummary", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            DynamicReport dReport = new DynamicReport();
            if (rptDataTable != null)
            {
                dReport.Schema = null;
                dReport.JsonData = JsonConvert.SerializeObject(rptDataTable);
            }
            return dReport;
        }
        #endregion

        #region Incentive Item Summary Report
        public DynamicReport INCTV_SummaryItemReport(DateTime FromDate, DateTime ToDate, int employeeId, Boolean IsRefferalOnly)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate),
                new Microsoft.Data.SqlClient.SqlParameter("@employeeId", employeeId),
                new Microsoft.Data.SqlClient.SqlParameter("@IsRefferalOnly", IsRefferalOnly)
            };
            DataSet rData = DALFunctions.GetDatasetFromStoredProc("SP_Report_INCTV_ReferralItemsSummary", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            DynamicReport dReport = new DynamicReport();
            if (rData != null)
            {
                dReport.Schema = null;
                dReport.JsonData = JsonConvert.SerializeObject(rData);
            }
            return dReport;
        }
        #endregion

        #region Incentive Doc ItemGroup Summary
        public DynamicReport INCTV_Doc_ItemGroupSummary(DateTime FromDate, DateTime ToDate, int employeeId, Boolean IsRefferalOnly)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate),
                new Microsoft.Data.SqlClient.SqlParameter("@employeeId", employeeId),
                new Microsoft.Data.SqlClient.SqlParameter("@IsRefferalOnly", IsRefferalOnly)
            };
            DataSet rData = DALFunctions.GetDatasetFromStoredProc("SP_Report_INCTV_Doc_ItemGroupSummary", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            DynamicReport dReport = new DynamicReport();
            if (rData != null)
            {
                dReport.Schema = null;
                dReport.JsonData = JsonConvert.SerializeObject(rData);
            }
            return dReport;
        }
        #endregion

        //PatientRegistrationReport
        public DataTable PatientRegistrationReport(DateTime FromDate, DateTime ToDate, string Gender, string Country)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate),
                new Microsoft.Data.SqlClient.SqlParameter("@Gender", Gender),
                new Microsoft.Data.SqlClient.SqlParameter("@Country", Country)
            };
            DataTable PatientRegRptdata = DALFunctions.GetDataTableFromStoredProc("SP_Report_Patient_RegistrationReport", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return PatientRegRptdata;
        }

        //For handover Amount 
        #region 
        public DynamicReport GetHandoverCalculationDateWise(DateTime FromDate, DateTime ToDate)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate)
            };
            DataSet rData = DALFunctions.GetDatasetFromStoredProc("SP_BIL_TXN_GetHandoverCalculationDateWise", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            DynamicReport dReport = new DynamicReport();
            if (rData != null)
            {
                dReport.Schema = null;
                dReport.JsonData = JsonConvert.SerializeObject(rData);
            }
            return dReport;
        }
        #endregion

        #region IncentivePaymentSummaryReport
        public DynamicReport INCTV_DoctorPaymentSummary(DateTime FromDate, DateTime ToDate)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate)
            };
            DataTable rptDataTable = DALFunctions.GetDataTableFromStoredProc("SP_Report_INCTV_DoctorPayment", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            DynamicReport dReport = new DynamicReport();
            if (rptDataTable != null)
            {
                dReport.Schema = null;
                dReport.JsonData = JsonConvert.SerializeObject(rptDataTable);
            }
            return dReport;
        }
        #endregion

        #region Bill Item Summary Report
        public DynamicReport RPT_Bil_ItemSummaryReport(DateTime FromDate, DateTime ToDate)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate)
            };
            DataSet rData = DALFunctions.GetDatasetFromStoredProc("SP_Report_ItemSummaryReport", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            DynamicReport dReport = new DynamicReport();
            if (rData != null)
            {
                dReport.Schema = null;
                dReport.JsonData = JsonConvert.SerializeObject(rData);
            }
            return dReport;
        }
        #endregion


        public DataTable PoliceCaseReport(DateTime FromDate, DateTime ToDate)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate),
            };

            DataTable policecasedata = DALFunctions.GetDataTableFromStoredProc("SP_Report_PoliceCasePatient", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return policecasedata;
        }

        public DataTable CovidDetailsForLab(string testName)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramsList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            {
                new Microsoft.Data.SqlClient.SqlParameter("@TestName", testName)
            };
            ReportingDbContext reportingDbContext = new ReportingDbContext(_options);
            DataTable testDetails = DALFunctions.GetDataTableFromStoredProc("SP_LAB_GetCovidTestDetails", paramsList, reportingDbContext);

            return testDetails;

        }

        public DataTable TotalCovidTestsDetailReport(string testName, string resultType, string CaseType, int CountrySubDivisionId, DateTime fromDate, DateTime toDate, string gender)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramsList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", fromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", toDate),
                new Microsoft.Data.SqlClient.SqlParameter("@TestName", testName),
                new Microsoft.Data.SqlClient.SqlParameter("@Gender", gender),
                new Microsoft.Data.SqlClient.SqlParameter("@ResultType", resultType),
                new Microsoft.Data.SqlClient.SqlParameter("@CountrySubDivisionId", CountrySubDivisionId),
                new Microsoft.Data.SqlClient.SqlParameter("@CaseType", CaseType),
            };
            ReportingDbContext reportingDbContext = new ReportingDbContext(_options);
            DataTable testDetails = DALFunctions.GetDataTableFromStoredProc("SP_REPORT_LAB_TotalDailyCovidTestDetails", paramsList, reportingDbContext);

            return testDetails;
        }

        public DataTable CovidTestsCumulativeReport(string testName, int subDivId, DateTime fromDate, DateTime toDate)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramsList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", fromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", toDate),
                new Microsoft.Data.SqlClient.SqlParameter("@TestName", testName),
                new Microsoft.Data.SqlClient.SqlParameter("@CountrySubDivisionId", subDivId),
            };
            ReportingDbContext reportingDbContext = new ReportingDbContext(_options);
            DataTable testDetails = DALFunctions.GetDataTableFromStoredProc("SP_Report_Lab_CovidTestsSummary", paramsList, reportingDbContext);

            return testDetails;
        }

        public DataTable GetHIVTestsDetailReport(DateTime fromDate, DateTime toDate)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramsList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", fromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", toDate)
            };
            ReportingDbContext reportingDbContext = new ReportingDbContext(_options);
            DataTable testDetails = DALFunctions.GetDataTableFromStoredProc("SP_Report_LAB_GetHIVTestDetails", paramsList, reportingDbContext);

            return testDetails;
        }

        public DataTable GetCultureTestsDetailReport(DateTime fromDate, DateTime toDate)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramsList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", fromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", toDate)
            };
            ReportingDbContext reportingDbContext = new ReportingDbContext(_options);
            DataTable testDetails = DALFunctions.GetDataTableFromStoredProc("SP_Report_LAB_GetCultureReport", paramsList, reportingDbContext);

            return testDetails;
        }

        public DataTable GetLabTypeWiseTestCountreport(int testId, string orderStatus, int categoryId, DateTime fromDate, DateTime toDate)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramsList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", fromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", toDate),
                new Microsoft.Data.SqlClient.SqlParameter("@TestId", testId),
                new Microsoft.Data.SqlClient.SqlParameter("@CategoryId", categoryId),
                new Microsoft.Data.SqlClient.SqlParameter("@OrderStatus",orderStatus)
            };
            ReportingDbContext reportingDbContext = new ReportingDbContext(_options);
            DataTable data = DALFunctions.GetDataTableFromStoredProc("SP_Report_Lab_LabTypeWise_Test_Count", paramsList, reportingDbContext);

            return data;
        }

        public DataTable GetEditedPatientDetailReport(int userId, DateTime fromDate, DateTime toDate)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramsList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", fromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", toDate),
                new Microsoft.Data.SqlClient.SqlParameter("@UserId", userId)
            };
            ReportingDbContext reportingDbContext = new ReportingDbContext(_options);
            DataTable data = DALFunctions.GetDataTableFromStoredProc("SP_Report_PAT_EditedPatientDetailReport", paramsList, reportingDbContext);

            return data;
        }
        #region UserWiseCashCollectionReport
        public DynamicReport UserWiseCashCollectionReport(DateTime fromDate, DateTime toDate, object UserId)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", fromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", toDate),
                new Microsoft.Data.SqlClient.SqlParameter("@UserId", UserId ?? DBNull.Value)
            };
            DataSet rData = DALFunctions.GetDatasetFromStoredProc("SP_Report_BILL_UserWiseCashCollectionReport", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            DynamicReport dReport = new DynamicReport();
            if (rData.Tables.Count > 0)
            {
                var data = new
                {
                    ReportData = rData.Tables[0],
                };
                dReport.Schema = null;
                dReport.JsonData = JsonConvert.SerializeObject(data);
            }
            return dReport;
        }
        #endregion


        #region radiology film count report.
        public DataTable GetFilmCountReport(DateTime fromdate, DateTime todate)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            {
                new Microsoft.Data.SqlClient.SqlParameter("@fromDate",fromdate),
                new Microsoft.Data.SqlClient.SqlParameter("@toDate", todate)
            };
            RadiologyDbContext radiologyDbContext = new RadiologyDbContext(_options);
            DataTable data = DALFunctions.GetDataTableFromStoredProc("SP_Report_Radiology_Film_Type_Count", paramList, radiologyDbContext);
            return data;
        }
        #endregion
        #region Digital Payment Mode Report
        public DynamicReport PaymentModeWiseReport(DateTime FromDate, DateTime ToDate, string PaymentMode, string Type, int User)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() {  new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                            new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate),
                            new Microsoft.Data.SqlClient.SqlParameter("@PaymentMode", PaymentMode),
                            new Microsoft.Data.SqlClient.SqlParameter("@Type", Type),
                            new Microsoft.Data.SqlClient.SqlParameter("@User", User)
                              };
            DataSet dataSet = DALFunctions.GetDatasetFromStoredProc("SP_BIL_MultiplePaymentModeWiseReport", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            DynamicReport dReport = new DynamicReport();
            if (dataSet.Tables.Count > 0)
            {
                var data = new
                {
                    InvoiceWiseDigitalPayment = dataSet.Tables[0],
                    ReportSummary = dataSet.Tables[1]
                };
                dReport.Schema = null;
                dReport.JsonData = JsonConvert.SerializeObject(data);
            }
            return dReport;
        }
        #endregion

        public DataTable HospitalIncomeIncentiveReport(DateTime FromDate, DateTime ToDate, string ServiceDepartments)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramsList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ServiceDepartments", ServiceDepartments)
            };
            ReportingDbContext reportingDbContext = new ReportingDbContext(_options);
            DataTable data = DALFunctions.GetDataTableFromStoredProc("SP_INCTV_Report_Hospital_Income", paramsList, reportingDbContext);

            return data;
        }

        public DataTable HospitalIncomeIncentiveReportServiceDepartmentWise(DateTime FromDate, DateTime ToDate, int ServiceDepartmentId)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramsList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ServiceDepartmentId", ServiceDepartmentId)
            };
            ReportingDbContext reportingDbContext = new ReportingDbContext(_options);
            DataTable data = DALFunctions.GetDataTableFromStoredProc("SP_INCTV_Report_ServiceDepartmentWise_Hospital_Income", paramsList, reportingDbContext);

            return data;
        }

        #region Bill Detail Report
        public DataTable BillDetailReport(DateTime FromDate, DateTime ToDate, string billingType, int? ItemId, int? UserId, string RankName, int? MembershipTypeId, int? ServiceDepartmentId)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() {
                           new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                           new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate),
                           new Microsoft.Data.SqlClient.SqlParameter("@billingType", billingType),
                           new Microsoft.Data.SqlClient.SqlParameter("@ItemId", ItemId),
                           new Microsoft.Data.SqlClient.SqlParameter("@UserId", UserId),
                           new Microsoft.Data.SqlClient.SqlParameter("@Rank", RankName=="null"? null: RankName),
                           new Microsoft.Data.SqlClient.SqlParameter("@MembershipTypeId", MembershipTypeId),
                           new Microsoft.Data.SqlClient.SqlParameter("@ServiceDepartmentId", ServiceDepartmentId),
            };

            DataTable totalItemBillData = DALFunctions.GetDataTableFromStoredProc("SP_Report_APF_BillDetailReport", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return totalItemBillData;
        }
        #endregion

        #region Get All Inventory Dashboard Statistics
        public DataTable InventoryDashboardStatistics(int SourceStoreId)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            {
                new Microsoft.Data.SqlClient.SqlParameter("@SourceStoreId", SourceStoreId)
            };
            DataTable rData = DALFunctions.GetDataTableFromStoredProc("SP_InventoryDashboardStatistics", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return rData;
        }
        #endregion

        #region Get All Storewise Dispatched Value
        public DataTable DepaartmentWiseDispatchedValue(int SourceStoreId, DateTime? FromDate, DateTime? ToDate)
        {

            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            {
                new Microsoft.Data.SqlClient.SqlParameter("@SourceStoreId", SourceStoreId),
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate),
            };
            DataTable rData = DALFunctions.GetDataTableFromStoredProc("SP_DepartmentWiseDispatchValue", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return rData;

        }
        #endregion

        #region Get SubCategory Wise Inventory Stock Value
        public DataTable SubCategoryWiseInventoryStockValue(int SourceStoreId)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            {
                new Microsoft.Data.SqlClient.SqlParameter("@SourceStoreId", SourceStoreId)
            };
            DataTable rData = DALFunctions.GetDataTableFromStoredProc("SP_SubCategoryWiseInventoryStockValue", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return rData;

        }
        #endregion

        #region Get Monthly Wise PurchaseOrder ,GoodReceipt and Dispatch
        public DataTable MonthlyWiseTransaction(int SourceStoreId)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            {
                new Microsoft.Data.SqlClient.SqlParameter("@SourceStoreId", SourceStoreId)
            };
            DataTable rData = DALFunctions.GetDataTableFromStoredProc("SP_MonthlyWisePurchaseOrdervsGoodsReceiptValue", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);

            return rData;

        }
        #endregion


        #region SchemeDetailInvoiceReport
        public DataTable SchemeDetailInvoiceReport(string fromDate, string toDate, string memberships, string ranks, string users)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            {
                           new Microsoft.Data.SqlClient.SqlParameter("@FromDate", fromDate),
                           new Microsoft.Data.SqlClient.SqlParameter("@ToDate", toDate),
                           new Microsoft.Data.SqlClient.SqlParameter("@Memberships", memberships),
                           new Microsoft.Data.SqlClient.SqlParameter("@Ranks", ranks),
                           new Microsoft.Data.SqlClient.SqlParameter("@Users", users)
            };
            DataTable schemeDetailInvoiceReport = DALFunctions.GetDataTableFromStoredProc("SP_Report_Bill_SchemeDetailInvoice", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return schemeDetailInvoiceReport;
        }
        #endregion

        #region This will return datatable for Billing Dashboard Rank wise patient invoice count
        public DataTable BillingDashboardRankWisePatientInvoiceCount(string FromDate, string ToDate)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramsList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate)
            };
            ReportingDbContext reportingDbContext = new ReportingDbContext(_options);
            DataTable data = DALFunctions.GetDataTableFromStoredProc("SP_BIL_Dashboard_RankWisePatientInvoiceCount", paramsList, reportingDbContext);

            return data;
        }
        #endregion

        #region This will return datatable for Billing Dashboard Membership wise patient invoice count
        public DataTable BillingDashboardMembershipWisePatientInvoiceCount(string FromDate, string ToDate)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramsList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate)
            };
            ReportingDbContext reportingDbContext = new ReportingDbContext(_options);
            DataTable data = DALFunctions.GetDataTableFromStoredProc("SP_BIL_Dashboard_MembershipWisePatientInvoiceCount", paramsList, reportingDbContext);

            return data;
        }
        #endregion

        #region This will return datatable for Lab Dashboard Membership wise Test  count
        public DataTable LabDashboardMembershipWiseTestCount(string FromDate, string ToDate)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramsList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate)
            };
            ReportingDbContext reportingDbContext = new ReportingDbContext(_options);
            DataTable data = DALFunctions.GetDataTableFromStoredProc("SP_Dashboard_LAB_MembershipWiseLabTest", paramsList, reportingDbContext);

            return data;
        }
        #endregion

        #region This will return datatable for Lab Dashboard Rank wise Test  count
        public DataTable LabDashboardRankWiseTestCount(string FromDate, string ToDate)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramsList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate)
            };
            ReportingDbContext reportingDbContext = new ReportingDbContext(_options);
            DataTable data = DALFunctions.GetDataTableFromStoredProc("SP_Dashboard_LABRankWiseLabTest", paramsList, reportingDbContext);

            return data;
        }
        #endregion

        #region This will return datatable for Lab Dashboard Top 10Trending Test  count
        public DataTable LabDashboardTrendingTestCount(string FromDate, string ToDate)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramsList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate)
            };
            ReportingDbContext reportingDbContext = new ReportingDbContext(_options);
            DataTable data = DALFunctions.GetDataTableFromStoredProc("SP_Dashboard_LAB_TrendingLabTest", paramsList, reportingDbContext);

            return data;
        }
        #endregion

        #region This will return datatable for Lab Dashboard Test Completed Today
        public DataTable LabDashboardTestDoneToday()
        {
            ReportingDbContext reportingDbContext = new ReportingDbContext(_options);
            DataTable data = DALFunctions.GetDataTableFromStoredProc("SP_Dashboard_LAB_TestCompleteToday", reportingDbContext);

            return data;
        }
        #endregion
      
        #region This will return datatable for Lab Dashboard Dengue Details
        public DataTable LabDashboardDengueTestDetails()
        {
            ReportingDbContext reportingDbContext = new ReportingDbContext(_options);
            DataTable data = DALFunctions.GetDataTableFromStoredProc("SP_Dashboard_LAB_DangueTestDetails", reportingDbContext);

            return data;
        }
        #endregion

        #region This will return datatable for Lab Dashboard TestReq Details
        public DynamicReport LabDashboardTestReqDetails()
        {
            ReportingDbContext reportingDbContext = new ReportingDbContext(_options);
            DataSet dataTables = DALFunctions.GetDatasetFromStoredProc("SP_Dashboard_LAB_TestReqDetails",null, reportingDbContext);
            DynamicReport dReport = new DynamicReport();
            if (dataTables.Tables.Count > 0)
            {
                var data = new
                {
                    LabReqTillNow = dataTables.Tables[0],
                    LabReqToday = dataTables.Tables[1]
                };
                dReport.Schema = null;
                dReport.JsonData=JsonConvert.SerializeObject(data);               
            }
            return dReport;
        }
        #endregion

        #region This will return datatable for Lab Dashboard TestReq Details
        public DynamicReport LabDashboardNormalAbnormalDetails(int labTestId)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramsList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            {
                new Microsoft.Data.SqlClient.SqlParameter("@labTestId", labTestId)
            };
            ReportingDbContext reportingDbContext = new ReportingDbContext(_options);
            DataSet dataTables = DALFunctions.GetDatasetFromStoredProc("SP_Dashboard_LAB_AbnormalNormalTestCount", paramsList, reportingDbContext);
            DynamicReport dReport = new DynamicReport();
            if (dataTables.Tables.Count > 0)
            {
                var data = new
                {
                    NoramlTestResultCount = dataTables.Tables[0],
                    AbnoramlTestResultCount = dataTables.Tables[1],
                    NoOfVisitsThatUsesLabService = dataTables.Tables[2]
                };
                dReport.Schema = null;
                dReport.JsonData = JsonConvert.SerializeObject(data);
            }
            return dReport;
        }
        #endregion

        #region Department Wise Rank Count
        public DataTable DepartmentWiseRankCountReport(DateTime FromDate, DateTime ToDate, string DepartmentIds, string RankNames)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramsList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate),
                new Microsoft.Data.SqlClient.SqlParameter("@DepartmentIds", DepartmentIds),
                new Microsoft.Data.SqlClient.SqlParameter("@RankNames", RankNames)
            };
            ReportingDbContext reportingDbContext = new ReportingDbContext(_options);
            DataTable data = DALFunctions.GetDataTableFromStoredProc("SP_RPT_DepartmentWiseRankCountReport", paramsList, reportingDbContext);

            return data;
            
        }
        #endregion

        #region Rank-Membership-Wise-Discharge Patient Report
        public DataTable RankMembershipWiseDischargePatientReport(DateTime FromDate, DateTime ToDate, string Membership, string Rank)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramsList = new List<Microsoft.Data.SqlClient.SqlParameter>()
            {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate),
                new Microsoft.Data.SqlClient.SqlParameter("@MembershiptTypeIds", Membership),
                new Microsoft.Data.SqlClient.SqlParameter("@Rank", Rank)
            };
            ReportingDbContext reportingDbContext = new ReportingDbContext(_options);
            DataTable data = DALFunctions.GetDataTableFromStoredProc("SP_RPT_RankMembershipwiseDischargedPatientReport", paramsList, reportingDbContext);

            return data;

        }
        #endregion
        #region Inpatient Outstanding Report
        public DataTable InpatientOutstandingReport(string Operator,decimal? Amount)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() { new Microsoft.Data.SqlClient.SqlParameter("@Operator", Operator), new Microsoft.Data.SqlClient.SqlParameter("@Amount", Amount) };
            DataTable data = DALFunctions.GetDataTableFromStoredProc("SP_RPT_Admission_InPatientOutstandingReport", paramList, (Microsoft.EntityFrameworkCore.DbContext)this);
            return data;
        }
        #endregion
    }
}
