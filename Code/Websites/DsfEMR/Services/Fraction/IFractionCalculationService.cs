using DsfEMR.ServerModel;
using DsfEMR.ViewModel;
using System;
using System.Collections.Generic;
using System.Data;

namespace DsfEMR.Services
{
    public interface IFractionCalculationService
    {
        List<FractionCalculationModel> ListFractionCalculation();
        int AddFractionCalculation(FractionCalculationModel[] model);
        FractionCalculationModel UpdateFractionCalculation(FractionCalculationModel model);
        List<FractionCalculationViewModel> GetFractionCalculation(int BillTxnItemId);
        DataTable GetFractionTxnList();
        DataTable GetFractionReportByItemList();
        DataTable GetFractionReportByDoctorList(DateTime FromDate, DateTime ToDate);
        
    }
}
