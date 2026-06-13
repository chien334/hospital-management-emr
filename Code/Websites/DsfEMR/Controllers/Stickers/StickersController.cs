using DsfEMR.CommonTypes;
using DsfEMR.Controllers.Stickers.DTOs;
using DsfEMR.Core.Configuration;
using DsfEMR.DalLayer;
using DsfEMR.Enums;
using DsfEMR.Security;
using DsfEMR.ServerModel;
using DsfEMR.Utilities;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Data;
using Microsoft.Data.SqlClient;
using System.Linq;
using System.Threading.Tasks;

namespace DsfEMR.Controllers
{
    [Route("api/[controller]")]
    public class StickersController : CommonController
    {
        private readonly MasterDbContext _masterDbContext;
        DsfHTTPResponse<object> responseData = new DsfHTTPResponse<object>();
        public StickersController(IOptions<MyConfiguration> _config) : base(_config)
        {
            _masterDbContext = new MasterDbContext(connString);

        }
        [HttpGet]
        [Route("GetPatientStickerDetails")]
        public string GetPatientStickerDetails(int PatientId)
        {
            DsfHTTPResponse<List<PatientStickerModel>> responseData = new DsfHTTPResponse<List<PatientStickerModel>>();
            try
            {
                PatientDbContext patDbContext = new PatientDbContext(connString);
                StickersBL stick = new StickersBL();
                var res = stick.GetPatientStickerDetails(patDbContext, PatientId);
                responseData.Status = "OK";
                responseData.Results = res;
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message;
            }
            return DsfJSONConvert.SerializeObject(responseData);
        }

        [HttpGet]
        [Route("RegistrationStickerSettingsAndData")]
        public IActionResult RegistrationStickerSettingsAndData(int PatientVisitId)
        {         
            Func<object> func = () => GetRegistrationStickerSettingsAndData(PatientVisitId);
            return InvokeHttpGetFunction(func);
        }
        private object GetRegistrationStickerSettingsAndData(int PatientVisitId)
        {
            List<SqlParameter> paramList = new List<SqlParameter>() {
                        new SqlParameter("@PatientVisitId", PatientVisitId)
                    };

            DataSet dataset = DALFunctions.GetDatasetFromStoredProc("SP_VIS_GetVisitStickerSettingsAndData", paramList, _masterDbContext);
            DataTable stickersettings = dataset.Tables[0];
            DataTable stickerdata = dataset.Tables[1];
            StickerSettingsAndData_DTO settingsAndData_DTO = new StickerSettingsAndData_DTO();
            settingsAndData_DTO.StickerSettings = RegistrationStickerSettings_DTO.MapDataTableToSingleObject(stickersettings);
            settingsAndData_DTO.StickerData = VisitStickerData_DTO.MapDataTableToSingleObject(stickerdata);
            return (settingsAndData_DTO);
        }
    }
}
