CREATE OR REPLACE FUNCTION sp_report_bill_invoice_return_detail(
    p_billreturnid INT
)
RETURNS TABLE (
    "ItemName" VARCHAR,
    "Quantity" INT,
    "RetQuantity" INT,
    "RetSubTotal" DECIMAL,
    "RetDiscountAmount" INT,
    "RetTotalAmount" DECIMAL
) AS $$
BEGIN
    /*
    filename: "sp_report_bill_invoice_return_detail"
    createdby/date: krishna/27-10-2021
    description: this sp will give details of returned items on the return bill report grid after view details is clicked and billreturnid is passed to this sp.
    remarks:   
    change history
    s.no.    updatedby/date                        remarks
    1       krishna/27-10-2021                created the script
    
    */
    
    
    
    	RETURN QUERY SELECT 
    		rtitm.itemname, 
    		txnitm.quantity,
    		rtitm.retquantity,
    		rtitm.retsubtotal,
    		rtitm.retdiscountamount,
    		rtitm.rettotalamount
    		from bil_txn_invoicereturnitems rtitm 
    		join bil_txn_billingtransactionitems txnitm on rtitm.billingtransactionitemid = txnitm.billingtransactionitemid 
    		where rtitm.billreturnid = p_billreturnid;
END;
$$ LANGUAGE plpgsql;