-- START : VIKAS: 1-Oct-2020: Correction for storeName, price column. 
CREATE PROCEDURE [dbo].[SP_Report_INV_CurrentStockItemDetails_By_StoreId] 
@StoreIds NVARCHAR(400) = '', @ItemId INT=null  
AS
/*
Change History
S.No.    UpdatedBy/Date					Remarks
1		Nagesh/19 Sep 2020			 updated script for available quantity column
2		NageshBB/22 sep 2020		 exclued items which available quantity is 0 and added storename column
3. 		Vikas/1-Oct-2020 			 Added missed column storeName and Price.
*/
DECLARE @mainStoreId INT=null;
SET @mainStoreId = (select StoreId from PHRM_MST_Store where [Name]='Main Store')	

IF(@mainStoreId IN (SELECT DISTINCT(value) FROM STRING_SPLIT(@StoreIds, ',') WHERE RTRIM(value) <> ''))

BEGIN
	SELECT 
	X.GoodsReceiptNo,
	GoodsReceiptDate,
	x.Quantity,
	X.Price,
	X.AvailableQuantity,
	X.StoreName
	FROM (
			select 

			gr.GoodsReceiptDate, 
			gr.GoodsReceiptNo,
			stk.AvailableQuantity,
			gritm.ReceivedQuantity+gritm.FreeQuantity Quantity ,
			stk.Price,
			'Main Store' as StoreName
		from INV_TXN_Stock stk
			join INV_TXN_GoodsReceiptItems gritm on stk.GoodsReceiptItemId = gritm.GoodsReceiptItemId
			join INV_TXN_GoodsReceipt gr on gritm.GoodsReceiptId = gr.GoodsReceiptID			
		where stk.ItemId=@ItemId and stk.AvailableQuantity>0
		UNION 
		SELECT 
			gr.GoodsReceiptDate, 
			gr.GoodsReceiptNo,
			stk.AvailableQuantity,
			gritm.ReceivedQuantity+gritm.FreeQuantity,
			stk.Price,
			store.Name as StoreName			
		FROM WARD_INV_Stock stk
			join INV_TXN_GoodsReceiptItems gritm on stk.GoodsReceiptItemId = gritm.GoodsReceiptItemId
			join INV_TXN_GoodsReceipt gr on gritm.GoodsReceiptId = gr.GoodsReceiptID
			join PHRM_MST_Store store on store.StoreId =stk.StoreId
		WHERE  stk.AvailableQuantity>0 AND 
		  stk.ItemId=@ItemId AND stk.StoreId IN (SELECT DISTINCT(value) FROM STRING_SPLIT(@StoreIds, ',') WHERE RTRIM(value) <> '')

		) as X
		
GROUP BY GoodsReceiptDate,X.GoodsReceiptNo,X.Price,x.Quantity,x.AvailableQuantity,x.StoreName
	order by x.StoreName,convert(date,x.GoodsReceiptDate)
END

ELSE
	BEGIN
		SELECT 
			gr.GoodsReceiptDate, 
			gr.GoodsReceiptNo,
			stk.AvailableQuantity,
			(gritm.ReceivedQuantity)+ (gritm.FreeQuantity) as Quantity,
			stk.Price,
			store.Name as StoreName
		FROM WARD_INV_Stock stk
			join INV_TXN_GoodsReceiptItems gritm on stk.GoodsReceiptItemId = gritm.GoodsReceiptItemId
			join INV_TXN_GoodsReceipt gr on gritm.GoodsReceiptId = gr.GoodsReceiptID
			join PHRM_MST_Store store on store.StoreId =stk.StoreId
		WHERE  stk.AvailableQuantity>0 AND 
		stk.ItemId=@ItemId AND stk.StoreId IN (SELECT DISTINCT(value) FROM STRING_SPLIT(@StoreIds, ',') WHERE RTRIM(value) <> '')
		GROUP BY GoodsReceiptDate,gr.GoodsReceiptNo,stk.Price,gritm.ReceivedQuantity,gritm.FreeQuantity,stk.AvailableQuantity,store.Name
	    order by store.Name, convert(date,gr.GoodsReceiptDate)
	END