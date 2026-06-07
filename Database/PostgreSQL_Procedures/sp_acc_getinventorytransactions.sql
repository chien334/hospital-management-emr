CREATE OR REPLACE FUNCTION sp_acc_getinventorytransactions(
    p_transactiondate DATE,
    p_hospitalid INT
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
    ref3 refcursor := 'cursor3';
    ref4 refcursor := 'cursor4';
    ref5 refcursor := 'cursor5';
    ref6 refcursor := 'cursor6';
    ref7 refcursor := 'cursor7';
    ref8 refcursor := 'cursor8';
    ref9 refcursor := 'cursor9';
    v_fystartdate TIMESTAMP := (select  StartDate from ACC_MST_FiscalYears where (p_transactiondate)::date
	between (Startdate)::date and (EndDate)::date LIMIT 1);
    v_fyenddate TIMESTAMP := (select  EndDate from ACC_MST_FiscalYears where (p_transactiondate)::date
	between (Startdate)::date and (EndDate)::date LIMIT 1);
BEGIN
    -- exec "sp_acc_getinventorytransactions"	'2022-08-17',1
    /************************************************************************
    filename: "sp_acc_getinventorytransactions"
    createdby/date: ajay/05jul'19
    Description: getting records of inventory transactions for accounting
    Change History
    S.No.    UpdatedBy/Date                        Remarks
    1       Ajay/05Jul'19						created the script
    2.		vikas / 01-jun-2020					update table 1 data -> exculde 'Capital Goods' item type from table1
    3.		nageshbb 23 jul 2020				replaced createdon by goodsreceiptdate column
    4.		vikas 11th aug 2020					replaced parameter v_fromdate and v_todate into p_transactiondate
    5.      sud:11aug'20                        Date changed to GoodsReceiptDate. Voucher should be created on this date.
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
    
    	
    	--Table1: GoodReceipt
    		OPEN ref1 FOR SELECT 
    			--gr.CreatedOn,
    			gr.GoodsReceiptDate AS "CreatedOn",
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
    			AND ((gr.GoodsReceiptDate)::DATE= (p_transactiondate)::DATE)  -- BETWEEN CONVERT(DATE, v_fromdate) AND CONVERT(DATE, v_todate))
    			--AND itm.ItemType !='capital goods'
    			and gr.IsCancel!=1;
        RETURN NEXT ref1; --excluded cancel gr	
    	--Table2: WriteOffItems
    		OPEN ref2 FOR SELECT * 
    		FROM
    			INV_TXN_WriteOffItems 
    		WHERE
    			(IsTransferredToACC IS NULL OR IsTransferredToACC = 0)
    			AND ((CreatedOn)::DATE= (p_transactiondate)::DATE);
        RETURN NEXT ref2;-- BETWEEN CONVERT(DATE, v_fromdate) AND CONVERT(DATE, v_todate))
    	--Table3: ReturnToVendor
    		OPEN ref3 FOR SELECT
    			rv.*, 
    			v.VendorName, 
    			gr.PaymentMode,
    			(SELECT ItemCategory from INV_TXN_GoodsReceiptItems where GoodsReceiptId= gr.GoodsReceiptID and GoodsReceiptItemId= rv.GoodsReceiptItemId) AS "ItemType"
    		FROM
    			INV_TXN_ReturnToVendorItems rv 
    			JOIN INV_MST_Vendor v ON rv.VendorId = v.VendorId 
    			JOIN INV_TXN_GoodsReceipt gr ON rv.GoodsReceiptId = gr.GoodsReceiptID 
    		WHERE
    			(rv.IsTransferredToACC IS NULL OR rv.IsTransferredToACC = 0)
    			AND ((rv.CreatedOn)::DATE= (p_transactiondate)::DATE);
        RETURN NEXT ref3;-- BETWEEN CONVERT(DATE, v_fromdate) AND CONVERT(DATE, v_todate))
    	
    	--Table4: DispatchToDept
    	--NageshBB: 12Aug2020: changed table name for get dispatched records StockTransaction to WARD_INV_Transaction						
    			--Select 
    			--wardTxn.TransactionId,
    			--CreatedOn=convert(date, wardTxn.TransactionDate),
    			--TransactionType='invdispatchtodept',					
    			--wardTxn.Price, 
    			--wardTxn.Quantity					
    			--from WARD_INV_Transaction wardTxn join INV_MST_Item itm 
    			--on wardTxn.ItemId=itm.ItemId
    			--where (wardTxn.IsTransferToAcc IS NULL OR wardTxn.IsTransferToAcc =0) 
    			--AND wardTxn.TransactionType='dispatched-items' AND itm.ItemType='consumables'
    			--and (convert(date, wardTxn.TransactionDate)= convert(date, p_transactiondate))	
    			OPEN ref4 FOR Select 
    			stkTxn.StockTransactionId as TransactionId,
    			CreatedOn=(stkTxn.TransactionDate)::date,
    			TransactionType='invdispatchtodept',					
    			stkTxn.CostPrice as Price, 
    			stkTxn.OutQty as Quantity
    			from INV_TXN_StockTransaction stkTxn join INV_MST_Item itm 
    			on stkTxn.ItemId=itm.ItemId
    			where (stkTxn.IsTransferredToACC IS NULL OR stkTxn.IsTransferredToACC =0) 
    			AND stkTxn.TransactionType='dispatched-item-from' AND itm.ItemType='consumables'
    			and ((stkTxn.TransactionDate)::date= (p_transactiondate)::date);
        RETURN NEXT ref4;
    
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
    		--    AND (CONVERT(DATE, wardTxn.TransactionDate)= CONVERT(DATE, p_transactiondate))	
    		OPEN ref5 FOR SELECT 
    				stkTxn.StockTransactionId as  TransactionId,
    				sb.SubCategoryId,
    				sb.SubCategoryName,   
    				CreatedOn=(stkTxn.TransactionDate)::date,											
    				TotalAmount= stkTxn.OutQty * stkTxn.CostPrice
    			FROM INV_TXN_StockTransaction stkTxn
    				join INV_MST_Item itm on stkTxn.ItemId= itm.ItemId
    				join INV_MST_ItemSubCategory sb on itm.SubCategoryId= sb.SubCategoryId						
    			WHERE (stkTxn.IsTransferredToACC IS NULL OR stkTxn.IsTransferredToACC=0)  
    			AND stkTxn.TransactionType='consumption-items' AND itm.ItemType='consumables'
    		    AND ((stkTxn.TransactionDate)::DATE= (p_transactiondate)::DATE);
        RETURN NEXT ref5;
    		-- Table 6 :INVStockManageOut	
    		--NageshBB: asper discussion we need single voucher for whole year txn items 
    		--so here we will get data as per fiscal year enddate and transaction date will be fiscal year end date		
    		--Declare p_transactiondate TIMESTAMP='2020-05-13 12:59:22.307'
    
    		--SELECT 
    		--			0 'transactionid',
    		--			StkTxn.StockTxnId,
    		--			sb.SubCategoryId,
    		--			sb.SubCategoryName, 
    		--			TransactionType='invstockmanageout',
    		--			CreatedOn=  convert(date,v_fyenddate),											
    		--			TotalAmount= StkTxn.Quantity * StkTxn.Price
    		--	FROM INV_TXN_StockTransaction StkTxn
    		--			join INV_MST_Item itm on StkTxn.ItemId= itm.ItemId
    		--			join INV_MST_ItemSubCategory sb on itm.SubCategoryId= sb.SubCategoryId						
    		--		WHERE (StkTxn.IsTransferredToACC IS NULL OR StkTxn.IsTransferredToACC=0)  
    		--		AND StkTxn.TransactionType in ('fy-managed-items','stockmanaged-items') and InOut='out'
    		--	    AND ((CONVERT(DATE, StkTxn.TransactionDate) between CONVERT(DATE, v_fystartdate) and CONVERT(DATE, v_fyenddate) )) 
    		--		AND convert(date,v_fyenddate)=convert(date,p_transactiondate)
    		--		AND itm.ItemType='consumables'
    				OPEN ref6 FOR SELECT 					
    					StkTxn.StockTransactionId as TransactionId,
    					sb.SubCategoryId,
    					sb.SubCategoryName, 
    					TransactionType='invstockmanageout',
    					CreatedOn=  (StkTxn.CreatedOn)::date,											
    					TotalAmount= StkTxn.OutQty * StkTxn.CostPrice
    			FROM INV_TXN_StockTransaction StkTxn
    					join INV_MST_Item itm on StkTxn.ItemId= itm.ItemId
    					join INV_MST_ItemSubCategory sb on itm.SubCategoryId= sb.SubCategoryId						
    				WHERE (StkTxn.IsTransferredToACC IS NULL OR StkTxn.IsTransferredToACC=0)  
    				AND StkTxn.TransactionType in ('fy-managed-item','stock-managed-item') and StkTxn.OutQty >0
    			    AND (((StkTxn.TransactionDate)::DATE between (v_fystartdate)::DATE and (v_fyenddate)::DATE )) 
    				AND (StkTxn.CreatedOn)::date=(p_transactiondate)::date;
        RETURN NEXT ref6;
    				--AND itm.ItemType='consumables'
    		--temp update date '2020-08-09 07:49:19.017' to '2020-08-09 07:49:19.017'
    		--update WARD_INV_Transaction set TransactionDate='2020-05-06 07:49:19.017'
    		--where TransactionType in ('fy-stock-manage') and InOut='out'
    		--union
    		--SELECT 
    		--			wardTxn.TransactionId,
    		--			--0  'stocktxnid',
    		--			sb.SubCategoryId,
    		--			sb.SubCategoryName,  
    		--			TransactionType='invstockmanageout',
    		--			CreatedOn= convert(date,v_fyenddate),											
    		--			TotalAmount= wardTxn.Quantity * wardTxn.Price
    		--		FROM WARD_INV_Transaction wardTxn
    		--			join INV_MST_Item itm on wardTxn.ItemId= itm.ItemId
    		--			join INV_MST_ItemSubCategory sb on itm.SubCategoryId= sb.SubCategoryId						
    		--		WHERE (wardTxn.IsTransferToAcc IS NULL OR wardTxn.IsTransferToAcc=0)  
    		--		AND wardTxn.TransactionType in ('fy-stock-manage') and InOut='out'
    		--	    AND ((CONVERT(DATE, wardTxn.TransactionDate) between CONVERT(DATE, v_fystartdate) and CONVERT(DATE, v_fyenddate) )) 					
    		--		AND convert(date,v_fyenddate)=convert(date,p_transactiondate)
    		--		AND itm.ItemType='consumables'
    	 
    	 --Table 7 : Other Chareges
    			OPEN ref7 FOR SELECT oc.GoodsReceiptItemId,
    				   oc.ChargeId,
    				   oc.VendorId,
    				   ved.VendorName,
    				   oc.Amount AS "Amount",
    				   oc.VATAmount AS "VATAmount",
    				   oc.TotalAmount AS "TotalAmount",
    				   0 AS "LedgerId"
    					FROM
    					INV_MAP_GoodsReceiptItems_OtherCharges oc
    					JOIN INV_MST_Vendor ved ON oc.VendorId = ved.VendorId
    					WHERE (oc.CreatedOn)::DATE = (p_transactiondate)::DATE;
        RETURN NEXT ref7;
    
    	 --Table 8 : Return To Department	
    			OPEN ref8 FOR Select 
    			stkTxn.StockTransactionId as TransactionId,
    			CreatedOn=(stkTxn.TransactionDate)::date,
    			TransactionType='invdispatchtodeptreturn',					
    			stkTxn.CostPrice as Price, 
    			stkTxn.OutQty as Quantity
    			from INV_TXN_StockTransaction stkTxn join INV_MST_Item itm 
    			on stkTxn.ItemId=itm.ItemId
    			where (stkTxn.IsTransferredToACC IS NULL OR stkTxn.IsTransferredToACC =0) 
    			AND stkTxn.TransactionType='returned-item-from' AND itm.ItemType='consumables'
    			and ((stkTxn.TransactionDate)::date= (p_transactiondate)::date);
        RETURN NEXT ref8;
    				
    	--Table 9 : Stock Manage In
    			OPEN ref9 FOR SELECT 					
    			StkTxn.StockTransactionId as TransactionId,
    			sb.SubCategoryId,
    			sb.SubCategoryName, 
    			TransactionType='invstockmanagein',
    			CreatedOn=  (StkTxn.CreatedOn)::date,											
    			TotalAmount= StkTxn.InQty * StkTxn.CostPrice
    			FROM INV_TXN_StockTransaction StkTxn
    					join INV_MST_Item itm on StkTxn.ItemId= itm.ItemId
    					join INV_MST_ItemSubCategory sb on itm.SubCategoryId= sb.SubCategoryId						
    				WHERE (StkTxn.IsTransferredToACC IS NULL OR StkTxn.IsTransferredToACC=0)  
    				AND StkTxn.TransactionType in ('fy-managed-item','stock-managed-item') and stktxn.inqty >0
    			    and (((stktxn.transactiondate)::date between (v_fystartdate)::date and (v_fyenddate)::date )) 
    				and (stktxn.createdon)::date=(p_transactiondate)::date;
        return next ref9;
END;
$$ LANGUAGE plpgsql;