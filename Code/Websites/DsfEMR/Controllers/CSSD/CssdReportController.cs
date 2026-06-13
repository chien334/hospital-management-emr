using DsfEMR.CommonTypes;
using DsfEMR.Security;
using DsfEMR.Services;
using DsfEMR.Utilities;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace DsfEMR.Controllers.CSSD
{
    [RequestFormSizeLimit(valueCountLimit: 1000000, Order = 1)]
    [DsfDataFilter()]
    [Route("api/[controller]")]
    public class CssdReportController : Controller
    {
        #region Fields
        private ICssdReportService _cssdReportService;
        public DsfHTTPResponse<object> responseData = new DsfHTTPResponse<object>();
        #endregion

        #region CTOR
        public CssdReportController(ICssdReportService cssdReportService)
        {
            _cssdReportService = cssdReportService;
        }
        #endregion

        #region Methods, APIs
        [HttpGet("GetIntegratedCssdReport")]
        public async Task<IActionResult> GetIntegratedCssdReport(DateTime FromDate, DateTime ToDate)
        {
            try
            {
                responseData.Results = await _cssdReportService.GetIntegratedCssdReport(FromDate, ToDate);
                responseData.Status = "OK";
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message + " exception details:" + ex.ToString();
            }
            return Ok(responseData);
        }
        #endregion
    }
}
