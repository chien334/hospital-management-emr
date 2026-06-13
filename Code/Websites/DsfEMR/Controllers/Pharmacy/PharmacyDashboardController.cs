using DsfEMR.CommonTypes;
using DsfEMR.Core.Configuration;
using DsfEMR.DalLayer;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;
using System.Collections.Generic;
using Microsoft.Data.SqlClient;
using System.Data;
using System.Threading.Tasks;
using System;
using DsfEMR.Enums;

namespace DsfEMR.Controllers.Pharmacy
{
    public class PharmacyDashboardController : Controller
    {
        private readonly string connString = null;
        private PharmacyDbContext pharmacyDbContext;
        public DsfHTTPResponse<object> responseData = new DsfHTTPResponse<object>();
        public PharmacyDashboardController(IOptions<MyConfiguration> _config)
        {
            connString = _config.Value.Connectionstring;
            pharmacyDbContext = new PharmacyDbContext(connString);
        }
        public async Task<IActionResult> GetPharmacyDashboardCardSummaryCalculation(DateTime FromDate, DateTime ToDate)
        {
            try
            {
                List<SqlParameter> paramList = new List<SqlParameter>()  {
                            new SqlParameter("@FromDate", FromDate),
                            new SqlParameter("@ToDate", ToDate)
            };
                DataSet dataSet = await Task.Run(() => DALFunctions.GetDatasetFromStoredProc("SP_Dashboard_PHRM_CardSummaryCalculation", paramList, pharmacyDbContext));

                var results = new
                {
                    Sales = dataSet.Tables[0],
                    GoodReceipts = dataSet.Tables[1],
                    Dispatchs = dataSet.Tables[2],
                    Stocks = dataSet.Tables[3]
                };
                responseData.Results = results;
                responseData.Status = ENUM_DsfHttpResponseText.OK;
            }
            catch (Exception ex)
            {
                responseData.Status = ENUM_DsfHttpResponseText.Failed;
                responseData.ErrorMessage = ex.Message;
            }
            return Ok(responseData);
        }

        public async Task<IActionResult> GetPharmacyDashboardSubstoreWiseDispatchValue(DateTime FromDate, DateTime ToDate)
        {
            try
            {
                List<SqlParameter> paramList = new List<SqlParameter>()  {
                            new SqlParameter("@FromDate", FromDate),
                            new SqlParameter("@ToDate", ToDate)
            };
                DataTable result = await Task.Run(() => DALFunctions.GetDataTableFromStoredProc("SP_Dashboard_PHRM_SubstoreWiseDispatchValue", paramList, pharmacyDbContext));
                responseData.Results = result;
                responseData.Status = ENUM_DsfHttpResponseText.OK;
            }
            catch (Exception ex)
            {
                responseData.Status = ENUM_DsfHttpResponseText.Failed;
                responseData.ErrorMessage = ex.Message;
            }
            return Ok(responseData);
        }

        public async Task<IActionResult> GetPharmacyDashboardMembershipWiseMedicineSale(DateTime FromDate, DateTime ToDate)
        {
            try
            {
                List<SqlParameter> paramList = new List<SqlParameter>()  {
                            new SqlParameter("@FromDate", FromDate),
                            new SqlParameter("@ToDate", ToDate)
            };
                DataTable result = await Task.Run(() => DALFunctions.GetDataTableFromStoredProc("SP_Dashboard_PHRM_MembershipWiseMedicineSale", paramList, pharmacyDbContext));
                responseData.Results = result;
                responseData.Status = ENUM_DsfHttpResponseText.OK;
            }
            catch (Exception ex)
            {
                responseData.Status = ENUM_DsfHttpResponseText.Failed;
                responseData.ErrorMessage = ex.Message;
            }
            return Ok(responseData);
        }
        public async Task<IActionResult> GetPharmacyDashboardMostSoldMedicine(DateTime FromDate, DateTime ToDate)
        {
            try
            {
                List<SqlParameter> paramList = new List<SqlParameter>()  {
                            new SqlParameter("@FromDate", FromDate),
                            new SqlParameter("@ToDate", ToDate)
            };
                DataTable result = await Task.Run(() => DALFunctions.GetDataTableFromStoredProc("SP_Dashboard_PHRM_MostSoldMedicine", paramList, pharmacyDbContext));
                responseData.Results = result;
                responseData.Status = ENUM_DsfHttpResponseText.OK;
            }
            catch (Exception ex)
            {
                responseData.Status = ENUM_DsfHttpResponseText.Failed;
                responseData.ErrorMessage = ex.Message;
            }
            return Ok(responseData);
        }
    }
}
