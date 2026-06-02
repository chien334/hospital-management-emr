CREATE PROCEDURE [dbo].[SP_Report_Inventory_GoodReceiptEvaluation]
  @GoodReceiptNo int = null,
  @FromDate DateTime=null,
  @ToDate DateTime=null,
  @TransactionType varchar(70)=null
  AS
/*
 FileName: SP_Report_Inventory_GoodReceiptEvaluation 
 Created: 12Dec'19 <Sanjit>
 Description: To Get All The Details of GoodRecipt of the inventory
 Remarks: 
 Change History
 S.No.    Date/User              Change          Remarks
 1.      12Dec'19/sanjit         created          
 2.		 17Jun'20/sanjit		 changed goodsreceiptid to goodsreceiptno
*/
BEGIN
  If(@GoodReceiptNo IS NOT NULL)
  BEGIN
    select gr.GoodsReceiptID,gr.GoodsReceiptNo,itm.ItemName,itm.Code,itm.ItemType,gritm.BatchNO,gritm.ItemRate,stktxn.TransactionType,stktxn.Quantity,stktxn.InOut,stktxn.CreatedOn as 'TransactionDate',stktxn.ReferenceNo,emp.FirstName as 'TransactionBy',
	unit.UOMName
	from INV_TXN_StockTransaction as stktxn
    
    join INV_TXN_Stock as stk on stktxn.StockId = stk.StockId
    join INV_TXN_GoodsReceiptItems as gritm on stk.GoodsReceiptItemId = gritm.GoodsReceiptItemId
    join INV_TXN_GoodsReceipt as gr on gritm.GoodsReceiptId = gr.GoodsReceiptID
    join INV_MST_Item as itm on stk.ItemId = itm.ItemId
    join EMP_Employee as emp on stktxn.CreatedBy = emp.EmployeeId
    left join INV_MST_UnitOfMeasurement unit on itm.UnitOfMeasurementId = unit.UOMId
    where gr.GoodsReceiptNo = @GoodReceiptNo and stkTxn.TransactionType like ISNULL(@TransactionType,'%') and CONVERT(date,stktxn.CreatedOn) between ISNULL(@FromDate,'2010-01-01') and ISNULL(@ToDate,GETDATE())
    order by stktxn.CreatedOn desc
  END
  ELSE
  BEGIN
    select gr.GoodsReceiptID,gr.GoodsReceiptNo,itm.ItemName,itm.Code,itm.ItemType,gritm.BatchNO,gritm.ItemRate,stktxn.TransactionType,stktxn.Quantity,stktxn.InOut,stktxn.CreatedOn as 'TransactionDate',stktxn.ReferenceNo,emp.FirstName as 'TransactionBy',
	unit.UOMName
	from INV_TXN_StockTransaction as stktxn    
	join INV_TXN_Stock as stk on stktxn.StockId = stk.StockId
    join INV_TXN_GoodsReceiptItems as gritm on stk.GoodsReceiptItemId = gritm.GoodsReceiptItemId
    join INV_TXN_GoodsReceipt as gr on gritm.GoodsReceiptId = gr.GoodsReceiptID
    join INV_MST_Item as itm on stk.ItemId = itm.ItemId
    join EMP_Employee as emp on stktxn.CreatedBy = emp.EmployeeId
    left join INV_MST_UnitOfMeasurement unit on itm.UnitOfMeasurementId = unit.UOMId
    where stkTxn.TransactionType like ISNULL(@TransactionType,'%') and CONVERT(date,stktxn.CreatedOn) between ISNULL(@FromDate,'2010-01-01') and ISNULL(@ToDate,GETDATE())
    order by stktxn.CreatedOn desc
  END
END