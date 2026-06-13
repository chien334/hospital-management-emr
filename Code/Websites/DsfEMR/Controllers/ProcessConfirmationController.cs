using DsfEMR.Core.Configuration;
using DsfEMR.DalLayer;
using DsfEMR.Security;
using DsfEMR.Services.ProcessConfirmation;
using DsfEMR.Services.ProcessConfirmation.DTO;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;
using System;
using System.Collections.Generic;
using System.Linq;
/* using System.Web.Security; */

namespace DsfEMR.Controllers
{

    public class ProcessConfirmationController : CommonController
    {
        private readonly IProcessConfirmationService _processConfirmationService;

        public ProcessConfirmationController(IOptions<MyConfiguration> _config, IProcessConfirmationService processConfirmationService) : base(_config)
        {
            _processConfirmationService = processConfirmationService;
        }

        [HttpPost]
        [Route("ConfirmProcess")]
        public IActionResult PostConfirmProcess([FromBody] ProcessConfirmationUserCredentials_DTO processConfirmationUserCredentials)
        {
            Func<object> func = () => _processConfirmationService.ConfirmProcess(processConfirmationUserCredentials);
            return InvokeHttpPostFunction(func);
        }
    }
}
