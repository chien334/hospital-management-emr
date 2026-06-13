using DsfEMR.ServerModel.PharmacyModels;
using DsfEMR.ViewModel.Pharmacy;
using System;
using System.Collections.Generic;

namespace DsfEMR.Services.Pharmacy.Rack
{
    public interface IRackService
    {
        List<RackViewModel> ListRack();
        RackViewModel AddRack(PHRMRackModel model);
        RackViewModel UpdateRack(RackViewModel model);
        RackViewModel GetRack(int id);
        void DeleteRack(int id);
        List<RackViewModel> GetParentRack();
        List<RackViewModel> GetAllRack();
        List<PHRM_MAP_ItemToRack> GetAllRackItem();
        String GetDrugList(int rackId, int storeId);
        string GetStoreRackNameByItemId(int itemId);
    }
}
