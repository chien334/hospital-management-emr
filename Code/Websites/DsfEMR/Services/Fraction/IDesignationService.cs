using DsfEMR.ServerModel;
using DsfEMR.ServerModel.PharmacyModels;
using DsfEMR.ViewModel.Pharmacy;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace DsfEMR.Services
{
    public interface IDesignationService
    {
        List<DesignationModel> ListDesignation();
        DesignationModel AddDesignation(DesignationModel model);
        DesignationModel UpdateDesignation(DesignationModel model);
        DesignationModel GetDesignation(int id);
    }
}
