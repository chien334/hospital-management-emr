-- SP_Report_BIL_DepartmentSummary 
CREATE PROCEDURE [dbo].[SP_Report_BIL_DepartmentSummary] -- SP_Report_BIL_DepartmentSummary '2020-12-07','2020-12-07'
  @FromDate DATETIME = NULL,
  @ToDate DATETIME = NULL
AS
/*
Change History
S.No.	UpdatedBy/Date			Remarks
1		Ramavtar/11Sept'18      Initial Draft
2		Ramavtar/30Nov'18		added summary and filtered report data for provisional and cancel
3       Sud/13Mar'19            Changed to function FN_BILL_Get_BillingTxnItemSeggregation_ByBillingType_NoProvisional 
                                  from: FN_BIL_GetTxnItemsInfoWithDateSeparation_DepartmentSummary
4.		Dinesh/ 28th May'19		Added Credit Received amount in summary as previously it was not cleared and taking from previous dates
5.      Dinesh /7thDec'2020     Handled Settled Discount Amount 
*/
BEGIN
	--table1: report data
	 SELECT
	    [dbo].[FN_BIL_GetSrvDeptReportingName_DepartmentSummary] (ServiceDepartmentName,ItemName) 'ServiceDepartment',
		--fnItems.ServiceDepartmentName 'ServiceDepartment',
		SUM(ISNULL(fnItems.Quantity, 0)) 'Quantity',
		SUM(ISNULL(fnItems.SubTotal, 0)) 'SubTotal',
		SUM(ISNULL(fnItems.DiscountAmount, 0)) 'DiscountAmount',
		SUM(ISNULL(fnItems.TotalAmount, 0)) 'TotalAmount',
		SUM(ISNULL(fnItems.ReturnTotalAmount, 0)) 'ReturnAmount',
	    SUM(ISNULL(TotalAmount, 0) - ISNULL(ReturnTotalAmount, 0)) AS 'NetSales',
	    SUM(ISNULL(CreditAmount, 0)) AS 'CreditAmount',
		SUM(ISNULL(CreditReceived, 0)) AS 'CreditReceivedAmount'

	FROM FN_BILL_Get_BillingTxnItemSeggregation_ByBillingType_NoProvisional(@FromDate, @ToDate)  fnItems

	GROUP BY  
	  [dbo].[FN_BIL_GetSrvDeptReportingName_DepartmentSummary] (ServiceDepartmentName,ItemName) 
	ORDER BY 1
	--SELECT
	--	fnItems.ServiceDepartmentName 'ServiceDepartment',
	--	SUM(ISNULL(fnItems.Quantity, 0)) 'Quantity',
	--	SUM(ISNULL(fnItems.SubTotal, 0)) 'SubTotal',
	--	SUM(ISNULL(fnItems.DiscountAmount, 0)) 'DiscountAmount',
	--	SUM(ISNULL(fnItems.TotalAmount, 0)) 'TotalAmount',
	--	SUM(ISNULL(fnItems.ReturnAmount, 0)) 'ReturnAmount',
	--	SUM(ISNULL(TotalAmount, 0) - ISNULL(ReturnAmount, 0)) 'NetSales'
	--FROM (SELECT
	--	*
	--FROM FN_BIL_GetTxnItemsInfoWithDateSeparation_DepartmentSummary(@FromDate, @ToDate)
	--WHERE BillStatus != 'cancelled' AND BillStatus != 'provisional') fnItems
	--GROUP BY fnItems.ServiceDepartmentName
	--ORDER BY 1
	--table2: provisional, cancel, credit amounts for summary
	SELECT 
		SUM(CASE WHEN BillStatus='provisional' THEN ProvisionalAmount ELSE 0 END) 'ProvisionalAmount',
		SUM(CASE WHEN BillStatus='cancelled' THEN CancelledAmount ELSE 0 END) 'CancelledAmount',
		SUM(CASE WHEN BillStatus='credit' THEN CreditAmount ELSE 0 END) 'CreditAmount',
		(SELECT SUM(ISNULL(CreditReceived, 0)) FROM FN_BILL_Get_BillingTxnItemSeggregation_ByBillingType_NoProvisional(@FromDate,@ToDate))  AS 'CreditReceivedAmount',
		(SELECT SUM(ISNULL(AdvanceReceived,0)) FROM FN_BIL_GetDepositNProvisionalBetnDateRange(@FromDate,@ToDate)) 'AdvanceReceived',
		(SELECT SUM(ISNULL(AdvanceSettled,0)) FROM FN_BIL_GetDepositNProvisionalBetnDateRange(@FromDate,@ToDate)) 'AdvanceSettled',
		(SELECT SUM(ISNULL(SettledDiscountAmount,0)) FROM [FN_BIL_GetSettledAmountBetnDateRange](@FromDate,@ToDate)) 'SettledDiscountAmount'
	FROM FN_BIL_GetTxnItemsInfoWithDateSeparation_DepartmentSummary(@FromDate, @ToDate)
END