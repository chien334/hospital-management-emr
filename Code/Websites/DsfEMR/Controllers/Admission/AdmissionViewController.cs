using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;
using DsfEMR.Core.Configuration;
using DsfEMR.Security;
using DsfEMR.Utilities;

// For more information on enabling MVC for empty projects, visit http://go.microsoft.com/fwlink/?LinkID=397860

namespace DsfEMR.Controllers
{
    public class AdmissionViewController : Controller
    {
        private readonly string config = null;
        public AdmissionViewController(IOptions<MyConfiguration> _config)
        {
            config = _config.Value.Connectionstring;

        }
        // GET: /<controller>/
        [DsfViewFilter("adt-createadmission-view")]
        public IActionResult AdmissionCreate()
        {
            try
            {
                ViewData["ConnectionString"] = config;
                return View("CreateAdmission");
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }
        [DsfViewFilter("adt-admissionsearchpatient-view")]
        public IActionResult AdmissionSearchPatient()
        {
            try
            {
                return View("AdmissionSearchPatient");
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }
        [DsfViewFilter("adt-admittedlist-view")]
        public IActionResult AdmittedList()
        {
            try
            {
                return View("AdmittedList");
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }
        [DsfViewFilter("adt-dischargedlist-view")]
        public IActionResult DischargedList()
        {
            try
            {
                return View("DischargedList");
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }
        [DsfViewFilter("adt-view")]
        public IActionResult Admission()
        {
            try
            {
                return View("Admission");
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }
    }
}
