using DsfEMR.CommonTypes;
using DsfEMR.Services;
using Microsoft.AspNetCore.Mvc;
using System;

namespace DsfEMR.Controllers
{
    [Route("api/[controller]")]
    public class ActivateInventoryController : Controller
    {
        private IActivateInventoryService _activateInventory;
        public DsfHTTPResponse<object> responseData = new DsfHTTPResponse<object>();

        public ActivateInventoryController(IActivateInventoryService activateInventory)
        {
            _activateInventory = activateInventory;
        }

        [HttpGet]
        public IActionResult GetAll()
        {

            try
            {
                responseData.Results = _activateInventory.GetAllInventories();
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
                responseData.Results = _activateInventory.GetInventory(id);
                responseData.Status = "OK";
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message + " exception details:" + ex.ToString();
            }
            return Ok(responseData);
        }
    }
}
