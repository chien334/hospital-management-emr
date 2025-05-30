using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;
using Microsoft.Data.SqlClient;
using System.Linq;
using DanpheEMR.ServerModel;
using System.Text;
using System.Threading.Tasks;
using System.Data;
using DanpheEMR.ServerModel.ReportingModels;
using Newtonsoft.Json;
using Newtonsoft.Json.Converters;

namespace DanpheEMR.DalLayer
{
    public class WardReportingDbContext : DbContext
    {
        private string connStr = null;
        public WardReportingDbContext(DbContextOptions<WardReportingDbContext> options) : base(options)
        {
            // ...existing code...
        }

        #region WARD Stock Items Report        
        public DataTable WARDStockItemsReport(int ItemId,int StoreId)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() { new Microsoft.Data.SqlClient.SqlParameter("@ItemId", ItemId),new Microsoft.Data.SqlClient.SqlParameter("@StoreId", StoreId) };
            foreach (Microsoft.Data.SqlClient.SqlParameter parameter in paramList)
            {
                if (parameter.Value == null)
                {
                    parameter.Value = "";
                }
            }
            DataTable stockItems = DALFunctions.GetDataTableFromStoredProc("SP_WardReport_StockReport", paramList, this as Microsoft.EntityFrameworkCore.DbContext);
            return stockItems;
        }
        #endregion

        #region WARD Requisition DataTable
        public DataTable WARDRequisitionReport(DateTime FromDate, DateTime ToDate,int StoreId)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                 new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate),
                 new Microsoft.Data.SqlClient.SqlParameter("@StoreId", StoreId)

            };

            foreach (Microsoft.Data.SqlClient.SqlParameter parameter in paramList)
            {
                if (parameter.Value == null)
                {
                    parameter.Value = "";

                }
            }
            DataTable stockItems = DALFunctions.GetDataTableFromStoredProc("SP_WardReport_RequisitionReport", paramList, this as Microsoft.EntityFrameworkCore.DbContext);
            return stockItems;
        }
        #endregion

        #region WARD Breakage DataTable
        public DataTable WARDBreakageReport(DateTime FromDate, DateTime ToDate,int StoreId)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                 new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate),
                 new Microsoft.Data.SqlClient.SqlParameter("@StoreId", StoreId)
            };

            foreach (Microsoft.Data.SqlClient.SqlParameter parameter in paramList)
            {
                if (parameter.Value == null)
                {
                    parameter.Value = "";

                }
            }
            DataTable stockItems = DALFunctions.GetDataTableFromStoredProc("SP_WardReport_BreakageReport", paramList, this as Microsoft.EntityFrameworkCore.DbContext);
            return stockItems;
        }
        #endregion

        #region WARD Consumption DataTable
        public DataTable WARDConsumptionReport(DateTime FromDate, DateTime ToDate,int StoreId)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                 new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate),
                 new Microsoft.Data.SqlClient.SqlParameter("@StoreId", StoreId)
            };

            foreach (Microsoft.Data.SqlClient.SqlParameter parameter in paramList)
            {
                if (parameter.Value == null)
                {
                    parameter.Value = "";

                }
            }
            DataTable stockItems = DALFunctions.GetDataTableFromStoredProc("SP_WardReport_ConsumptionReport", paramList, this as Microsoft.EntityFrameworkCore.DbContext);
            return stockItems;
        }
        #endregion



        #region WARD Internal Consumption DataTable
        public DataTable WARDInteranlConsumptionReport(DateTime FromDate, DateTime ToDate, int StoreId)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                 new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate),
                 new Microsoft.Data.SqlClient.SqlParameter("@StoreId", StoreId)
            };

            foreach (Microsoft.Data.SqlClient.SqlParameter parameter in paramList)
            {
                if (parameter.Value == null)
                {
                    parameter.Value = "";

                }
            }
            DataTable stockItems = DALFunctions.GetDataTableFromStoredProc("SP_WardReport_InternalConsumptionReport", paramList, this as Microsoft.EntityFrameworkCore.DbContext);
            return stockItems;
        }
        #endregion

        #region WARD Transfer DataTable
        public DataTable WARDTransferReport(DateTime FromDate, DateTime ToDate,int StoreId)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() {
                 new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                 new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate),
                 new Microsoft.Data.SqlClient.SqlParameter("@StoreId", StoreId)
            };

            foreach (Microsoft.Data.SqlClient.SqlParameter parameter in paramList)
            {
                if (parameter.Value == null)
                {
                    parameter.Value = "";

                }
            }
            DataTable stockItems = DALFunctions.GetDataTableFromStoredProc("SP_WardReport_TransferReport", paramList, this as Microsoft.EntityFrameworkCore.DbContext);
            return stockItems;
        }
        #endregion

        ///WARD INVENTORY REPORT
        #region WARD Inventory Requisition and Dispatch Report
        public DataTable RequisitionDispatchReport(DateTime FromDate, DateTime ToDate,int StoreId)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                 new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate),
                 new Microsoft.Data.SqlClient.SqlParameter("@StoreId", StoreId)
            };

            foreach (Microsoft.Data.SqlClient.SqlParameter parameter in paramList)
            {
                if (parameter.Value == null)
                {
                    parameter.Value = "";

                }
            }
            DataTable stockItems = DALFunctions.GetDataTableFromStoredProc("SP_WardInv_Report_RequisitionDispatchReport", paramList, this as Microsoft.EntityFrameworkCore.DbContext);
            return stockItems;
        }
        #endregion

        #region WARD Inventory Transfer Report
        public DataTable TransferReport(DateTime FromDate, DateTime ToDate,int StoreId)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                 new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate),
                 new Microsoft.Data.SqlClient.SqlParameter("@StoreId", StoreId)
            };

            foreach (Microsoft.Data.SqlClient.SqlParameter parameter in paramList)
            {
                if (parameter.Value == null)
                {
                    parameter.Value = "";

                }
            }
            DataTable stockItems = DALFunctions.GetDataTableFromStoredProc("SP_WardInv_Report_TransferReport", paramList, this as Microsoft.EntityFrameworkCore.DbContext);
            return stockItems;
        }
        #endregion

        #region WARD Inventory Consumption Report
        public DataTable ConsumptionReport(DateTime FromDate, DateTime ToDate, int StoreId)
        {
            List<Microsoft.Data.SqlClient.SqlParameter> paramList = new List<Microsoft.Data.SqlClient.SqlParameter>() {
                new Microsoft.Data.SqlClient.SqlParameter("@FromDate", FromDate),
                 new Microsoft.Data.SqlClient.SqlParameter("@ToDate", ToDate),
                 new Microsoft.Data.SqlClient.SqlParameter("@StoreId", StoreId)
            };

            foreach (Microsoft.Data.SqlClient.SqlParameter parameter in paramList)
            {
                if (parameter.Value == null)
                {
                    parameter.Value = "";

                }
            }
            DataTable stockItems = DALFunctions.GetDataTableFromStoredProc("SP_WardInv_Report_ConsumptionReport", paramList, this as Microsoft.EntityFrameworkCore.DbContext);
            return stockItems;
        }
        #endregion
    }
}
