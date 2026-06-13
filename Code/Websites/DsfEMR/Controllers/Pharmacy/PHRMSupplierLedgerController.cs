using DsfEMR.CommonTypes;
using DsfEMR.Security;
using DsfEMR.Services.Pharmacy.SupplierLedger;
using DsfEMR.Utilities;
using DsfEMR.ViewModel.Pharmacy;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace DsfEMR.Controllers.Pharmacy
{
    [RequestFormSizeLimit(valueCountLimit: 1000000, Order = 1)]
    [DsfDataFilter()]
    [Route("api/[controller]")]
    public class PHRMSupplierLedgerController : Controller
    {
        #region DECLARATIONS
        private ISupplierLedgerService _supplierLedgerService;
        public DsfHTTPResponse<object> responseData = new DsfHTTPResponse<object>();
        #endregion

        #region CTOR
        public PHRMSupplierLedgerController(ISupplierLedgerService PHRMSupplierLedgerController)
        {
            _supplierLedgerService = PHRMSupplierLedgerController;
        }
        #endregion

        #region METHODS, APIs
        [HttpGet()]
        public async Task<IActionResult> GetAll()
        {
            try
            {
                responseData.Results = await _supplierLedgerService.GetAllAsync();
                responseData.Status = "OK";
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message + " exception details:" + ex.ToString();
            }
            return Ok(responseData);

        }

        [HttpGet("{id}")]
        public async Task<IActionResult> Get(int supplierId)
        {
            try
            {
                responseData.Results = await _supplierLedgerService.GetSupplierLedgerGRDetails(supplierId);
                responseData.Status = "OK";
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message + " exception details:" + ex.ToString();
            }
            return Ok(responseData);
        }


        [HttpPut]
        public IActionResult MakeSupplierLedgerPayment([FromBody] IList<MakeSupplierLedgerPaymentVM> ledgerTxn)
        {
            try
            {
                var currentUser = HttpContext.Session.Get<RbacUser>("currentuser");
                responseData.Results = _supplierLedgerService.MakeSupplierLedgerPayment(ledgerTxn, currentUser);
                responseData.Status = "OK";
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message;
            }
            return Ok(responseData);
        }
        #endregion
    }
}
