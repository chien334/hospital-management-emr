CREATE OR REPLACE FUNCTION sp_report_inventory_vendortransactionreport(
    p_fiscalyearid INT DEFAULT NULL,
    p_vendorid INT DEFAULT NULL
)
RETURNS TABLE (
    "FiscalYearId" INT,
    "VendorId" INT,
    "SubTotal" DECIMAL,
    "VATTotal" DECIMAL,
    "DiscountAmount" INT,
    "TotalAmount" DECIMAL
) AS $$
BEGIN
    
    	RETURN QUERY SELECT 
    		fiscalyearid,
    		vendorid,
    		sum(a.subtotal) AS "SubTotal",
    		sum(a.vattotal) AS "VATTotal",
    		sum(a.discountamount) AS "DiscountAmount",
    		sum(a.totalamount) AS "TotalAmount"
    	 from (
    				select
    						fs.fiscalyearname,
    						fs.fiscalyearid,
    						ved.vendorid,
    						(gd.subtotal) AS "SubTotal",
    						(gd.vattotal) AS "VATTotal",
    						(gd.discountamount) AS "DiscountAmount",
    						(gd.totalamount) AS "TotalAmount",
    						'gr_sale' as "txntype"
    					from inv_txn_goodsreceipt gd 
    						left join bil_cfg_fiscalyears fs on fs.fiscalyearid = p_fiscalyearid
    						left join inv_mst_vendor ved on gd.vendorid = ved.vendorid 
    					where  
    						gd.createdon>(fs.startyear)::date and gd.createdon<(fs.endyear)::date
    						and gd.iscancel = 0 
    				  union all
    
    						select 
    								fs.fiscalyearname,
    								fs.fiscalyearid,
    								ret.vendorid,
    								-(ret.totalamount + (gritm.discountamount/gritm.receivedquantity * ret.quantity )) AS "SubTotal",								 
    								-(gritm.vatamount/gritm.receivedquantity * ret.quantity) as "vatamount",
    								-(gritm.discountamount/gritm.receivedquantity * ret.quantity ) AS "DiscountAmount",								 
    								-ret.totalamount AS "TotalAmount",
    								'gr_return' as "txntype"
    						from inv_txn_returntovendoritems ret
    						join inv_txn_goodsreceiptitems gritm on  ret.goodsreceiptitemid = gritm.goodsreceiptitemid 
    						left join bil_cfg_fiscalyears fs on fs.fiscalyearid =p_fiscalyearid
    					where
    						ret.createdon>(fs.startyear)::date and ret.createdon<(fs.endyear)::date	
    				
    
    	) a
    	where  (a.totalamount>= 100000) and (vendorid = p_vendorid or coalesce(p_vendorid, '') = '')	
    	group by fiscalyearid,vendorid;
END;
$$ LANGUAGE plpgsql;