/*
FileName: [SP_Report_Inventory_SupplierWiseStock] 
CreatedBy/date: Aniket/02-10-2021
Description: To get the Details of Supplier Wise Stock Report
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1.    Aniket/02-10-2021                    created the script
2.	  Aniket/20-10-2021                    updated Opening and Closing stock
3.	  Sanjit/28-10-2021					   revised the changes (correction of opening and closing quantity logic)
4.    Rohit/15-11-2021					   Changed the parameter sequence (Item wise and Store wise filter was not working.)
*/
CREATE OR REPLACE FUNCTION sp_report_inventory_supplierwisestock(
    p_fromdate TIMESTAMP,
    p_todate TIMESTAMP,
    p_vendorid INT DEFAULT NULL,
    p_storeid INT DEFAULT NULL,
    p_itemid INT DEFAULT NULL
)
RETURNS TABLE (
    "OpeningStock" VARCHAR,
    "VendorName" VARCHAR,
    "Category" VARCHAR,
    "SubCategory" VARCHAR,
    "ItemCode" VARCHAR,
    "ItemName" VARCHAR,
    "StoreName" VARCHAR,
    "PurchaseQty" INT,
    "BatchNo" VARCHAR,
    "ExpiryDate" TIMESTAMP,
    "ConsumedQty" TIMESTAMP,
    "OtherQtyTxn" INT,
    "ClosingStock" VARCHAR
) AS $$
DECLARE
    v_consumptionordispatch VARCHAR := (SELECT ParameterValue FROM CORE_CFG_Parameters WHERE ParameterName = 'ConsumptionOrDispatchForReports' and ParameterGroupName = 'Inventory');
BEGIN
    begin
    	-- to check if the hospital uses dispatch or consumption method to finish the stock
    	 
    
    	RETURN QUERY SELECT 
    		coalesce(gr.openingqty,0) AS "OpeningStock", 
    		v.vendorname AS "VendorName",
    		c.itemcategoryname AS "Category",
    		sc.subcategoryname AS "SubCategory",
    		i.code AS "ItemCode",
    		i.itemname AS "ItemName",
    		str.name AS "StoreName",
    		coalesce(gr.purchaseqty,0) AS "PurchaseQty",
    		gr.batchno AS "BatchNo",
    		gr.expirydate AS "ExpiryDate",
    		coalesce(gr.consumedqty,0) AS "ConsumedQty",
    		case when gr.writeoffqty > 0 then (-gr.writeoffqty)::varchar || ' (write-off) ' else '' end +
    		case when gr.purchasereturnqty > 0 then (-gr.purchasereturnqty)::varchar || ' (purchase-return) ' else '' end ||
    		case when gr.stkmanageqty > 0 then (gr.stkmanageqty)::varchar || ' (stock-manage)' else '' end
    		AS "OtherQtyTxn",
    		coalesce(gr.openingqty,0) + coalesce(gr.purchaseqty,0) - coalesce(gr.consumedqty,0) - coalesce(gr.writeoffqty,0) - coalesce(gr.purchasereturnqty,0) || coalesce(gr.stkmanageqty,0) AS "ClosingStock"
    	from 
    		inv_mst_item i
    		cross join inv_mst_vendor v
    		cross join phrm_mst_store str
    		inner join inv_mst_itemcategory c on i.itemcategoryid = c.itemcategoryid
    		inner join inv_mst_itemsubcategory sc on i.subcategoryid = sc.subcategoryid
    		inner join 
    		(
    			select 
    				x.storeid, x.itemid, x.batchno, x.expirydate, x.vendorid, sum(x.openingqty) as openingqty, sum(x.purchaseqty) AS "PurchaseQty", sum(x.consumedqty) AS "ConsumedQty", sum(x.writeoffqty) as writeoffqty, sum(x.purchasereturnqty) as purchasereturnqty, sum(stkmanageqty) as stkmanageqty
    			from
    			(
    				--to calculate the opening quantity, we take the goods receipts upto the from date provided
    				select gr.storeid, gri.itemid, s.batchno, s.expirydate, gr.vendorid, sum(coalesce(st.inqty,0)) - sum(coalesce(st.outqty,0)) as openingqty, 0 AS "PurchaseQty", 0 AS "ConsumedQty", 0 as writeoffqty, 0 as purchasereturnqty, 0 as stkmanageqty
    				from
    					inv_txn_goodsreceiptitems gri 
    					inner join inv_txn_goodsreceipt gr on gri.goodsreceiptid = gr.goodsreceiptid
    					inner join inv_mst_stock s on gri.stockid = s.stockid
    					inner join inv_txn_stocktransaction st on s.stockid = st.stockid
    				where (st.transactiondate)::date <= p_fromdate and
    				--used stocktxn date instead of grdate since calculation of opening depends on stktxn date. taking gr date may bring unwanted data in the output				
    					(gr.vendorid = p_vendorid or p_vendorid is null) and
    					(gri.itemid = p_itemid or p_itemid is null) and
    					(gr.storeid = p_storeid or p_storeid is null)
    				group by gr.storeid, gri.itemid, s.batchno, s.expirydate, gr.vendorid
    
    				union all
    
    				--to calculate the purchased, consumed and closing quantity, we take the goods receipts from the provided date range
    				select	
    					gr.storeid, gri.itemid, s.batchno, s.expirydate, gr.vendorid, 
    					0 as openingqty, 
    					sum( 
    						case 
    							when st.transactiontype in ('gr-item','goodreceipt-items') then st.inqty 
    							when st.transactiontype = 'cancel-gr-items' then -st.outqty 
    							else 0 
    						end
    					   ) AS "PurchaseQty", 
    					sum( 
    							case
    								when v_consumptionordispatch = 'consumption' and st.transactiontype = 'consumption-items' then st.outqty
    								when v_consumptionordispatch != 'consumption' and st.transactiontype in ('dispatched-item-from','dispatched-item') then st.outqty
    								else 0
    							end
    						) AS "ConsumedQty",			   
    					sum(
    							case
    								when st.transactiontype = 'writeoff-items' then st.outqty
    								else 0
    							end
    					   ) as writeoffqty,
    					sum(
    							case
    								when st.transactiontype = 'returntovendor-items' then st.outqty
    								else 0
    							end
    					   ) as purchasereturnqty,
    					sum(
    							case
    								when st.transactiontype in ('stock-managed-item','fy-managed-item') and st.inqty > 0 then st.inqty
    								when st.transactiontype in ('stock-managed-item','fy-managed-item') and st.outqty > 0 then -st.outqty
    								else 0
    							end
    					   ) as stkmanageqty
    
    				from
    					inv_txn_goodsreceiptitems gri 
    					inner join inv_txn_goodsreceipt gr on gri.goodsreceiptid = gr.goodsreceiptid
    					inner join inv_mst_stock s on gri.stockid = s.stockid
    					inner join inv_txn_stocktransaction st on s.stockid = st.stockid
    				where (st.transactiondate)::date between p_fromdate and p_todate and
    				--used stocktxn date instead of grdate since calculation of opening depends on stktxn date. taking gr date may bring unwanted data in the output			
    					(gr.vendorid = p_vendorid or p_vendorid is null) and
    					(gri.itemid = p_itemid or p_itemid is null) and
    					(gr.storeid = p_storeid or p_storeid is null)
    				group by gr.storeid, gri.itemid, s.batchno, s.expirydate, gr.vendorid
    			) x
    			-- if a same item with same batch and expiry date was supplied from same vendor, then report will show them as a single row, hence the group by is used as below
    			group by x.storeid, x.itemid, x.batchno, x.expirydate, x.vendorid
    		)
    		gr on i.itemid = gr.itemid and v.vendorid = gr.vendorid and str.storeid = gr.storeid
    	where (coalesce(gr.openingqty,0) != 0 or coalesce(gr.purchaseqty,0) != 0 or coalesce(gr.consumedqty,0) != 0)
    	order by coalesce(gr.purchaseqty,0) desc;
    end;
END;
$$ LANGUAGE plpgsql;