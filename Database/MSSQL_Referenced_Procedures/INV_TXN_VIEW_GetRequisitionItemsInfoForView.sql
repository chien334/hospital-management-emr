CREATE Procedure [dbo].[INV_TXN_VIEW_GetRequisitionItemsInfoForView] 
  @RequisitionId INT
AS
/*
FileName: INV_TXN_VIEW_GetRequisitionItemsInfoForView -- EXEC INV_TXN_VIEW_GetRequisitionItemsInfoForView  8
Author: Sud/19Feb'20 
Description: to get details of Requisition items along with Employee Information.
Remarks: We're returning two tables, one for Requisition details and another for Dispatch Details.
ChangeHistory:
S.No    Author/Date                  Remarks
1.      Sud/19Feb'20                Initial Draft
2.      Sud/4Mar'20					added RequisitionItemId in select query. Needed for Cancellation.
3.		sanjit/9Apr'20				added IssueNo and RequisitionNo in SP
4.		sanjit/17Apr'20				added cancel details in the sp.
5.		sanjit/6May'20				added RequisitionRemarks in the sp.(immediate solution,must refactor properly)
6.		sanjit/12Jun'20				removed withdrawn items from the query.
7.		Rohit/4Jan'22				added ItemCategory in query to get ItemCategory from Requisition.
8.      Rohit/7Sept'23              fetched DispatchNo
*/
BEGIN


SELECT reqItm.ItemId
	,itm.ItemName
	,itm.Code
	,reqItm.Quantity
	,reqItm.ItemCategory
	,reqItm.Specification
	,reqItm.ReceivedQuantity
	,reqItm.PendingQuantity
	,reqItm.RequisitionItemStatus
	,reqItm.Remark
	,reqItm.ReceivedQuantity AS 'DispatchedQuantity'
	,reqItm.RequisitionNo
	,reqItm.IssueNo
	,reqItm.RequisitionId
	,reqItm.CreatedOn
	,reqItm.CreatedBy
	,reqEmp.FullName 'CreatedByName'
	,reqItm.RequisitionItemId
	,reqItm.isActive
	,reqItm.CancelOn
	,reqItm.CancelRemarks
	,(
		SELECT FullName
		FROM EMP_Employee
		WHERE EmployeeId = reqItm.CancelBy
		) 'CancelBy'
	,NULL AS 'ReceivedBy'
	,-- receive item feature is not yet implemented, correct this later : sud-19Feb'20,
	(
		SELECT Remarks
		FROM INV_TXN_Requisition
		WHERE RequisitionId = @RequisitionId
		) 'Remarks'
		,dis.DispatchNo
FROM INV_TXN_RequisitionItems reqItm
INNER JOIN INV_MST_Item itm ON reqItm.ItemId = itm.ItemId
INNER JOIN EMP_Employee reqEmp ON reqItm.CreatedBy = reqEmp.EmployeeId
OUTER APPLY (select top 1 DispatchNo from INV_TXN_Dispatch WHERE RequisitionId =reqItm.RequisitionId) dis
WHERE reqItm.RequisitionId = @RequisitionId
	AND reqItm.RequisitionItemStatus != 'withdrawn'

SELECT dispItm.RequisitionItemId
	,dispItm.DispatchedQuantity
	,dispItm.CreatedOn 'DispatchedOn'
	,dispItm.CreatedBy 'DispatchedBy'
	,emp.FullName 'DispatchedByName'
FROM INV_TXN_DispatchItems dispItm
INNER JOIN EMP_Employee emp ON dispItm.CreatedBy = emp.EmployeeId
WHERE RequisitionItemId IN (
		SELECT RequisitionItemId
		FROM INV_TXN_RequisitionItems
		WHERE RequisitionId = @RequisitionId
		)
ORDER BY dispItm.CreatedOn
END
--END: ROHIT: 7Sept'23: SP modofied to get DispatchNo from the requisition------------------


--START: ROHIT: 7Sept'23: SP modofied to get DispatchNo from the requisition (previously DispatchNo is fetched as IssueNo)------------------