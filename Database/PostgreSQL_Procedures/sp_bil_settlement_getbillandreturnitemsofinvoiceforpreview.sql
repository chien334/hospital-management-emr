CREATE OR REPLACE FUNCTION sp_bil_settlement_getbillandreturnitemsofinvoiceforpreview(
    p_billingtransactionid INT DEFAULT 0
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
    ref3 refcursor := 'cursor3';
    ref4 refcursor := 'cursor4';
BEGIN
    /*
    filename: "sp_bil_settlement_getbillandreturnitemsofinvoiceforpreview"
    createdby/date: sud/2021-11-18
    description: gets invoiceinfo, creditnote info, invoiceitems and creditnoteitems for preview in settlement page. 
    notes      : we're returning 4 tables with individual informations, these will be filtered in Client side as required.
    Change History
    S.No.    UpdatedBy/Date                        Remarks
    1.		Sud/2021-11-18   					  Initial Draft
    2.		Krishna/21stApril'23				  change itemid to integrationitemid
    */
    
    
    	open ref1 for select txn.invoiceno,txn.invoicecode, (txn.createdon)::date as "invoicedate",
    		 txn.subtotal, txn.discountamount, txn.totalamount
    		from bil_txn_billingtransaction txn
    	where txn.billingtransactionid = p_billingtransactionid;
        return next ref1;
    
    	open ref2 for select txnitm.itemid, txnitm.itemname, txnitm.quantity, txnitm.price,
    	   txnitm.subtotal,txnitm.discountamount,txnitm.totalamount
    		from bil_txn_billingtransactionitems txnitm 
    	where txnitm.billingtransactionid = p_billingtransactionid;
        return next ref2;
    
    	open ref3 for select billreturnid, creditnotenumber, (createdon)::date as "returndate" 
    	from  bil_txn_invoicereturn 
    	where billingtransactionid = p_billingtransactionid;
        return next ref3;
    
    	open ref4 for select billreturnid, integrationitemid, itemname, retquantity, price, retsubtotal, retdiscountamount, rettotalamount
    	from bil_txn_invoicereturnitems 
    	where billingtransactionid = p_billingtransactionid;
        return next ref4;
END;
$$ LANGUAGE plpgsql;