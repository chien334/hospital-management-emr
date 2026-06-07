CREATE OR REPLACE FUNCTION sp_report_quotation_rates(
    p_purchaseorderid INT
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    v_columns VARCHAR := '';
    v_sql VARCHAR := '';
BEGIN
    /*
    filename: "sp_report_quotation_rates" 
    createdby/date: rajib/22-01-2021
    description: to get the details of report quotion rates
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1.		rajib/22-01-2021						created the script
    */
    
    
    
    	open ref1 for select v_columns ||= quotename(v.vendorname) || ',' 
    	from
    	  (select 
    		distinct q.vendorname
    		from inv_txn_purchaseorderitems poi 
    		left join inv_quotationitems qi on qi.itemid = poi.itemid
    		join inv_quotation q on qi.quotationid = q.quotationid
    		where poi.purchaseorderid = p_purchaseorderid
        )  v;
        return next ref1;
    
    	-- remove the last comma
    	v_columns := left(v_columns, len(v_columns) - 1);
    
    	v_sql := 'select * from (
    	select QI.ItemName, Q.VendorName, QI.Price
    	from INV_TXN_PurchaseOrder PO
    	join INV_TXN_PurchaseOrderItems POI on PO.PurchaseOrderId = POI.PurchaseOrderId
    	left join INV_QuotationItems QI on QI.ItemId = POI.ItemId
    	join INV_Quotation Q on QI.QuotationId = Q.QuotationId
    	where POI.PurchaseOrderId = '|| (p_purchaseorderid)::varchar ||'
    	) t
    	PIVOT( SUM(t.Price) 
    	FOR t.VendorName IN ('|| v_columns || ')
    	) AS pivot_table';
    
    	-- execute the dynamic sql
    	open ref1 for execute v_sql;
        return next ref1;
END;
$$ LANGUAGE plpgsql;