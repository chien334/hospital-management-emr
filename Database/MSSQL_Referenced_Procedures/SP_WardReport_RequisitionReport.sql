CREATE PROCEDURE [dbo].[SP_WardReport_RequisitionReport]  
	@FromDate datetime=null,
	@ToDate datetime=null,
	@StoreId int = null
AS
/*
FileName: [SP_WardReport_RequisitionReport] '1/7/2020','1/7/2020'
CreatedBy/date: Rusha/03-26-2019
Description: To get the Requsition and Dispatch Details of Stock such as WardName, ItemName, BatchNo, RequestedQty, MRP of Each Item Selected By User 
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1.		Rusha/03-26-2019					   get stock details of requisition and dispatch of item from different ward
2.		Sanjit/01-09-2020					   added requested by user and dispatched by user and receivedby user.
3.		Sanjit/03-20-2020					   substore integration
*/

BEGIN
  IF ((@FromDate IS NOT NULL) and (@ToDate IS NOT NULL))
		BEGIN
			select req.RequisitionId,disp.DispatchId,convert(date,req.CreatedOn) as RequestedDate,
			convert(date,dispitm.CreatedOn) as DispatchDate, itm.ItemName,sum(reqitm.Quantity) as RequestedQty,
			sum(dispitm.Quantity) as DispatchQty,dispitm.MRP, ROUND(sum(dispitm.Quantity)*dispitm.MRP, 2, 0) as TotalAmt,
			(select FullName from EMP_Employee as emp1 where emp1.EmployeeId = req.CreatedBy) as 'RequestedByUser',
			(select FullName from EMP_Employee as emp2 where emp2.EmployeeId = dispitm.CreatedBy) as 'DispatchedByUser',
			disp.ReceivedBy as 'ReceivedBy'
			from WARD_Requisition as req
			join WARD_RequisitionItems as reqitm on req.RequisitionId= reqitm.RequisitionId
			join PHRM_MST_Item as itm on reqitm.ItemId= itm.ItemId
			left join WARD_Dispatch as disp on req.RequisitionId = disp.RequisitionId and req.StoreId = disp.StoreId
			left join WARD_DispatchItems as dispitm on reqitm.RequisitionItemId=dispitm.RequisitionItemId and disp.DispatchId = dispitm.DispatchId
			where req.StoreId = @StoreId and CONVERT(date, req.CreatedOn) BETWEEN ISNULL(@FromDate,GETDATE())  AND ISNULL(@ToDate,GETDATE())+1
			group by convert(date,req.CreatedOn),convert(date,dispitm.CreatedOn),reqitm.Quantity,itm.ItemName, dispitm.MRP, 
			dispitm.Quantity,req.CreatedBy,dispitm.CreatedBy,req.RequisitionId,disp.DispatchId,disp.ReceivedBy,dispitm.DispatchItemId
		END		
End