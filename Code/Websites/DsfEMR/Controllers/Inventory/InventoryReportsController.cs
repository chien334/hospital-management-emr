using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using DsfEMR.DalLayer;
using Microsoft.Extensions.Options;
using DsfEMR.Core.Configuration;
using DsfEMR.ServerModel.ReportingModels;
using DsfEMR.CommonTypes;
using DsfEMR.Utilities;
using System.Data;
using DsfEMR.ServerModel.InventoryModels.InventoryReportModel;
using DsfEMR.Services.Inventory.DTO.InventoryReports;

// For more information on enabling MVC for empty projects, visit http://go.microsoft.com/fwlink/?LinkID=397860

namespace DsfEMR.Controllers.Reporting
{
    public class InventoryReportsController : Controller
    {
        readonly string connString = null;
        public InventoryReportsController(IOptions<MyConfiguration> _config)
        {
            connString = _config.Value.Connectionstring;
        }

        public IActionResult ReportsMain()
        {
            return View("~/Views/InventoryView/Reports/ReportsMain.cshtml");
        }




        #region Current Stock Level Report

        public string CurrentStockLevelReport(string ItemName)
        {
            DsfHTTPResponse<List<CurrentStockLevel>> responseData = new DsfHTTPResponse<List<CurrentStockLevel>>();
            try
            {
                InventoryReportingDbContext invreportingDbContext = new InventoryReportingDbContext(connString);
                List<CurrentStockLevel> currentstocklevel = invreportingDbContext.CurrentStockLevelReport(ItemName);

                responseData.Status = "OK";
                responseData.Results = currentstocklevel;
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message;
            }
            return DsfJSONConvert.SerializeObject(responseData);
        }

        public string CurrentStockLevelReportById(string StoreIds)
        {
            DsfHTTPResponse<DataTable> responseData = new DsfHTTPResponse<DataTable>();
            try
            {
                InventoryReportingDbContext invreportingDbContext = new InventoryReportingDbContext(connString);
                DataTable result = invreportingDbContext.CurrentStockLevelReportByItemId(StoreIds);
                responseData.Status = "OK";
                responseData.Results = result;
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message;
            }
            return DsfJSONConvert.SerializeObject(responseData);
        }
        public string CurrentStockItemDetailsByStoreId(string StoreIds, int ItemId)
        {
            DsfHTTPResponse<DataTable> responseData = new DsfHTTPResponse<DataTable>();
            try
            {
                InventoryReportingDbContext invreportingDbContext = new InventoryReportingDbContext(connString);
                DataTable result = invreportingDbContext.CurrentStockItemDetailsByStoreId(StoreIds, ItemId);
                responseData.Status = "OK";
                responseData.Results = result;
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message;
            }
            return DsfJSONConvert.SerializeObject(responseData);
        }

        public IActionResult StockLevel()
        {
            return View("~/Views/InventoryView/Reports/StockLevel.cshtml");
        }

        #endregion

        #region Write Off Report

        public string CurrentWriteOffReport(int ItemId)
        {
            DsfHTTPResponse<List<CurrentWriteOff>> responseData = new DsfHTTPResponse<List<CurrentWriteOff>>();
            try
            {
                InventoryReportingDbContext invreportingDbContext = new InventoryReportingDbContext(connString);
                List<CurrentWriteOff> currentwriteoff = invreportingDbContext.CurrentWriteOffReport(ItemId);

                responseData.Status = "OK";
                responseData.Results = currentwriteoff;
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message;
            }
            return DsfJSONConvert.SerializeObject(responseData);
        }

        #endregion

        #region Return To Vendor Report

        public string ReturnToVendorReport(int VendorId)
        {
            DsfHTTPResponse<List<ReturnToVendor>> responseData = new DsfHTTPResponse<List<ReturnToVendor>>();
            try
            {
                InventoryReportingDbContext invreportingDbContext = new InventoryReportingDbContext(connString);
                List<ReturnToVendor> currentwriteoff = invreportingDbContext.ReturnToVendorReport(VendorId);

                responseData.Status = "OK";
                responseData.Results = currentwriteoff;
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message;
            }
            return DsfJSONConvert.SerializeObject(responseData);
        }

        #endregion



        #region Daily Item Dispatch Report

        public string DailyItemDispatchReport(DateTime FromDate, DateTime ToDate, int StoreId)
        {
            DsfHTTPResponse<List<DailyItemDispatchModel>> responseData = new DsfHTTPResponse<List<DailyItemDispatchModel>>();
            try
            {
                InventoryReportingDbContext invreportingDbContext = new InventoryReportingDbContext(connString);
                List<DailyItemDispatchModel> currentItemdispatchlevel = invreportingDbContext.DailyItemDispatchReport(FromDate, ToDate, StoreId);

                responseData.Status = "OK";
                responseData.Results = currentItemdispatchlevel;
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message;
            }
            return DsfJSONConvert.SerializeObject(responseData);
        }

        public IActionResult DailyItemDispatch()
        {
            return View("~/Views/InventoryView/Reports/DailyItemDispatch.cshtml");
        }

        #endregion
        #region Inventory Purchase Items Report
        public string INVPurchaseItemsReport(DateTime FromDate, DateTime ToDate, int FiscalYearId, int? ItemId)
        {
            DsfHTTPResponse<DataTable> responseData = new DsfHTTPResponse<DataTable>();
            try
            {
                InventoryReportingDbContext invreportingDbContext = new InventoryReportingDbContext(connString);
                DataTable result = invreportingDbContext.INVPurchaseItemsReport(FromDate, ToDate, FiscalYearId, ItemId);
                responseData.Status = "OK";
                responseData.Results = result;
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message;
            }
            return DsfJSONConvert.SerializeObject(responseData);
        }
        #endregion

        #region Purchase Order Report

        public string PurchaseOrderReport(DateTime FromDate, DateTime ToDate, int? StoreId)
        {
            DsfHTTPResponse<List<PurchaseOrderModel>> responseData = new DsfHTTPResponse<List<PurchaseOrderModel>>();
            try
            {
                InventoryReportingDbContext invreportingDbContext = new InventoryReportingDbContext(connString);
                List<PurchaseOrderModel> currentPurchaseOrderlevel = invreportingDbContext.PurchaseOrderReport(FromDate, ToDate, StoreId);

                responseData.Status = "OK";
                responseData.Results = currentPurchaseOrderlevel;
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message;
            }
            return DsfJSONConvert.SerializeObject(responseData);
        }

        public IActionResult PurchaseOrderSummery()
        {
            return View("~/Views/InventoryView/Reports/PurchaseOrderSummery.cshtml");
        }

        #endregion
        #region Cancelled PO and GR Reports
        public string CancelledPOandGRReport(DateTime FromDate, DateTime ToDate, string isGR)
        {
            DsfHTTPResponse<List<GoodsReceiptModel>> responseData = new DsfHTTPResponse<List<GoodsReceiptModel>>();
            try
            {
                bool GR = bool.Parse(isGR);
                InventoryReportingDbContext invreportingDbContext = new InventoryReportingDbContext(connString);
                List<GoodsReceiptModel> dsbStats = invreportingDbContext.CancelledPOandGRReports(FromDate, ToDate, GR);

                responseData.Status = "OK";
                responseData.Results = dsbStats;
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message;
            }
            return DsfJSONConvert.SerializeObject(responseData);
        }
        #endregion

        #region Goods Receipt Evaluation Report
        public string GoodReceiptEvaluationReport(DateTime? FromDate, DateTime? ToDate, string TransactionType, int? GoodReceiptNo)
        {
            DsfHTTPResponse<List<GoodsReceiptEvaluationModel>> responseData = new DsfHTTPResponse<List<GoodsReceiptEvaluationModel>>();
            try
            {

                InventoryReportingDbContext invreportingDbContext = new InventoryReportingDbContext(connString);
                List<GoodsReceiptEvaluationModel> dsbStats = invreportingDbContext.GoodReceiptEvaluationReport(FromDate, ToDate, TransactionType, GoodReceiptNo);

                responseData.Status = "OK";
                responseData.Results = dsbStats;
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message;
            }
            return DsfJSONConvert.SerializeObject(responseData);
        }
        #endregion

        #region Inventory Summary Report

        public string InventorySummaryReport(DateTime FromDate, DateTime ToDate, int FiscalYearId, int? StoreId)
        {
            DsfHTTPResponse<List<INV_RPT_InventorySummaryReport_DTO>> responseData = new DsfHTTPResponse<List<INV_RPT_InventorySummaryReport_DTO>>();
            try
            {
                InventoryReportingDbContext invreportingDbContext = new InventoryReportingDbContext(connString);
                DataTable result = invreportingDbContext.InventorySummaryReport(FromDate, ToDate, FiscalYearId, StoreId);
                List<INV_RPT_InventorySummaryReport_DTO> summaryList = INV_RPT_InventorySummaryReport_DTO.MapDataTableToListObject(result);
                responseData.Status = "OK";
                responseData.Results = summaryList;
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message;
            }
            return DsfJSONConvert.SerializeObject(responseData);
        }

        public IActionResult InventorySummary()
        {
            return View("~/Views/InventoryView/Reports/InventorySummary.cshtml");
        }

        #endregion

        #region Inventory Valuation

        public string InventoryValuationReport()
        {
            DsfHTTPResponse<DataTable> responseData = new DsfHTTPResponse<DataTable>();
            try
            {
                InventoryReportingDbContext invreportingDbContext = new InventoryReportingDbContext(connString);
                DataTable dsbStats = invreportingDbContext.InventoryValuation();

                responseData.Status = "OK";
                responseData.Results = dsbStats;
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message;
            }
            return DsfJSONConvert.SerializeObject(responseData);
        }

        public IActionResult InventoryValuation()
        {
            return View("~/Views/InventoryView/Reports/InventoryValuation.cshtml");
        }
        #endregion

        #region ComparisonPOGR
        public string ComparisonPoGrReport()
        {
            DsfHTTPResponse<DataTable> responseData = new DsfHTTPResponse<DataTable>();
            try
            {
                InventoryReportingDbContext invreportingDbContext = new InventoryReportingDbContext(connString);
                DataTable dsbStats = invreportingDbContext.ComparisonPOGR();

                responseData.Status = "OK";
                responseData.Results = dsbStats;
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message;
            }
            return DsfJSONConvert.SerializeObject(responseData);
        }

        public IActionResult ComparisonPOGR()
        {
            return View("~/Views/InventoryView/Reports/ComparisonPOGR.cshtml");
        }
        #endregion

        #region PurchaseReport
        public string PurchaseReport()
        {
            DsfHTTPResponse<DataTable> responseData = new DsfHTTPResponse<DataTable>();
            try
            {
                InventoryReportingDbContext invreportingDbContext = new InventoryReportingDbContext(connString);
                DataTable dsbStats = invreportingDbContext.PurchaseReports();

                responseData.Status = "OK";
                responseData.Results = dsbStats;
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message;
            }
            return DsfJSONConvert.SerializeObject(responseData);
        }

        public IActionResult IPurchaseReport()
        {
            return View("~/Views/InventoryView/Reports/PurchaseReport.cshtml");
        }
        #endregion

        #region Fixed Assets Report

        public string FixedAssetsReport(DateTime FromDate, DateTime ToDate)
        {
            DsfHTTPResponse<List<FixedAssetsModel>> responseData = new DsfHTTPResponse<List<FixedAssetsModel>>();
            try
            {
                InventoryReportingDbContext invreportingDbContext = new InventoryReportingDbContext(connString);
                List<FixedAssetsModel> currentFixedAssets = invreportingDbContext.FixedAssetsReport(FromDate, ToDate);

                responseData.Status = "OK";
                responseData.Results = currentFixedAssets;
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message;
            }
            return DsfJSONConvert.SerializeObject(responseData);
        }


        #endregion

        #region Fixed Assets Movement Report

        public string FixedAssetsMovementReport(DateTime FromDate, DateTime ToDate, int? EmployeeId, int? DepartmentId, int? ItemId, string ReferenceNumber)
        {
            DsfHTTPResponse<List<FixedAssetsMovementModel>> responseData = new DsfHTTPResponse<List<FixedAssetsMovementModel>>();
            try
            {
                InventoryReportingDbContext invreportingDbContext = new InventoryReportingDbContext(connString);
                List<FixedAssetsMovementModel> currentFixedAssets = invreportingDbContext.FixedAssetsMovementReport(FromDate, ToDate, EmployeeId, DepartmentId, ItemId, ReferenceNumber);

                responseData.Status = "OK";
                responseData.Results = currentFixedAssets;
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message;
            }
            return DsfJSONConvert.SerializeObject(responseData);
        }


        #endregion

        #region Detail Stock Ledger Model Report

        public string DepartmentDetailStockLedgerReport(DateTime FromDate, DateTime ToDate, int? ItemId, int selectedStoreId)
        {
            DsfHTTPResponse<List<DetailStockLedgerModel>> responseData = new DsfHTTPResponse<List<DetailStockLedgerModel>>();
            try
            {
                InventoryReportingDbContext invreportingDbContext = new InventoryReportingDbContext(connString);
                List<DetailStockLedgerModel> currentDetailStockLedger = invreportingDbContext.DepartmentDetailStockLedgerReport(FromDate, ToDate, ItemId, selectedStoreId);

                responseData.Status = "OK";
                responseData.Results = currentDetailStockLedger;
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message;
            }
            return DsfJSONConvert.SerializeObject(responseData);
        }
        #endregion

        #region Consumable Stock Ledger  Report
        public string ConsumableStockLedgerReport(DateTime FromDate, DateTime ToDate, int ItemId, int selectedStoreId, int fiscalYearId)
        {
            DsfHTTPResponse<ConsumableStockLedgerDetailFinalViewModel> responseData = new DsfHTTPResponse<ConsumableStockLedgerDetailFinalViewModel>();
            try
            {
                InventoryReportingDbContext invreportingDbContext = new InventoryReportingDbContext(connString);
                ConsumableStockLedgerDetailFinalViewModel currentDetailStockLedger = invreportingDbContext.ConsumableStockLedgerReport(FromDate, ToDate, ItemId, selectedStoreId, fiscalYearId, invreportingDbContext);
                responseData.Status = "OK";
                responseData.Results = currentDetailStockLedger;
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message;
            }
            return DsfJSONConvert.SerializeObject(responseData);
        }
        #endregion

        #region Capital Stock Ledger  Report
        public string CapitalStockLedgerReport(DateTime FromDate, DateTime ToDate, int ItemId, int selectedStoreId, int fiscalYearId)
        {
            DsfHTTPResponse<CapitalStockLedgerDetailFinalViewModel> responseData = new DsfHTTPResponse<CapitalStockLedgerDetailFinalViewModel>();
            try
            {
                InventoryReportingDbContext invreportingDbContext = new InventoryReportingDbContext(connString);
                CapitalStockLedgerDetailFinalViewModel currentDetailStockLedger = invreportingDbContext.CapitalStockLedgerReport(FromDate, ToDate, ItemId, selectedStoreId, fiscalYearId, invreportingDbContext);
                responseData.Status = "OK";
                responseData.Results = currentDetailStockLedger;
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message;
            }
            return DsfJSONConvert.SerializeObject(responseData);
        }
        #endregion
        #region Issued Item List  Report
        public string IssuedItemListReport(DateTime FromDate, DateTime ToDate, int? ItemId, int? SubStoreId, int? MainStoreId, int? EmployeeId, int fiscalYearId, int? SubCategoryId)
        {
            DsfHTTPResponse<List<IssuedItemViewModel>> responseData = new DsfHTTPResponse<List<IssuedItemViewModel>>();
            try
            {
                InventoryReportingDbContext invreportingDbContext = new InventoryReportingDbContext(connString);
                List<IssuedItemViewModel> ReportData = invreportingDbContext.IssuedItemListReport(FromDate, ToDate, fiscalYearId, ItemId, SubStoreId, MainStoreId, EmployeeId, SubCategoryId);
                responseData.Status = "OK";
                responseData.Results = ReportData;
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message;
            }
            return DsfJSONConvert.SerializeObject(responseData);
        }
        #endregion

        #region Opening Stock Valuation Report
        public string OpeningStockValuationReport(DateTime TillDate)
        {
            DsfHTTPResponse<DataTable> responseData = new DsfHTTPResponse<DataTable>();
            try
            {
                InventoryReportingDbContext invreportingDbContext = new InventoryReportingDbContext(connString);
                DataTable openigStockValuationReportData = invreportingDbContext.OpeningStockValuationReport(TillDate);
                responseData.Status = "OK";
                responseData.Results = openigStockValuationReportData;
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message;
            }
            return DsfJSONConvert.SerializeObject(responseData);
        }
        #endregion

        public string ApprovedMaterialStockRegisterReport(DateTime FromDate, DateTime ToDate)
        {
            DsfHTTPResponse<List<ApprovedMaterialStockRegisterModel>> responseData = new DsfHTTPResponse<List<ApprovedMaterialStockRegisterModel>>();
            try
            {

                InventoryReportingDbContext invreportingDbContext = new InventoryReportingDbContext(connString);
                List<ApprovedMaterialStockRegisterModel> currentFixedAssets = invreportingDbContext.ApprovedMaterialStockRegisterReport(FromDate, ToDate);

                responseData.Status = "OK";
                responseData.Results = currentFixedAssets;
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message;
            }
            return DsfJSONConvert.SerializeObject(responseData);
        }

        #region Vendor Transaction Report
        public string VendorTransactionReport(int fiscalYearId, int VendorId)
        {
            //DsfHTTPResponse<List<GoodsReceiptEvaluationModel>> responseData = new DsfHTTPResponse<List<GoodsReceiptEvaluationModel>>();
            DsfHTTPResponse<DataTable> responseData = new DsfHTTPResponse<DataTable>();
            try
            {
                InventoryReportingDbContext invreportingDbContext = new InventoryReportingDbContext(connString);
                DataTable result = invreportingDbContext.VendorTransactionReport(fiscalYearId, VendorId);
                responseData.Status = "OK";
                responseData.Results = result;
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message;
            }
            return DsfJSONConvert.SerializeObject(responseData);
        }
        #endregion

        #region VendorTransactionReportData
        public string VendorTransactionReportData(int fiscalYearId, int VendorId)
        {
            //DsfHTTPResponse<List<GoodsReceiptEvaluationModel>> responseData = new DsfHTTPResponse<List<GoodsReceiptEvaluationModel>>();
            DsfHTTPResponse<DataTable> responseData = new DsfHTTPResponse<DataTable>();
            try
            {
                InventoryReportingDbContext invreportingDbContext = new InventoryReportingDbContext(connString);
                InventoryDbContext inventoryDbContext = new InventoryDbContext(connString);

                DataTable result = invreportingDbContext.VendorTransactionReportData(fiscalYearId, VendorId);

                responseData.Status = "OK";
                responseData.Results = result;
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message;
            }
            return DsfJSONConvert.SerializeObject(responseData);
        }
        #endregion

        #region ItemMgmtDetail
        public string ItemMgmtDetailReport()
        {
            DsfHTTPResponse<DataTable> responseData = new DsfHTTPResponse<DataTable>();
            try
            {
                InventoryReportingDbContext invreportingDbContext = new InventoryReportingDbContext(connString);
                DataTable dsbStats = invreportingDbContext.ItemMgmtDetail();

                responseData.Status = "OK";
                responseData.Results = dsbStats;
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message;
            }
            return DsfJSONConvert.SerializeObject(responseData);
        }
        #endregion
        #region Substore Report
        public string SubstoreStockReport(int StoreId, int ItemId)
        {
            DsfHTTPResponse<SubstoreReportViewModel> responseData = new DsfHTTPResponse<SubstoreReportViewModel>();
            try
            {
                InventoryReportingDbContext invreportingDbContext = new InventoryReportingDbContext(connString);
                SubstoreReportViewModel substoreStock = invreportingDbContext.SubstoreStockReport(StoreId, ItemId);

                responseData.Status = "OK";
                responseData.Results = substoreStock;
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message;
            }
            return DsfJSONConvert.SerializeObject(responseData);
        }
        #endregion

        #region Inventory Purchase summary report
        public string InvPurchaseSummaryReport(DateTime FromDate, DateTime ToDate, int VendorId)
        {
            //DsfHTTPResponse<DataTable> responseData = new DsfHTTPResponse<DataTable>();
            DsfHTTPResponse<object> responseData = new DsfHTTPResponse<object>();
            try
            {
                InventoryReportingDbContext invreportingDbContext = new InventoryReportingDbContext(connString);
                InventoryDbContext inventoryDbContext = new InventoryDbContext(connString);
                DataTable result = invreportingDbContext.InvPurchaseSummaryReport(FromDate, ToDate, VendorId);
                var itmCategoryList = (from itmcat in inventoryDbContext.ItemCategoryMaster
                                       where itmcat.IsActive == true
                                       select itmcat.ItemCategoryName).ToList();
                responseData.Status = "OK";
                responseData.Results = new
                {
                    PurchaeSummaryList = result,
                    GRCategoryList = itmCategoryList
                };
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message;
            }
            return DsfJSONConvert.SerializeObject(responseData);
        }
        #endregion
        #region Grid Data Function ExpiryItemReport
        public string ExpiryItemReport(int? ItemId, int? StoreId, DateTime FromDate, DateTime ToDate)
        {
            DsfHTTPResponse<DataTable> responseData = new DsfHTTPResponse<DataTable>();

            try
            {
                InventoryReportingDbContext invreportingDbContext = new InventoryReportingDbContext(connString);
                DataTable expiryItemResult = invreportingDbContext.ExpiryItemReport(ItemId, StoreId, FromDate, ToDate);
                responseData.Status = "OK";
                responseData.Results = expiryItemResult;
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message;
            }
            return DsfJSONConvert.SerializeObject(responseData);
        }
        #endregion

        #region SupplierWiseStock
        public string GetAllVendorList()
        {
            DsfHTTPResponse<object> responseData = new DsfHTTPResponse<object>();
            try
            {
                InventoryDbContext invreportingDbContext = new InventoryDbContext(connString);
                var result = (from ven in invreportingDbContext.Vendors
                              select new
                              {
                                  VendorId = ven.VendorId,
                                  VendorName = ven.VendorName
                              }).ToList();
                responseData.Status = "OK";
                responseData.Results = result;
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message;
            }
            return DsfJSONConvert.SerializeObject(responseData);
        }

        public string GetAllItemsList()
        {
            DsfHTTPResponse<object> responseData = new DsfHTTPResponse<object>();
            try
            {
                InventoryDbContext invreportingDbContext = new InventoryDbContext(connString);
                var result = (from itm in invreportingDbContext.Items
                              select new
                              {
                                  ItemId = itm.ItemId,
                                  ItemName = itm.ItemName
                              }).ToList();
                responseData.Status = "OK";
                responseData.Results = result;
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message;
            }
            return DsfJSONConvert.SerializeObject(responseData);
        }

        public string GetAllStoreList()
        {
            DsfHTTPResponse<object> responseData = new DsfHTTPResponse<object>();
            try
            {
                InventoryDbContext invreportingDbContext = new InventoryDbContext(connString);
                var result = (from s in invreportingDbContext.StoreMasters
                              select new
                              {
                                  StoreId = s.StoreId,
                                  StoreName = s.Name
                              }).ToList();
                responseData.Status = "OK";
                responseData.Results = result;
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message;
            }
            return DsfJSONConvert.SerializeObject(responseData);
        }

        public string SupplierWiseStockReport(DateTime FromDate, DateTime ToDate, int? VendorId, int? StoreId, int? ItemId)
        {
            DsfHTTPResponse<List<SupplierWiseStockModel>> responseData = new DsfHTTPResponse<List<SupplierWiseStockModel>>();
            try
            {
                InventoryReportingDbContext invreportingDbContext = new InventoryReportingDbContext(connString);
                List<SupplierWiseStockModel> result = invreportingDbContext.SupplierWiseStockReport(FromDate, ToDate, VendorId, StoreId, ItemId);
                responseData.Status = "OK";
                responseData.Results = result;
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message;
            }
            return DsfJSONConvert.SerializeObject(responseData);
        }

        #endregion

        #region Inventory Purchase return to supplier report
        public string InvReturnToSupplierReport(DateTime FromDate, DateTime ToDate, int? VendorId, int? ItemId, string batchNumber, int? goodReceiptNumber, int? creditNoteNumber)
        {
            DsfHTTPResponse<List<ReturnToVendorItems>> responseData = new DsfHTTPResponse<List<ReturnToVendorItems>>();
            try
            {
                InventoryReportingDbContext invreportingDbContext = new InventoryReportingDbContext(connString);
                List<ReturnToVendorItems> ReturnToSupplier = invreportingDbContext.ReturnToSupplierReport(FromDate, ToDate, VendorId, ItemId, batchNumber, goodReceiptNumber, creditNoteNumber);

                responseData.Status = "OK";
                responseData.Results = ReturnToSupplier;
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message;
            }
            return DsfJSONConvert.SerializeObject(responseData);
        }
        #endregion
        public string INVSupplierInformationReport()
        {
            DsfHTTPResponse<DataTable> responseData = new DsfHTTPResponse<DataTable>();
            try
            {
                InventoryReportingDbContext invreportingDbContext = new InventoryReportingDbContext(connString);
                DataTable supplierInfoResult = invreportingDbContext.INVSupplierInformationReport();
                responseData.Status = "OK";
                responseData.Results = supplierInfoResult;

            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message;
            }
            return DsfJSONConvert.SerializeObject(responseData);
        }
        #region Substore Dispatch And Consumption Report
        public string SubstoreDispatchAndConsumptionReport(int? StoreId, int? ItemId, int? SubCategoryId, DateTime FromDate, DateTime ToDate)
        {
            DsfHTTPResponse<DataTable> responseData = new DsfHTTPResponse<DataTable>();

            try
            {
                InventoryReportingDbContext invreportingDbContext = new InventoryReportingDbContext(connString);
                DataTable dispatchAndConsumptionReportData = invreportingDbContext.SubstoreDispatchAndConsumptionReport(StoreId, ItemId, SubCategoryId, FromDate, ToDate);
                responseData.Status = "OK";
                responseData.Results = dispatchAndConsumptionReportData;
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message;
            }
            return DsfJSONConvert.SerializeObject(responseData);
        }
        #endregion

        #region Expirable Stock  Report
        public string ExpirableStockReport(DateTime FromDate, DateTime ToDate, int fiscalYearId, int ItemId)
        {
            DsfHTTPResponse<ExpirableStockReportFinalViewModel> responseData = new DsfHTTPResponse<ExpirableStockReportFinalViewModel>();
            try
            {
                InventoryReportingDbContext invreportingDbContext = new InventoryReportingDbContext(connString);
                ExpirableStockReportFinalViewModel expirableStockData = invreportingDbContext.ExpirableStockReport(FromDate, ToDate, ItemId, fiscalYearId, invreportingDbContext);
                responseData.Status = "OK";
                responseData.Results = expirableStockData;
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message;
            }
            return DsfJSONConvert.SerializeObject(responseData);
        }
        #endregion
        #region Substore Wise Summary Report
        public string SubstoreWiseSummaryReport(int? StoreId, DateTime FromDate, DateTime ToDate, int FiscalYearId)
        {
            DsfHTTPResponse<DataTable> responseData = new DsfHTTPResponse<DataTable>();

            try
            {
                InventoryReportingDbContext invreportingDbContext = new InventoryReportingDbContext(connString);
                DataTable SubstoreWiseSummaryReportData = invreportingDbContext.SubstoreWiseSummaryReport(StoreId, FromDate, ToDate, FiscalYearId);
                responseData.Status = "OK";
                responseData.Results = SubstoreWiseSummaryReportData;
            }
            catch (Exception ex)
            {
                responseData.Status = "Failed";
                responseData.ErrorMessage = ex.Message;
            }
            return DsfJSONConvert.SerializeObject(responseData);
        }
        #endregion
    }
}