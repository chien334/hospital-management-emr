using DsfEMR.Security;
using DsfEMR.ServerModel;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace DsfEMR.Services.QueueManagement
{
    public interface IQueueManagementService
    {
        dynamic GetDepartment();
        dynamic GetAppointmentData(int deptId, int doctorId, bool pendingOnly);
        dynamic updateQueueStatus(string data, int visitId, RbacUser currentUser);
        dynamic GetAllAppointmentApplicableDoctor();
    }
}
