using DsfEMR.Security;
using DsfEMR.ViewModel.Pharmacy;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace DsfEMR.Services.Pharmacy.SupplierLedger
{
    public interface ISupplierLedgerService
    {
        Task<GetSupplierLedgerGRDetailsVM> GetSupplierLedgerGRDetails(int supplierId);
        Task<GetPHRMSupplierLedgerVM> GetAllAsync();
        int MakeSupplierLedgerPayment(IList<MakeSupplierLedgerPaymentVM> ledgerTxn, RbacUser currentUser);
    }
}
