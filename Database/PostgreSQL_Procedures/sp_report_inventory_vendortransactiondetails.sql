/*
FileName: [SP_Report_Inventory_VendorTransactionDetails]
CreatedBy/date: 
Description: 
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1      	Vikas:28th Jan 2020					Details transaction script for vendor transaction more than 100000	

*/
CREATE OR REPLACE FUNCTION sp_report_inventory_vendortransactiondetails(
    p_fiscalyearid INT DEFAULT NULL,
    p_vendorid INT DEFAULT NULL
)
RETURNS TABLE (
    "VendorId" INT,
    "ItemId" INT,
    "ItemName" VARCHAR,
    "Sales_SubTotal" DECIMAL,
    "Sales_VatAmount" DECIMAL,
    "Sales_DiscountAmount" INT,
    "Sales_TotalAmount" DECIMAL,
    "Ret_SubTotal" DECIMAL,
    "Ret_VATTotal" DECIMAL,
    "Ret_DiscountAmount" INT,
    "Ret_TotalAmount" DECIMAL,
    "Total" DECIMAL
) AS $$
BEGIN
    
    
    	RETURN QUERY SELECT 
    		vendorid,		
    		itemid,
    		itemname,
    		sum(a.subtotal) AS "Sales_SubTotal",
    		sum(a.vattotal) AS "Sales_VatAmount",
    		sum(a.discountamount) AS "Sales_DiscountAmount",
    		sum(a.totalamount) AS "Sales_TotalAmount",
    
    		sum(a.ret_subtotal) AS "Ret_SubTotal",
    		sum(a.ret_vattotal) AS "Ret_VATTotal",
    		sum(a.ret_discountamount) AS "Ret_DiscountAmount",
    		sum(a.ret_totalamount) AS "Ret_TotalAmount",
    		(sum(a.totalamount)-sum(a.ret_totalamount)) AS "Total"
    
    	 from (
    				select
    						ved.vendorid,
    						item.itemname,
    						item.itemid,
    						(gd.subtotal) as "subtotal",
    						(gd.vattotal) as "vattotal",
    						(gd.discountamount) as "discountamount",
    						(gd.totalamount) as "totalamount",
    
    						0 AS "Ret_SubTotal",
    						0 AS "Ret_VATTotal",
    						0 AS "Ret_DiscountAmount",
    						0 AS "Ret_TotalAmount"
    
    					from inv_txn_goodsreceipt gd 
    						left join bil_cfg_fiscalyears fs on fs.fiscalyearid = p_fiscalyearid
    						left join inv_mst_vendor ved on gd.vendorid = ved.vendorid 
    						left join inv_txn_goodsreceiptitems gritem on gd.goodsreceiptid= gritem.goodsreceiptid
    						left join inv_mst_item item on gritem.itemid = item.itemid	
    					where  
    						gd.createdon>(fs.startyear)::date and gd.createdon<(fs.endyear)::date
    						and gd.iscancel = 0 
    						and (gritem.goodsreceiptitemid not in (select goodsreceiptitemid from inv_txn_returntovendoritems))
    
    				  union all
    						select 
    								ret.vendorid,
    								item.itemname,
    								item.itemid,
    								0 as "subtotal",
    								0 as "vattotal",
    								0 as "discountamount",
    								0 as "totalamount",
    								((ret.totalamount + (gritm.discountamount/gritm.receivedquantity * ret.quantity ))) AS "Ret_SubTotal",								 
    								((gritm.vatamount/gritm.receivedquantity * ret.quantity)) AS "Ret_VATTotal",
    								((gritm.discountamount/gritm.receivedquantity * ret.quantity )) AS "Ret_DiscountAmount",								 
    								(ret.totalamount) AS "Ret_TotalAmount"
    						from inv_txn_returntovendoritems ret
    						join inv_txn_goodsreceiptitems gritm on  ret.goodsreceiptitemid = gritm.goodsreceiptitemid 
    						left join bil_cfg_fiscalyears fs on fs.fiscalyearid = p_fiscalyearid
    						left join inv_mst_item item on gritm.itemid = item.itemid
    					where
    						ret.createdon>(fs.startyear)::date and ret.createdon<(fs.endyear)::date	
    	) a
    	where vendorid = p_vendorid or coalesce(p_vendorid, '') = ''
    	group by vendorid , itemname,itemid;
END;
$$ LANGUAGE plpgsql;