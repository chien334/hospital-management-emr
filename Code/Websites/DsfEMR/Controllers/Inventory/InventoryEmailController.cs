using System;
using Microsoft.AspNetCore.Mvc;
using DsfEMR.ServerModel;
using DsfEMR.Utilities;
using DsfEMR.CommonTypes;
using DsfEMR.Services;
using DsfEMR.Security;
using DsfEMR.ViewModel;
using DsfEMR.Core.Configuration;
using Microsoft.Extensions.Options;
using DsfEMR.DalLayer;

namespace DsfEMR.Controllers
{
    [Route("api/[controller]")]
    public class InventoryEmailController : CommonController
    {

        public IEmailService _emailService;
        public DsfHTTPResponse<object> responseData = new DsfHTTPResponse<object>();

        public InventoryEmailController(IOptions<MyConfiguration> _config, IEmailService emailService) : base(_config)
        {
            _emailService = emailService;
        }

        [HttpGet]
        public IActionResult Get()
        {
            return Ok("hello");
        }
        
        [HttpPost]
        public IActionResult Post([FromBody]EmailViewModel value)
        {
            try
            {                
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }
                var emailList = value.EmailAddress.Split(';');
                value.EmailAddressList = new System.Collections.Generic.List<String>();
                foreach (var email in emailList)
                {
                    value.EmailAddressList.Add(email);
                }

                var apiKey = "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";

                responseData.Results = _emailService.SendEmail("info@hamshospital.org", value.EmailAddressList,"HAMS HOSPITAL", value.Subject, "", value.Content, apiKey);
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
