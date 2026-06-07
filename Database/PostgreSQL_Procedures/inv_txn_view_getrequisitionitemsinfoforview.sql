CREATE OR REPLACE FUNCTION inv_txn_view_getrequisitionitemsinfoforview(
    p_requisitionid INT
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
BEGIN
    /*
    filename: inv_txn_view_getrequisitionitemsinfoforview -- exec inv_txn_view_getrequisitionitemsinfoforview  8
    author: sud/19feb'20 
    Description: to get details of Requisition items along with Employee Information.
    Remarks: We're returning two tables, one for requisition details and another for dispatch details.
    changehistory:
    s.no    author/date                  remarks
    1.      sud/19feb'20                Initial Draft
    2.      Sud/4Mar'20					added requisitionitemid in select query. needed for cancellation.
    3.		sanjit/9apr'20				added IssueNo and RequisitionNo in SP
    4.		sanjit/17Apr'20				added cancel details in the sp.
    5.		sanjit/6may'20				added RequisitionRemarks in the sp.(immediate solution,must refactor properly)
    6.		sanjit/12Jun'20				removed withdrawn items from the query.
    7.		rohit/4jan'22				added ItemCategory in query to get ItemCategory from Requisition.
    8.      Rohit/7Sept'23              fetched dispatchno
    */
    
    
    
    open ref1 for select reqitm."ItemId"
    	,itm."ItemName"
    	,itm."Code"
    	,reqitm."Quantity"
    	,reqitm."ItemCategory"
    	,reqitm."Specification"
    	,reqitm."ReceivedQuantity"
    	,reqitm."PendingQuantity"
    	,reqitm."RequisitionItemStatus"
    	,reqitm."Remark"
    	,reqitm."ReceivedQuantity" as "dispatchedquantity"
    	,reqitm."RequisitionNo"
    	,reqitm."IssueNo"
    	,reqitm."RequisitionId"
    	,reqitm."CreatedOn"
    	,reqitm."CreatedBy"
    	,reqemp."FullName" as "createdbyname"
    	,reqitm."RequisitionItemId"
    	,reqitm."isActive"
    	,reqitm."CancelOn"
    	,reqitm."CancelRemarks"
    	,(
    		select "FullName"
    		from "EMP_Employee"
    		where "EmployeeId" = reqitm."CancelBy"
    		) as "cancelby"
    	,null::text as "receivedby"
    	,-- receive item feature is not yet implemented, correct this later : sud-19feb'20,
    	(
    		SELECT "Remarks"
    		FROM "INV_TXN_Requisition"
    		WHERE "RequisitionId" = p_requisitionid
    		) AS "Remarks"
    		,dis."DispatchNo"
    FROM "INV_TXN_RequisitionItems" reqItm
    INNER JOIN "INV_MST_Item" itm ON reqItm."ItemId" = itm."ItemId"
    INNER JOIN "EMP_Employee" reqEmp ON reqItm."CreatedBy" = reqEmp."EmployeeId"
    LEFT JOIN LATERAL (select "DispatchNo" from "INV_TXN_Dispatch" WHERE "RequisitionId" = reqItm."RequisitionId" LIMIT 1) dis ON TRUE
    WHERE reqItm."RequisitionId" = p_requisitionid
    	AND reqItm."RequisitionItemStatus" != 'withdrawn';
        RETURN NEXT ref1;
    
    OPEN ref2 FOR SELECT dispItm."RequisitionItemId"
    	,dispItm."DispatchedQuantity"
    	,dispItm."CreatedOn" AS "DispatchedOn"
    	,dispItm."CreatedBy" AS "DispatchedBy"
    	,emp."FullName" AS "DispatchedByName"
    FROM "INV_TXN_DispatchItems" dispItm
    INNER JOIN "EMP_Employee" emp ON dispItm."CreatedBy" = emp."EmployeeId"
    WHERE "RequisitionItemId" IN (
    		SELECT "RequisitionItemId"
    		FROM "INV_TXN_RequisitionItems"
    		WHERE "RequisitionId" = p_requisitionid
    		)
    ORDER BY dispItm."CreatedOn";
        RETURN NEXT ref2;
    
    --END: ROHIT: 7Sept'23: sp modofied to get dispatchno from the requisition------------------
    
    
    --start: rohit: 7sept'23: sp modofied to get dispatchno from the requisition (previously dispatchno is fetched as issueno)------------------
END;
$$ LANGUAGE plpgsql;