CREATE OR REPLACE FUNCTION sp_report_dispatch_details(
    p_dispatchid INT DEFAULT 0,
    p_fiscalyearid INT DEFAULT 0,
    p_requisitionid INT DEFAULT 0
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
BEGIN
    /*
    change history
    s.no.    updatedby/date					remarks
    1		kushal/18 oct 2019				created script 
    2		sanjit/5 mar 2020				divided by zero bug fix using case statement
    3.      sud/3mar'20						Changed Department to Store (needs revision)
    4.		Sanjit/10Apr'20					added remarks in sp	
    5.		sanjit/17apr'20					Added few more properties to use it in Dispatch Receipt.
    6.		Sanjit/12Sep'21					stock refactoring changes
    7.		rohit/19jan'22					BarCodeNumber is added in SP to show the barcode in dispatched receipt
    8.		ROHIT/10Feb'22					issue no is not showing issue solved.
    9.		rohit/20may'22					SP Modified to get Item Level Remarks
    10.		ROHIT/17Jun'22					fetched dispatcheddate, receiveddate
    11.		rohit/19jul'22					FiscalYearId predicate is added
    12.		ROHIT/19Dec'22					get dispatcheddate instead of createdon
    13.		rohit/7may'23					Fetched Main Level Details
    14.		ROHIT/7Sept'23					fetched dispatchno (previously dispatchno is fetched as issueno)
    */
    begin
      if(p_dispatchid > 0)
    	then
    	open ref1 for select req."RequisitionNo"
    	,ts."Name" as "targetstorename"
    	,ss."Name" as "sourcestorename"
    	,dis."DispatchNo"
    	,req."IssueNo"
    	,req."RequisitionDate"
    	,reqemp."FullName" as "requestedbyname"
    	,disemp."FullName" as "dispatchedbyname"
    	,dis."CreatedOn" as "dispatcheddate"
    	,recemp."FullName" as "receivedby"
    	,dis."ReceivedOn" as "receiveddate"
    	,dis."Remarks"
    	,req."IsDirectDispatched"
    from "INV_TXN_Dispatch" dis
    inner join "INV_TXN_Requisition" req on dis."RequisitionId" = req."RequisitionId"
    inner join "PHRM_MST_Store" ts on dis."TargetStoreId" = ts."StoreId"
    inner join "PHRM_MST_Store" ss on dis."SourceStoreId" = ss."StoreId"
    inner join "EMP_Employee" reqemp on req."CreatedBy" = reqemp."EmployeeId"
    inner join "EMP_Employee" disemp on dis."CreatedBy" = disemp."EmployeeId"
    left join "EMP_Employee" recemp on dis."ReceivedBy" = recemp."EmployeeId"
    where dis."DispatchId" = p_dispatchid
    	and dis."RequisitionId" = p_requisitionid
    	and dis."FiscalYearId" = p_fiscalyearid;
        return next ref1;
    
        open ref2 for select
          ri."RequisitionItemId",
          d."ItemId",
    	  d."Specification",
          i."Code",
          i."ItemName",
          ri."Quantity",
          ri."PendingQuantity",
          ri."ReceivedQuantity",
          d."DispatchedQuantity",
          (select 
            "CostPrice"
          from "INV_TXN_StockTransaction"
          where "TransactionType" in ('dispatched-item-to','dispatched-item-from') and "ReferenceNo" = d."DispatchItemsId" limit 1) as costprice,
          d."DispatchedQuantity" * (select 
            "CostPrice"
          from "INV_TXN_StockTransaction"
          where "TransactionType" in ('dispatched-item-to','dispatched-item-from') and "ReferenceNo" = d."DispatchItemsId" limit 1 ) as amt,
          ri."RequisitionItemStatus",
          d."Remarks",
    	  d."ItemRemarks",
    	  string_agg(fas."BarCodeNumber",',')  as "barcodenumber",
    	  fy."FiscalYearName"
        from
          "INV_TXN_DispatchItems" d
          inner join "INV_MST_Item" i on i."ItemId" = d."ItemId"
    	  left join "INV_MAP_DispatchItems_FixedAssetStock" f on d."DispatchItemsId"=f."DispatchItemsId"
    	  left join "INV_TXN_FixedAssetStock" fas on f."FixedAssetStockId"=fas."FixedAssetStockId"
          inner join "INV_TXN_RequisitionItems" ri on d."RequisitionItemId"= ri."RequisitionItemId" 
          inner join "INV_TXN_Requisition" r on r."RequisitionId" = ri."RequisitionId"
    	  inner join "INV_CFG_FiscalYears" fy on d."FiscalYearId"=fy."FiscalYearId"
        where d."DispatchId" = p_dispatchid and d."FiscalYearId"=p_fiscalyearid and r."RequisitionId"=p_requisitionid
    	group by 
          ri."RequisitionItemId",
          d."ItemId",
    	  d."Specification",
          i."Code",
          i."ItemName",
          ri."Quantity",
          ri."PendingQuantity",
          ri."ReceivedQuantity",
          d."DispatchedQuantity",
    	  ri."RequisitionItemStatus",
          d."Remarks",
    	  d."DispatchItemsId",
    	  d."ItemRemarks",
    	  fy."FiscalYearName";
        return next ref2;
      end if;
    end;
END;
$$ LANGUAGE plpgsql;