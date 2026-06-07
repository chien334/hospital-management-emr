CREATE OR REPLACE FUNCTION sp_report_inventory_goodreceiptevaluation(
    p_goodreceiptno INT DEFAULT NULL,
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_transactiontype VARCHAR DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
BEGIN
    /*
     filename: sp_report_inventory_goodreceiptevaluation 
     created: 12dec'19 <Sanjit>
     Description: To Get All The Details of GoodRecipt of the inventory
     Remarks: 
     Change History
     S.No.    Date/User              Change          Remarks
     1.      12Dec'19/sanjit         created          
     2.		 17jun'20/sanjit		 changed goodsreceiptid to goodsreceiptno
    */
    BEGIN
      If(p_goodreceiptno IS NOT NULL)
      THEN
        OPEN ref1 FOR select gr.GoodsReceiptID,gr.GoodsReceiptNo,itm.ItemName,itm.Code,itm.ItemType,gritm.BatchNO,gritm.ItemRate,stktxn.TransactionType,stktxn.Quantity,stktxn.InOut,stktxn.CreatedOn AS "TransactionDate",stktxn.ReferenceNo,emp.FirstName AS "TransactionBy",
    	unit.UOMName
    	from INV_TXN_StockTransaction as stktxn
        
        join INV_TXN_Stock as stk on stktxn.StockId = stk.StockId
        join INV_TXN_GoodsReceiptItems as gritm on stk.GoodsReceiptItemId = gritm.GoodsReceiptItemId
        join INV_TXN_GoodsReceipt as gr on gritm.GoodsReceiptId = gr.GoodsReceiptID
        join INV_MST_Item as itm on stk.ItemId = itm.ItemId
        join EMP_Employee as emp on stktxn.CreatedBy = emp.EmployeeId
        left join INV_MST_UnitOfMeasurement unit on itm.UnitOfMeasurementId = unit.UOMId
        where gr.GoodsReceiptNo = p_goodreceiptno and stkTxn.TransactionType like COALESCE(p_transactiontype,'%') and (stktxn.CreatedOn)::date between COALESCE(p_fromdate,'2010-01-01') and COALESCE(p_todate,CURRENT_TIMESTAMP)
        order by stktxn.CreatedOn desc;
        RETURN NEXT ref1;
      
      ELSE
      
        OPEN ref2 FOR select gr.GoodsReceiptID,gr.GoodsReceiptNo,itm.ItemName,itm.Code,itm.ItemType,gritm.BatchNO,gritm.ItemRate,stktxn.TransactionType,stktxn.Quantity,stktxn.InOut,stktxn.CreatedOn AS "TransactionDate",stktxn.ReferenceNo,emp.FirstName AS "TransactionBy",
    	unit.UOMName
    	from INV_TXN_StockTransaction as stktxn    
    	join INV_TXN_Stock as stk on stktxn.StockId = stk.StockId
        join INV_TXN_GoodsReceiptItems as gritm on stk.GoodsReceiptItemId = gritm.GoodsReceiptItemId
        join INV_TXN_GoodsReceipt as gr on gritm.GoodsReceiptId = gr.GoodsReceiptID
        join INV_MST_Item as itm on stk.ItemId = itm.ItemId
        join EMP_Employee as emp on stktxn.CreatedBy = emp.EmployeeId
        left join INV_MST_UnitOfMeasurement unit on itm.UnitOfMeasurementId = unit.UOMId
        where stkTxn.TransactionType like COALESCE(p_transactiontype,'%') and (stktxn.CreatedOn)::date between COALESCE(p_fromdate,'2010-01-01') and coalesce(p_todate,current_timestamp)
        order by stktxn.createdon desc;
        return next ref2;
      end if;
    end;
END;
$$ LANGUAGE plpgsql;