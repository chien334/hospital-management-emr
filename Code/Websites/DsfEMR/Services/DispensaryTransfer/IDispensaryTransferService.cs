using DsfEMR.Controllers.Dispensary;
using DsfEMR.Security;
using DsfEMR.ServerModel;
using DsfEMR.ServerModel.PharmacyModels;
using DsfEMR.ViewModel.DispensaryTransfer;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace DsfEMR.Services.DispensaryTransfer
{
    public interface IDispensaryTransferService
    {
        IList<PHRMStoreModel> GetAllStoresForTransfer();
        Task<IList<GetAllDispensaryStocksVm>> GetAllDispensaryStocks(int DispensaryId);
        Task<int> TransferStock(List<StockTransferModel> value , RbacUser currentUser );
        Task<int> ReturnToStore(List<StockTransferModel> value, RbacUser currentUser);
        Task<int> DispensaryToDispensaryTransfer(List<StockTransferModel> value, RbacUser currentUser);
        Task<IList<GetAllTransactionByStoreIdDTO>> GetAllTransactionByStoreId(int storeId);
    }
}
