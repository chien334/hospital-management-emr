using DsfEMR.Core;
using DsfEMR.DalLayer;
using DsfEMR.Security;
using DsfEMR.ServerModel.IMUDTOs;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Threading.Tasks;

namespace DsfEMR.Services.IMU
{
    public interface IIMUService
    {
        Task <DataTable> GetAllImuTestData(LabDbContext labDbcontext, DateTime fromDate , DateTime toDate);
        Task<IMUResponseModel> PostDataToIMU(LabDbContext labDbContex,CoreDbContext coreDbContext, List<Int64> reqIdList, RbacUser user);
    }
}
