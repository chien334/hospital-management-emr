using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using DanpheEMR;
using DanpheEMR.Sync.IRDNepal;
using DanpheEMR.Sync;
using System.Diagnostics;
/*
 File: DanpheEMR.Jobs.Program.cs
 Created: 10May'18 Sudarshan
 Description: This is for batch processing of IRD-post billing.
              This should be updated later if let's say we need to verify in India or something.
 */

namespace DanpheEMR.Jobs
{
    class Program
    {
        static void Main(string[] args)
        {
            Console.WriteLine("Sync to IRD in progress...");

            try
            {
                Console.WriteLine("Step 1: Syncing Billing Sales to IRD...");
                PostToIRD.SyncSalesToRemoteServer();
                Console.WriteLine("Step 1 completed.");

                Console.WriteLine("Step 2: Syncing Billing Sales Return to IRD...");
                PostToIRD.SyncSalesReturnToRemoteServer();
                Console.WriteLine("Step 2 completed.");

                Console.WriteLine("Step 3: Syncing Pharmacy Sales Invoice to IRD...");
                PostToIRD.SynchPhrmInvoiceToRemoteServer();
                Console.WriteLine("Step 3 completed.");

                Console.WriteLine("Step 4: Syncing Pharmacy Invoice Return to IRD...");
                PostToIRD.SyncPhrmInvoiceReturnToRemoteServer();
                Console.WriteLine("Step 4 completed.");

                Console.WriteLine("Sync to IRD completed successfully.");
            }
            catch (Exception ex)
            {
                Console.WriteLine("An error occurred during sync: " + ex.Message);
                Console.WriteLine("Stack Trace: " + ex.StackTrace);
            }

            Console.WriteLine("Sync process finished.");
        }
    }
}
