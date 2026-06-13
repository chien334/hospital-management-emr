using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;
using DsfEMR.Core.Configuration;
using DsfEMR.Security;
using DsfEMR.Utilities;

namespace DsfEMR.Controllers
{
    public class DashboardViewController : Controller
    {
        private readonly string config = null;
        public DashboardViewController(IOptions<MyConfiguration> _config)
        {
            config = _config.Value.Connectionstring;
        }
        public IActionResult DashBoardStatistics()
        {
            return View();
        }
     

    }
}
