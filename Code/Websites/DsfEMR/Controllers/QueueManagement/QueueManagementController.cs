using DsfEMR.CommonTypes;
using DsfEMR.Core.Configuration;
using DsfEMR.Security;
using DsfEMR.Services.QueueManagement;
using DsfEMR.Utilities;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

// For more information on enabling Web API for empty projects, visit https://go.microsoft.com/fwlink/?LinkID=397860

namespace DsfEMR.Controllers.QueueManagement
{
    [Route("api/[controller]")]
    public class QueueManagementController : CommonController
    {
        IQueueManagementService _queueManagementService;
        public DsfHTTPResponse<object> responseData = new DsfHTTPResponse<object>();
        public QueueManagementController(IQueueManagementService queueManagementService,IOptions<MyConfiguration> _config) : base(_config)
        {
            _queueManagementService = queueManagementService;
        }
        // GET: api/<QueueManagementController>
        [Route("GetAllApptDepartment")]
        [HttpGet]
        public IActionResult GetAllApptDepartment()
        {
            try
            {
                responseData.Results = _queueManagementService.GetDepartment();
                responseData.Status = "OK";
                return Ok(responseData);
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message + " exception details:" + ex.ToString();
                return BadRequest(responseData);
            }
        }

        [Route("GetAppointmentData")]
        [HttpGet]
        public IActionResult GetAppointmentData(int deptId, int doctorId,bool pendingOnly)
        {
            try
            {
                responseData.Results = _queueManagementService.GetAppointmentData(deptId, doctorId, pendingOnly);
                responseData.Status = "OK";
                return Ok(responseData);
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message + " exception details:" + ex.ToString();
                return BadRequest(responseData);
            }
        }
        [Route("GetAllAppointmentApplicableDoctor")]
        [HttpGet]
        public IActionResult GetAllAppointmentApplicableDoctor()
        {
            try
            {
                responseData.Results = _queueManagementService.GetAllAppointmentApplicableDoctor();
                responseData.Status = "OK";
                return Ok(responseData);
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message + " exception details:" + ex.ToString();
                return BadRequest(responseData);
            }
        }
        // GET api/<QueueManagementController>/5
        [HttpGet("{id}")]
        public string Get(int id)
        {
            return "value";
        }


        // PUT api/<QueueManagementController>/5
        [Route("updateQueueStatus")]
        [HttpPut]
        public IActionResult updateQueueStatus(string data, int visitId)
        {
            try
            {
                RbacUser currentUser = HttpContext.Session.Get<RbacUser>("currentuser");
                responseData.Results = _queueManagementService.updateQueueStatus(data, visitId, currentUser);
                responseData.Status = "OK";
                return Ok(responseData);
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message + " exception details:" + ex.ToString();
                return BadRequest(responseData);
            }
        }
    }
}
