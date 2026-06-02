CREATE PROCEDURE [dbo].[SP_ACC_GetInventoryTransactions]			
@TransactionDate DATE, @HospitalId INT
AS
-- exec [dbo].[SP_ACC_GetInventoryTransactions]	'2022-08-17',1
/************************************************************************
FileName: [SP_ACC_GetInventoryTransactions]
CreatedBy/date: Ajay/05Jul'19
Description: getting records of inventory transactions for accounting
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Ajay/05Jul'19						created the script
2.		Vikas / 01-Jun-2020					update table 1 data -> exculde 'Capital Goods' Item type from table1
3.		NageshBB 23 Jul 2020				replaced createdOn by GoodsReceiptDate column
4.		Vikas 11th Aug 2020					replaced parameter @FromDate and @ToDate into @TransactionDate
5.      Sud:11Aug'20                        Date changed to GoodsReceiptDate. Voucher should be created on this date.
6.		NageshBB: 12Aug2020					Changes for get Consumed and dispatched items for accounting
											Now dispatch and consumption records taking from WARD_INV_Transaction table
7.		NageshBB: 19Aug2020					changes for inventory Consumption TotalAmount ,new tranfer rule which record get for StockManageOut
											, exclude cancel good receipt
8.		NageshBB: 20Aug2020					StockManageOut transaction get only on fiscal Year END date
9.      Vikas: 5th Oct 2020				    Added GoodsReceiptNo for remarks.
10.	    NageshBB/Sanjit sir: 13 July 2021   updated as per new inventory table structure
11		Aniket 21Sept2021					added allias for costprice in DispatchToDept as Price
12      Dev Narayan 2June2022               Added New Table For Other Charge
13      Dev Narayan 6 June 2022             Add New Table for Return To Department And Stock Manage In
*************************************************************************/
BEGIN
	Declare @FYStartDate datetime=(select top 1 StartDate from ACC_MST_FiscalYears where convert(date,@TransactionDate)
	between convert(date,Startdate) and convert(date,EndDate)),
	@FYEndDate datetime=(select top 1 EndDate from ACC_MST_FiscalYears where convert(date,@TransactionDate)
	between convert(date,Startdate) and convert(date,EndDate))
	--Table1: GoodReceipt
		SELECT 
			--gr.CreatedOn,
			gr.GoodsReceiptDate as 'CreatedOn',
			v.VendorName,
			gr.VendorId,
			 gr.PaymentMode,
			 itm.ItemCategoryId,
			 itm.ItemType,
			 itm.ItemName,
			 gr.TDSAmount,
			 gr.BillNo,									-- 26 March 2020:Vikas: added for invetory integration, mapping with accounting as per charak requirements.
			 gr.GoodsReceiptID,							-- 30 march 2020:Vikas: added GoodsReceiptID column
			 gritm.*,
			 gr.GoodsReceiptNo							-- 5th Oct 2020: Vikas: Added GoodsReceiptNo for remarks.
		FROM
			INV_TXN_GoodsReceipt gr 
			join INV_TXN_GoodsReceiptItems gritm on gr.GoodsReceiptID = gritm.GoodsReceiptId
			JOIN INV_MST_Vendor v ON gr.VendorId = v.VendorId 
			join INV_MST_Item itm on gritm.ItemId = itm.ItemId
		WHERE
			(gritm.IsTransferredToACC IS NULL OR gritm.IsTransferredToACC = 0) 
			AND (CONVERT(DATE, gr.GoodsReceiptDate)= CONVERT(DATE, @TransactionDate))  -- BETWEEN CONVERT(DATE, @FromDate) AND CONVERT(DATE, @ToDate))
			--AND itm.ItemType !='Capital Goods'
			and gr.IsCancel!=1 --excluded cancel gr	
	--Table2: WriteOffItems
		SELECT * 
		FROM
			INV_TXN_WriteOffItems 
		WHERE
			(IsTransferredToACC IS NULL OR IsTransferredToACC = 0)
			AND (CONVERT(DATE, CreatedOn)= CONVERT(DATE, @TransactionDate))-- BETWEEN CONVERT(DATE, @FromDate) AND CONVERT(DATE, @ToDate))
	--Table3: ReturnToVendor
		SELECT
			rv.*, 
			v.VendorName, 
			gr.PaymentMode,
			(SELECT ItemCategory from INV_TXN_GoodsReceiptItems where GoodsReceiptId= gr.GoodsReceiptID and GoodsReceiptItemId= rv.GoodsReceiptItemId) as 'ItemType'
		FROM
			INV_TXN_ReturnToVendorItems rv 
			JOIN INV_MST_Vendor v ON rv.VendorId = v.VendorId 
			JOIN INV_TXN_GoodsReceipt gr ON rv.GoodsReceiptId = gr.GoodsReceiptID 
		WHERE
			(rv.IsTransferredToACC IS NULL OR rv.IsTransferredToACC = 0)
			AND (CONVERT(DATE, rv.CreatedOn)= CONVERT(DATE, @TransactionDate))-- BETWEEN CONVERT(DATE, @FromDate) AND CONVERT(DATE, @ToDate))
	
	--Table4: DispatchToDept
	--NageshBB: 12Aug2020: changed table name for get dispatched records StockTransaction to WARD_INV_Transaction						
			--Select 
			--wardTxn.TransactionId,
			--CreatedOn=convert(date, wardTxn.TransactionDate),
			--TransactionType='INVDispatchToDept',					
			--wardTxn.Price, 
			--wardTxn.Quantity					
			--from WARD_INV_Transaction wardTxn join INV_MST_Item itm 
			--on wardTxn.ItemId=itm.ItemId
			--where (wardTxn.IsTransferToAcc IS NULL OR wardTxn.IsTransferToAcc =0) 
			--AND wardTxn.TransactionType='dispatched-items' AND itm.ItemType='consumables'
			--and (convert(date, wardTxn.TransactionDate)= convert(date, @TransactionDate))	
			Select 
			stkTxn.StockTransactionId as TransactionId,
			CreatedOn=convert(date, stkTxn.TransactionDate),
			TransactionType='INVDispatchToDept',					
			stkTxn.CostPrice as Price, 
			stkTxn.OutQty as Quantity
			from INV_TXN_StockTransaction stkTxn join INV_MST_Item itm 
			on stkTxn.ItemId=itm.ItemId
			where (stkTxn.IsTransferredToACC IS NULL OR stkTxn.IsTransferredToACC =0) 
			AND stkTxn.TransactionType='dispatched-item-from' AND itm.ItemType='consumables'
			and (convert(date, stkTxn.TransactionDate)= convert(date, @TransactionDate))

	-- Table 5 :INVDeptConsumedGoods
	--NageshBB: 12Aug2020: changed table name for get consumed records. WARD_INV_Consumption to WARD_INV_Transaction
		--SELECT 
		--		wardTxn.TransactionId,
		--		sb.SubCategoryId,
		--		sb.SubCategoryName,   
		--		CreatedOn=convert(date,wardTxn.TransactionDate),											
		--		TotalAmount= wardTxn.Quantity * wardTxn.Price
		--	FROM WARD_INV_Transaction wardTxn
		--		join INV_MST_Item itm on wardTxn.ItemId= itm.ItemId
		--		join INV_MST_ItemSubCategory sb on itm.SubCategoryId= sb.SubCategoryId						
		--	WHERE (wardTxn.IsTransferToAcc IS NULL OR wardTxn.IsTransferToAcc=0)  
		--	AND wardTxn.TransactionType='consumption-items' AND itm.ItemType='consumables'
		--    AND (CONVERT(DATE, wardTxn.TransactionDate)= CONVERT(DATE, @TransactionDate))	
		SELECT 
				stkTxn.StockTransactionId as  TransactionId,
				sb.SubCategoryId,
				sb.SubCategoryName,   
				CreatedOn=convert(date,stkTxn.TransactionDate),											
				TotalAmount= stkTxn.OutQty * stkTxn.CostPrice
			FROM INV_TXN_StockTransaction stkTxn
				join INV_MST_Item itm on stkTxn.ItemId= itm.ItemId
				join INV_MST_ItemSubCategory sb on itm.SubCategoryId= sb.SubCategoryId						
			WHERE (stkTxn.IsTransferredToACC IS NULL OR stkTxn.IsTransferredToACC=0)  
			AND stkTxn.TransactionType='consumption-items' AND itm.ItemType='consumables'
		    AND (CONVERT(DATE, stkTxn.TransactionDate)= CONVERT(DATE, @TransactionDate))
		-- Table 6 :INVStockManageOut	
		--NageshBB: asper discussion we need single voucher for whole year txn items 
		--so here we will get data as per fiscal year enddate and transaction date will be fiscal year end date		
		--Declare @TransactionDate datetime='2020-05-13 12:59:22.307'

		--SELECT 
		--			0 'TransactionId',
		--			StkTxn.StockTxnId,
		--			sb.SubCategoryId,
		--			sb.SubCategoryName, 
		--			TransactionType='INVStockManageOut',
		--			CreatedOn=  convert(date,@FYEndDate),											
		--			TotalAmount= StkTxn.Quantity * StkTxn.Price
		--	FROM INV_TXN_StockTransaction StkTxn
		--			join INV_MST_Item itm on StkTxn.ItemId= itm.ItemId
		--			join INV_MST_ItemSubCategory sb on itm.SubCategoryId= sb.SubCategoryId						
		--		WHERE (StkTxn.IsTransferredToACC IS NULL OR StkTxn.IsTransferredToACC=0)  
		--		AND StkTxn.TransactionType in ('fy-managed-items','stockmanaged-items') and InOut='out'
		--	    AND ((CONVERT(DATE, StkTxn.TransactionDate) between CONVERT(DATE, @FYStartDate) and CONVERT(DATE, @FYEndDate) )) 
		--		AND convert(date,@FYEndDate)=convert(date,@TransactionDate)
		--		AND itm.ItemType='consumables'
				SELECT 					
					StkTxn.StockTransactionId as TransactionId,
					sb.SubCategoryId,
					sb.SubCategoryName, 
					TransactionType='INVStockManageOut',
					CreatedOn=  convert(date,StkTxn.CreatedOn),											
					TotalAmount= StkTxn.OutQty * StkTxn.CostPrice
			FROM INV_TXN_StockTransaction StkTxn
					join INV_MST_Item itm on StkTxn.ItemId= itm.ItemId
					join INV_MST_ItemSubCategory sb on itm.SubCategoryId= sb.SubCategoryId						
				WHERE (StkTxn.IsTransferredToACC IS NULL OR StkTxn.IsTransferredToACC=0)  
				AND StkTxn.TransactionType in ('fy-managed-item','stock-managed-item') and StkTxn.OutQty >0
			    AND ((CONVERT(DATE, StkTxn.TransactionDate) between CONVERT(DATE, @FYStartDate) and CONVERT(DATE, @FYEndDate) )) 
				AND convert(date,StkTxn.CreatedOn)=convert(date,@TransactionDate)
				--AND itm.ItemType='consumables'
		--temp update date '2020-08-09 07:49:19.017' to '2020-08-09 07:49:19.017'
		--update WARD_INV_Transaction set TransactionDate='2020-05-06 07:49:19.017'
		--where TransactionType in ('fy-stock-manage') and InOut='out'
		--union
		--SELECT 
		--			wardTxn.TransactionId,
		--			--0  'StockTxnId',
		--			sb.SubCategoryId,
		--			sb.SubCategoryName,  
		--			TransactionType='INVStockManageOut',
		--			CreatedOn= convert(date,@FYEndDate),											
		--			TotalAmount= wardTxn.Quantity * wardTxn.Price
		--		FROM WARD_INV_Transaction wardTxn
		--			join INV_MST_Item itm on wardTxn.ItemId= itm.ItemId
		--			join INV_MST_ItemSubCategory sb on itm.SubCategoryId= sb.SubCategoryId						
		--		WHERE (wardTxn.IsTransferToAcc IS NULL OR wardTxn.IsTransferToAcc=0)  
		--		AND wardTxn.TransactionType in ('fy-stock-manage') and InOut='out'
		--	    AND ((CONVERT(DATE, wardTxn.TransactionDate) between CONVERT(DATE, @FYStartDate) and CONVERT(DATE, @FYEndDate) )) 					
		--		AND convert(date,@FYEndDate)=convert(date,@TransactionDate)
		--		AND itm.ItemType='consumables'
	 
	 --Table 7 : Other Chareges
			SELECT oc.GoodsReceiptItemId,
				   oc.ChargeId,
				   oc.VendorId,
				   ved.VendorName,
				   oc.Amount as 'Amount',
				   oc.VATAmount as 'VATAmount',
				   oc.TotalAmount as 'TotalAmount',
				   0 as 'LedgerId'
					FROM
					INV_MAP_GoodsReceiptItems_OtherCharges oc
					JOIN INV_MST_Vendor ved ON oc.VendorId = ved.VendorId
					WHERE CONVERT(DATE,oc.CreatedOn) = CONVERT (DATE,@TransactionDate)

	 --Table 8 : Return To Department	
			Select 
			stkTxn.StockTransactionId as TransactionId,
			CreatedOn=convert(date, stkTxn.TransactionDate),
			TransactionType='INVDispatchToDeptReturn',					
			stkTxn.CostPrice as Price, 
			stkTxn.OutQty as Quantity
			from INV_TXN_StockTransaction stkTxn join INV_MST_Item itm 
			on stkTxn.ItemId=itm.ItemId
			where (stkTxn.IsTransferredToACC IS NULL OR stkTxn.IsTransferredToACC =0) 
			AND stkTxn.TransactionType='returned-item-from' AND itm.ItemType='consumables'
			and (convert(date, stkTxn.TransactionDate)= convert(date, @TransactionDate))
				
	--Table 9 : Stock Manage In
			SELECT 					
			StkTxn.StockTransactionId as TransactionId,
			sb.SubCategoryId,
			sb.SubCategoryName, 
			TransactionType='INVStockManageIn',
			CreatedOn=  convert(date,StkTxn.CreatedOn),											
			TotalAmount= StkTxn.InQty * StkTxn.CostPrice
			FROM INV_TXN_StockTransaction StkTxn
					join INV_MST_Item itm on StkTxn.ItemId= itm.ItemId
					join INV_MST_ItemSubCategory sb on itm.SubCategoryId= sb.SubCategoryId						
				WHERE (StkTxn.IsTransferredToACC IS NULL OR StkTxn.IsTransferredToACC=0)  
				AND StkTxn.TransactionType in ('fy-managed-item','stock-managed-item') and StkTxn.InQty >0
			    AND ((CONVERT(DATE, StkTxn.TransactionDate) between CONVERT(DATE, @FYStartDate) and CONVERT(DATE, @FYEndDate) )) 
				AND convert(date,StkTxn.CreatedOn)=convert(date,@TransactionDate)
END