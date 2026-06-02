CREATE PROCEDURE [dbo].[SP_Report_Dispatch_Details]
  @DispatchId int = 0,
  @FiscalYearId int =0,
  @RequisitionId int =0
AS
/*
Change History
S.No.    UpdatedBy/Date					Remarks
1		Kushal/18 Oct 2019				Created Script 
2		Sanjit/5 Mar 2020				divided by zero bug fix using case statement
3.      Sud/3Mar'20						Changed Department to Store (needs revision)
4.		Sanjit/10Apr'20					Added Remarks in SP	
5.		Sanjit/17Apr'20					Added few more properties to use it in Dispatch Receipt.
6.		Sanjit/12Sep'21					Stock Refactoring Changes
7.		Rohit/19Jan'22					BarCodeNumber is added in SP to show the barcode in dispatched receipt
8.		ROHIT/10Feb'22					Issue No is not showing issue solved.
9.		ROHIT/20May'22					SP Modified to get Item Level Remarks
10.		ROHIT/17Jun'22					Fetched DispatchedDate, ReceivedDate
11.		ROHIT/19Jul'22					FiscalYearId predicate is added
12.		ROHIT/19Dec'22					Get DispatchedDate instead of CreatedOn
13.		ROHIT/7May'23					Fetched Main Level Details
14.		ROHIT/7Sept'23					Fetched DispatchNo (previously DispatchNo is fetched as IssueNo)
*/
BEGIN
  IF(@DispatchId > 0)
	BEGIN
	SELECT req.RequisitionNo
	,ts.Name 'TargetStoreName'
	,ss.Name 'SourceStoreName'
	,dis.DispatchNo
	,req.IssueNo
	,req.RequisitionDate
	,reqEmp.FullName 'RequestedByName'
	,disEmp.FullName 'DispatchedByName'
	,dis.CreatedOn 'DispatchedDate'
	,recEmp.FullName 'ReceivedBy'
	,dis.ReceivedOn 'ReceivedDate'
	,dis.Remarks
	,req.IsDirectDispatched
FROM INV_TXN_Dispatch dis
INNER JOIN INV_TXN_Requisition req ON dis.RequisitionId = req.RequisitionId
INNER JOIN PHRM_MST_Store ts ON dis.TargetStoreId = ts.StoreId
INNER JOIN PHRM_MST_Store ss ON dis.SourceStoreId = ss.StoreId
INNER JOIN EMP_Employee reqEmp on req.CreatedBy=reqEmp.EmployeeId
INNER JOIN EMP_Employee disEmp on dis.CreatedBy =disEmp.EmployeeId
LEFT JOIN EMP_EMployee recEmp on dis.ReceivedBy =recEmp.EmployeeId
WHERE dis.DispatchId = @DispatchId
	AND dis.RequisitionId = @RequisitionId
	AND dis.FiscalYearId = @FiscalYearId

    SELECT
      RI.RequisitionItemId,
      D.ItemId,
	  D.Specification,
      I.Code,
      I.ItemName,
      RI.Quantity,
      RI.PendingQuantity,
      RI.ReceivedQuantity,
      D.DispatchedQuantity,
      (SELECT TOP(1)
        CostPrice
      FROM INV_TXN_StockTransaction
      WHERE TransactionType IN ('dispatched-item-to','dispatched-item-from') AND ReferenceNo = D.DispatchItemsId) AS CostPrice,
      D.DispatchedQuantity * (SELECT TOP(1)
        CostPrice
      FROM INV_TXN_StockTransaction
      WHERE TransactionType IN ('dispatched-item-to','dispatched-item-from') AND ReferenceNo = D.DispatchItemsId ) AS Amt,
      RI.RequisitionItemStatus,
      D.Remarks,
	  D.ItemRemarks,
	  STRING_AGG(FAS.BarCodeNumber,',')  'BarCodeNumber',
	  fy.FiscalYearName
    FROM
      INV_TXN_DispatchItems D
      INNER JOIN INV_MST_Item I ON I.ItemId = D.ItemId
	  LEFT JOIN INV_MAP_DispatchItems_FixedAssetStock F ON D.DispatchItemsId=F.DispatchItemsId
	  LEFT JOIN INV_TXN_FixedAssetStock FAS ON F.FixedAssetStockId=FAS.FixedAssetStockId
      INNER JOIN INV_TXN_RequisitionItems RI ON D.RequisitionItemId= RI.RequisitionItemId 
      INNER JOIN INV_TXN_Requisition R ON R.RequisitionId = RI.RequisitionId
	  INNER JOIN INV_CFG_FiscalYears fy ON D.FiscalYearId=fy.FiscalYearId
    WHERE D.DispatchId = @DispatchId AND D.FiscalYearId=@FiscalYearId AND R.RequisitionId=@RequisitionId
	GROUP BY 
      RI.RequisitionItemId,
      D.ItemId,
	  D.Specification,
      I.Code,
      I.ItemName,
      RI.Quantity,
      RI.PendingQuantity,
      RI.ReceivedQuantity,
      D.DispatchedQuantity,
	  RI.RequisitionItemStatus,
      D.Remarks,
	  D.DispatchItemsId,
	  D.ItemRemarks,
	  fy.FiscalYearName
  END
END