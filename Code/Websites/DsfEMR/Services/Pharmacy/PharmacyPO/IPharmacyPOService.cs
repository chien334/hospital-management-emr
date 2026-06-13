using DsfEMR.Security;
using DsfEMR.ServerModel;
using DsfEMR.ViewModel.Pharmacy;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace DsfEMR.Services.Pharmacy.PharmacyPO
{
    public interface IPharmacyPOService
    {
        Task<GetPharmacyPOEditVm> GetPurchaseOrderForEdit(int id);
        Task<GetItemsForPOViewModel> GetAllAsync();
        int UpdatePurchaseOrder(PHRMPurchaseOrderModel value, RbacUser currentUser);
    }
}
