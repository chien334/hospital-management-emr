using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;
using DsfEMR.Core.Configuration;

// For more information on enabling MVC for empty projects, visit http://go.microsoft.com/fwlink/?LinkID=397860
using DsfEMR.ServerModel;
using DsfEMR.DalLayer;
using DsfEMR.Security;
using DsfEMR.Utilities;

namespace DsfEMR.Controllers.Lab
{
    public class LabViewController : Controller
    {
        private readonly string config = null;
        public LabViewController(IOptions<MyConfiguration> _config)
        {
            config = _config.Value.Connectionstring;

        }
        public IActionResult GetView(string urlFullPath, string viewPath)
        {
            //Get Valid Route List for logged in user
            List<DsfRoute> validRouteList = HttpContext.Session.Get<List<DsfRoute>>("validRouteList");
            if (validRouteList != null || validRouteList.Count > 0)
            {
                List<DsfRoute> validRoutes = validRouteList.Where(a => a.UrlFullPath == urlFullPath).ToList();
                if (validRoutes != null && validRoutes.Count > 0)
                {
                    //Return view for valid user
                    return View(viewPath);
                }
                else
                {
                    //Return content with message for unauthorized user
                    return Content("<div>Page Not Found</div><router-outlet></router-outlet>");
                }
            }
            else
            {
                //Return content with message for unauthorized user
                return Content("<div>Page Not Found</div><router-outlet></router-outlet>");
            }
        }
        // GET: /<controller>/
        public IActionResult LabMain()
        {
            try
            {
                //RbacUser currentUser = HttpContext.Session.Get<RbacUser>("currentuser");
                //List<DsfRoute> childRoutes = RBAC.GetChildRoutesForUser(currentUser.UserId, urlFullPath: "Lab");
                //ViewData["validroutes"] = childRoutes;
                return this.GetView("Lab", "LabMain");                
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }
        public IActionResult ListLabRequisition()
        {
            try
            {
                var dal = new DalLayer.MasterDbContext(config);

                ViewData["ConnectionString"] = config;
                return this.GetView("Lab/Requisition", "ListLabRequisition");                
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }
        public IActionResult PendingLabResults()

        {
            try
            {
                ViewData["ConnectionString"] = config;
                return this.GetView("Lab/PendingLabResults", "PendingLabResults");                
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }
        public IActionResult SelectLabTests()
        {
            try
            {
                var dal = new DalLayer.MasterDbContext(config);

                ViewData["ConnectionString"] = config;
               // return this.GetView("Lab/PendingLabResults", "SelectLabTests");
                return View("SelectLabTests");
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }
       
        public IActionResult CollectSampleLabTests()
        {
            try
            {              
                ViewData["ConnectionString"] = config;
                return this.GetView("Lab/CollectSample", "CollectSampleLabTests");                
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }
        public IActionResult AddResult()
        {
            try
            {
                ViewData["ConnectionString"] = config;
                return this.GetView("Lab/AddResult", "AddResult");                
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }
        public IActionResult PatientTemplateList()
        {
            try
            {
                ViewData["ConnectionString"] = config;
                return this.GetView("Lab/PatientTemplateList", "PatientTemplateList");
                
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }
        public IActionResult ListPatientReport()
        {
            try
            {
                ViewData["ConnectionString"] = config;
                return this.GetView("Lab/ListPatientReport", "ListPatientReport");                
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }
        public IActionResult ViewAllReport()
        {
            try
            {
                ViewData["ConnectionString"] = config;
                return this.GetView("Lab/ViewAllReport", "ViewAllReport");
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        // GET: /<controller>/
        [DsfViewFilter("lab-settings-view")]
        public IActionResult LabSettingsMain()
        {
            try
            {
                return View();
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

       

    }
}
