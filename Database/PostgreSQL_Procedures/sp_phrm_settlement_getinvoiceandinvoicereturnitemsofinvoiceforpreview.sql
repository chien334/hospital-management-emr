CREATE OR REPLACE FUNCTION sp_phrm_settlement_getinvoiceandinvoicereturnitemsofinvoiceforpreview(
    p_invoiceid INT DEFAULT 0
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
    ref3 refcursor := 'cursor3';
    ref4 refcursor := 'cursor4';
BEGIN
    /*
    filename: sp_phrm_settlement_getinvoiceandinvoicereturnitemsofinvoiceforpreview 2397
    description: to get all invoice and return invoice items details  of patient for settlement preview
    remarks: we're returning 4 tables from this StoredProc.
    1. INVOICE information
    2. Invoice Items Information
    3. CreditNote Information
    4. CreditNote Items Information
    
    Change History
    S.No. 	UpdatedBy/Date 				Remarks
    1. 		Rohit/1,DEC'21 				created sp to get the settlement details for settlement receipt.
    2.      rohit/13feb'23						mrp-> saleprice
    */
    
    	open ref1 for select inv.invoiceprintid as "invoiceno"
    		,(inv.createon)::date as "invoicedate"
    		,inv.subtotal
    		,inv.discountamount
    		,inv.totalamount
    	from phrm_txn_invoice inv
    	where inv.invoiceid = p_invoiceid;
        return next ref1;
    
    	open ref2 for select txnitm.itemid
    		,txnitm.itemname
    		,txnitm.quantity
    		,txnitm.saleprice
    		,txnitm.subtotal
    		,txnitm.totaldisamt as "discountamount"
    		,txnitm.totalamount
    	from phrm_txn_invoiceitems txnitm
    	where txnitm.invoiceid = p_invoiceid;
        return next ref2;
    
    	open ref3 for select invoicereturnid
    		,creditnoteid
    		,(createdon)::date as "returndate"
    	from phrm_txn_invoicereturn
    	where invoiceid = p_invoiceid;
        return next ref3;
    
    	open ref4 for select retitm.invoicereturnid
    		,mstitm.itemname
    		,retitm.returnedqty
    		,retitm.saleprice
    		,retitm.subtotal
    		,retitm.discountamount
    		,retitm.totalamount
    	from phrm_txn_invoicereturnitems retitm
    	inner join phrm_mst_item mstitm on retitm.itemid = mstitm.itemid
    	where retitm.invoiceid = p_invoiceid;
        return next ref4;
END;
$$ LANGUAGE plpgsql;