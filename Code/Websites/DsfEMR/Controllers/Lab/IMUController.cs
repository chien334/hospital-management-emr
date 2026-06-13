using DsfEMR.CommonTypes;
using DsfEMR.Core;
using DsfEMR.Core.Configuration;
using DsfEMR.DalLayer;
using DsfEMR.Security;
using DsfEMR.ServerModel.IMUDTOs;
using DsfEMR.Services.IMU;
using DsfEMR.Utilities;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

// For more information on enabling Web API for empty projects, visit https://go.microsoft.com/fwlink/?LinkID=397860

namespace DsfEMR.Controllers.Lab
{
    [Route("api/[controller]")]
    public class IMUController : CommonController
    {
        IIMUService _imuService;
        public DsfHTTPResponse<object> responseData = new DsfHTTPResponse<object>();
        public IMUController(IIMUService imuService,IOptions<MyConfiguration> _config) : base(_config)
        {
            _imuService = imuService;
        }

        // GET: api/<IMUController>
        [HttpGet]
        [Route("GetAllImuTestList")]
        public async Task<IActionResult> GetAllImuTestList(DateTime fromDate, DateTime toDate)
        {
            try
            {
                LabDbContext labDbContext = new LabDbContext(connString);
                responseData.Results = await _imuService.GetAllImuTestData(labDbContext, fromDate, toDate);
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

        // GET api/<IMUController>/5
        [HttpGet("{id}")]
        public string Get(int id)
        {
            return "value";
        }

        // POST api/<IMUController>
        [HttpPost]
        [Route("PostDataToIMU")]
        public async Task<IActionResult> PostDataToIMU(string value)
        {
            try
            {
                RbacUser currentUser = HttpContext.Session.Get<RbacUser>("currentuser");
                IMUResponseModel res = new IMUResponseModel();
                LabDbContext labDbContext = new LabDbContext(connString);
                CoreDbContext coreDbContext = new CoreDbContext(connString);
                List<Int64> reqIdList = DsfJSONConvert.DeserializeObject<List<Int64>>(value);
                res = await _imuService.PostDataToIMU(labDbContext,coreDbContext,reqIdList, currentUser);
                if(res.status == 200)
                {
                    responseData.Results = res.message;
                    responseData.Status = "OK";
                    return Ok(responseData);
                }
                else
                {
                    responseData.ErrorMessage = res.message;
                    responseData.Status = "Failed";
                    return BadRequest(responseData);
                }
            }
            catch(Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message + "exception details:" + ex.ToString();
                return BadRequest(responseData);
            }
        }

        // PUT api/<IMUController>/5
        [HttpPut("{id}")]
        public void Put(int id, [FromBody] string value)
        {
        }

        // DELETE api/<IMUController>/5
        [HttpDelete("{id}")]
        public void Delete(int id)
        {
        }
    }
}
