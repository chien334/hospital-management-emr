CREATE OR REPLACE FUNCTION sp_mkt_transaction_bill_details(
    p_billingtransactionid INT
)
RETURNS TABLE (
    "BillingTransactionId" INT,
    "ItemName" VARCHAR,
    "Quantity" INT,
    "RetQuantity" INT,
    "NetQuantity" INT,
    "TotalAmount" DECIMAL,
    "RetTotalAmount" DECIMAL,
    "NetTotalAmount" DECIMAL
) AS $$
BEGIN
    /* 
    exec "sp_mkt_transaction_bill_details" '2208'
    change history
    s.no.    updatedby/date                        remarks
    1        bibek/2023-08-08                   created initial script 
    */
    
    
        RETURN QUERY SELECT 
            itms.billingtransactionid,
            itms.itemname,
            itms.quantity,
            coalesce(retitms.retqty, 0) AS "RetQuantity",
            itms.quantity - coalesce(retitms.retqty, 0) AS "NetQuantity",
            itms.totalamount,
            coalesce(retitms.rettotalamount, 0) AS "RetTotalAmount",
            itms.totalamount - coalesce(retitms.rettotalamount, 0) AS "NetTotalAmount"
        from (
            select * 
            from bil_txn_billingtransactionitems
            where billingtransactionid = p_billingtransactionid
        ) itms
        left join (
            select 
                billingtransactionitemid,
                sum(coalesce(rettotalamount, 0)) AS "RetTotalAmount", 
                sum(coalesce(retquantity, 0)) as "retqty"
            from bil_txn_invoicereturnitems 
            group by billingtransactionitemid
        ) retitms on itms.billingtransactionitemid = retitms.billingtransactionitemid;
END;
$$ LANGUAGE plpgsql;