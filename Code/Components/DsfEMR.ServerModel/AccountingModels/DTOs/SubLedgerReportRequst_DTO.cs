using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DsfEMR.ServerModel.AccountingModels.DTOs
{
    public class SubLedgerReportRequest_DTO
    {
        public List<int> SubLedgerIds;
        public DateTime FromDate;
        public DateTime ToDate;
        public int FiscalYearId;
    }
}
