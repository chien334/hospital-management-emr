using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using DanpheEMR.ServerModel;
using DanpheEMR.ServerModel.HelpdeskModels;
using DanpheEMR.ServerModel.ReportingModels;
using Microsoft.Data.SqlClient;
using System.Data;
using Newtonsoft.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using System.Data.Common;

namespace DanpheEMR.DalLayer
{
    public class HelpdeskDbContext : DbContext
    {
        private string connStr = null;
        public DbSet<EmployeeInfoModel> EmployeeInfo { get; set; }
        public DbSet<BedInformationModel> BedInfo { get; set; }
        public DbSet<WardInformationModel> WardInfo { get; set; }
        public HelpdeskDbContext(DbContextOptions<HelpdeskDbContext> options) : base(options)
        {
            // ...existing code...
        }
        public List<EmployeeInfoModel> GetEmployeeInfo()
        {
            // EF Core does not support Database.SqlQuery directly; use FromSqlRaw or similar if needed
            // Placeholder for actual implementation
            throw new NotImplementedException("Implement using EF Core's FromSqlRaw or similar method.");
        }
        //below two storedprocs needs to be changed, they're not updated after ADT module was updated.--sud:16Aug'17
        #region GetData From stored procedure
        private DataSet GetDatasetFromStoredProc(string storedProcName, List<SqlParameter> ipParams, string connString)
        {
            // This method should be refactored to use EF Core's Database.GetDbConnection()
            throw new NotImplementedException("Refactor this method for EF Core compatibility.");
        }

        #endregion

        public DynamicReport GetBedInformation()
        {
            List<SqlParameter> paramsList = new List<SqlParameter>();

            DataSet data = GetDatasetFromStoredProc("sp_BedInformation", paramsList, this.connStr);
            DynamicReport dReport = new DynamicReport();
            //return an anonymous type - when mutliple table are received
            var bedinfo = new
            {
                LabelData = data.Tables[0],
                BedList = data.Tables[1]
            };
            dReport.Schema = null;
            dReport.JsonData = JsonConvert.SerializeObject(bedinfo);
            return dReport;
        }
        public List<WardInformationModel> GetWardInformation()
        {
            var Data = Database.SqlQuery<WardInformationModel>("SP_ADT_GetBedOccupanciesOfAllWards");
            return Data.ToList<WardInformationModel>();
        }

        #region Bed feature Report
        public DataTable GetBedOccupancyOfWards()
        {
           
            DataTable bedfeature = DALFunctions.GetDataTableFromStoredProc("SP_ADT_GetBedOccupanciesOfAllWards", this);
            return bedfeature;
        }
        #endregion

    }
}
