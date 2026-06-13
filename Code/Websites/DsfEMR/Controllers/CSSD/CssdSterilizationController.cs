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
    public class CSSDSterilizationController : Controller
    {
        #region Fields
        private ICssdItemService _cssdItemService;
        public DsfHTTPResponse<object> responseData = new DsfHTTPResponse<object>();
        #endregion

        #region CTOR
        public CSSDSterilizationController(ICssdItemService cssdItemService)
        {
            _cssdItemService = cssdItemService;
        }
        #endregion

        #region Methods
        [HttpGet("GetAllPendingCSSDTransactions")]
        public async Task<IActionResult> GetAllPendingCSSDTransactions(DateTime FromDate, DateTime ToDate)
        {
            try
            {
                responseData.Results = await _cssdItemService.GetAllPendingCSSDTransactions(FromDate, ToDate);
                responseData.Status = "OK";
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message + " exception details:" + ex.ToString();
            }
            return Ok(responseData);
        }
        [HttpGet("GetAllFinalizedCSSDTransactions")]
        public async Task<IActionResult> GetAllFinalizedCSSDTransactions(DateTime FromDate, DateTime ToDate)
        {
            try
            {
                responseData.Results = await _cssdItemService.GetAllFinalizedCSSDTransactions(FromDate, ToDate);
                responseData.Status = "OK";
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message + " exception details:" + ex.ToString();
            }
            return Ok(responseData);
        }
        [HttpPut("DisinfectCSSDItem")]
        public async Task<IActionResult> DisinfectCSSDItem(int CssdTxnId, string DisinfectantName, string DisinfectionRemarks)
        {
            try
            {
                RbacUser currentUser = HttpContext.Session.Get<RbacUser>("currentuser");
                responseData.Results = await _cssdItemService.DisinfectCSSDItem(CssdTxnId, DisinfectantName, DisinfectionRemarks, currentUser);
                responseData.Status = "OK";
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message + " exception details:" + ex.ToString();
            }
            return Ok(responseData);
        }

        [HttpPut("DispatchCSSDItem")]
        public async Task<IActionResult> DispatchCSSDItem(int CssdTxnId, string DispatchRemarks)
        {
            try
            {
                RbacUser currentUser = HttpContext.Session.Get<RbacUser>("currentuser");
                responseData.Results = await _cssdItemService.DispatchCSSDItem(CssdTxnId, DispatchRemarks, currentUser);
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
