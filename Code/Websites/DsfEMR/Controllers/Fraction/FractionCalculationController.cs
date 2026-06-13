using System;
using Microsoft.AspNetCore.Mvc;
using DsfEMR.ServerModel;
using DsfEMR.Utilities;
using DsfEMR.CommonTypes;
using DsfEMR.Services;
using DsfEMR.Security;

namespace DsfEMR.Controllers
{
    [Route("api/[controller]")]
    public class FractionCalculationController : Controller
    {

        public IFractionCalculationService _FractionCalculationService;
        public DsfHTTPResponse<object> responseData = new DsfHTTPResponse<object>();

        public FractionCalculationController( IFractionCalculationService FractionCalculationService) 
        {
            _FractionCalculationService = FractionCalculationService;
        }

        [HttpGet]
        public IActionResult GetAll()
        {

            try
            {
                responseData.Results = _FractionCalculationService.ListFractionCalculation();
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
        public IActionResult Get(int id)
        {
            try
            {
                responseData.Results = _FractionCalculationService.GetFractionCalculation(id);
                responseData.Status = "OK";

            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message + " exception details:" + ex.ToString();
            }
            return Ok(responseData);
        }

        [HttpPost]
        public IActionResult Post([FromBody]FractionCalculationModel[] value)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }
                RbacUser currentUser = HttpContext.Session.Get<RbacUser>("currentuser");
                //value.CreatedBy = currentUser.EmployeeId;
                //responseData.Results = _FractionCalculationService.GetFractionCalculation(value.FractionCalculationId);
                responseData.Results = _FractionCalculationService.AddFractionCalculation(value);
                responseData.Status = "OK";
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message + " exception details:" + ex.ToString();
            }
            return Ok(responseData);
        }

        [HttpPut("{id}")]
        public IActionResult Put(int id, [FromBody]FractionCalculationModel value)
        {            
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }
                value.FractionCalculationId = id;
                _FractionCalculationService.UpdateFractionCalculation(value);
                responseData.Results = _FractionCalculationService.GetFractionCalculation(id);
                responseData.Status = "OK";
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message + " exception details:" + ex.ToString();
            }
            return Ok(responseData);
        }

        [HttpGet("~/api/GetFractionTxnList")]
        public IActionResult GetFractionTxnList()
        {
            return Ok(_FractionCalculationService.GetFractionTxnList());
        }
        [HttpGet("~/api/GetFractionReportByItemList")]
        public IActionResult GetFractionReportByItemList()
        {
            return Ok(_FractionCalculationService.GetFractionReportByItemList());
        }
        [HttpGet("~/api/GetFractionReportByDoctorList/{FromDate}/{ToDate}")]
        public IActionResult GetFractionReportByDoctorList(DateTime FromDate, DateTime ToDate)
        {
            return Ok(_FractionCalculationService.GetFractionReportByDoctorList(FromDate, ToDate));
        }
    }
}
