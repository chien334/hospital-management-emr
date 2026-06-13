using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using DsfEMR.AccTransfer;
using DsfEMR.CommonTypes;
using DsfEMR.Core.Caching;
using DsfEMR.DalLayer;
using DsfEMR.Security;
using DsfEMR.ServerModel;
using DsfEMR.Utilities;
using Newtonsoft.Json.Linq;

namespace DsfEMR.Controllers
{
    public class AccountingBL
    {
       

        #region Get Section list for accounting billing, pharmacy, inventory
        public static List<AccSectionModel> GetSections(AccountingDbContext accountingDBContext, int currHospitalId)
        {
            try
            {
                List<AccSectionModel> sectionList = new List<AccSectionModel>();
                var paraValue = accountingDBContext.CFGParameters.Where(a => a.ParameterGroupName == "Accounting" && a.ParameterName == "SectionList").FirstOrDefault().ParameterValue;
                if (paraValue != "")
                {
                    JObject jObject = JObject.Parse(paraValue);
                    var secList = jObject.SelectToken("SectionList").ToList();
                    sectionList = (secList != null) ? DsfJSONConvert.DeserializeObject<List<AccSectionModel>>(DsfJSONConvert.SerializeObject(secList)) : sectionList; ;
                }
                return sectionList;
            }
            catch (Exception ex) { throw ex; }
        }
        #endregion
       
        public static DsfHTTPResponse<object> CheckResponseObject(List<object> data,string type)
        {
            try
            {
                DsfHTTPResponse<object> resobj = new DsfHTTPResponse<object>();
                if (data != null && data.Count > 0)
                {
                        resobj.Status = "OK";
                        resobj.Results = data;                   
                }
                else
                {
                    resobj.Status = "Failed";
                    resobj.Results = null;
                    resobj.ErrorMessage = type + " data not found, Please click on refresh data button";
                }
                return resobj;
            }
            catch (Exception)
            {

                throw;
            }
        }

        public static string GetVoucherNumber(AccountingDbContext accountingDBContext, int? voucherId, int sectionId, int currHospitalId, int fYearId)
        {
            var incrementCounter = 1;
            sectionId = (sectionId > 0) ? sectionId : 4;          
            var voucherCode = (from v in accountingDBContext.Vouchers
                               where v.VoucherId == voucherId
                               select v.VoucherCode).FirstOrDefault();
            int? maxVNo = (from txn in accountingDBContext.Transactions
                           where txn.HospitalId == currHospitalId && txn.FiscalyearId == fYearId &&
                           txn.VoucherId == voucherId && txn.SectionId == sectionId
                           select (int?)txn.VoucherSerialNo).Max() ?? 0;
            var SectionCode = (from sec in accountingDBContext.Section
                               where sec.SectionId == sectionId && sec.HospitalId == currHospitalId
                               select sec.SectionCode).FirstOrDefault();

            var newVoucherNo = (maxVNo > 0) ? maxVNo + incrementCounter : 1;
            var voucherNumberFinal = (!string.IsNullOrEmpty(SectionCode)) ? SectionCode + '-' + voucherCode + '-' + newVoucherNo.ToString() : voucherCode + '-' + newVoucherNo.ToString();
            return voucherNumberFinal;
        }

        public static int GetTUID(AccountingDbContext accountingDBContext, int currHospitalId)
        {
            try
            {
                var incrementCounter = 1;
                var Tuid = (from txn in accountingDBContext.Transactions
                            where txn.HospitalId == currHospitalId
                            select (int?)txn.TUId).Max() ?? 0;
                if (Tuid != 0)
                {
                    Tuid = Tuid + incrementCounter;
                }
                else
                {
                    Tuid = 1;
                }
                return Tuid;
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }
    }
}
