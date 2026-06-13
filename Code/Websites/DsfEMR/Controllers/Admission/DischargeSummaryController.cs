using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.AspNetCore.Mvc;
using DsfEMR.Core.Configuration;
using DsfEMR.ServerModel;
using DsfEMR.DalLayer;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using DsfEMR.Utilities;
using DsfEMR.CommonTypes;
using DsfEMR.Core.Caching;
using DsfEMR.Security;
using DsfEMR.Controllers.Billing;

namespace DsfEMR.Controllers
{
    public class DischargeSummaryController : CommonController
    {
        double cacheExpMinutes;//= 5;//this should come from configuration later on.

        public DischargeSummaryController(IOptions<MyConfiguration> _config) : base(_config)
        {
            cacheExpMinutes = _config.Value.CacheExpirationMinutes;
        }

        //[HttpGet]
        //public string Get(string reqType,
        //    int patientId, int patientVisitId,
        //    string admissionStatus, int wardId,
        //    int bedFeatureId, int ipVisitId,
        //    int bedId)
        //{
        //    DsfHTTPResponse<object> responseData = new DsfHTTPResponse<object>();
        //    try
        //    {
        //        AdmissionDbContext dbContext = new AdmissionDbContext(base.connString);
        //        MasterDbContext masterDbContext = new MasterDbContext(base.connString);



        //        if (reqType == "getADTList")
        //        {
        //            return "1vcncncvn";
        //        }
        //    }
        //    catch(Exception ex)
        //    {
        //        return "vcvbcnvn";
        //    }       
        //}
    }
}