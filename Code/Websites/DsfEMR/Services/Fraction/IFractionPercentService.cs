using DsfEMR.ServerModel;
using DsfEMR.ServerModel.FractionModels;
using DsfEMR.ServerModel.PharmacyModels;
using DsfEMR.ViewModel.Pharmacy;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace DsfEMR.Services
{
    public interface IFractionPercentService
    {
        List<FractionPercentVM> ListFractionApplicableItems();
        FractionPercentVM AddFractionPercent(FractionPercentModel model);
        FractionPercentVM UpdateFractionPercent(FractionPercentModel model);
        FractionPercentVM GetFractionPercent(int id);
        FractionPercentVM GetFractionPercentByBillPriceId(int id);

    }
}
