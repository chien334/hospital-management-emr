using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DsfEMR.ServerModel.SchedulingModels
{
    public class WorkingHoursTxnVM
    {
        public List<EmployeeShiftMap> Maps { get; set; }
        public List<ShiftsMasterModel> Shifts { get; set; }
    }
}
