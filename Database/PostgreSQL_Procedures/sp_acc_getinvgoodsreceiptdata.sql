CREATE OR REPLACE FUNCTION sp_acc_getinvgoodsreceiptdata(

)
RETURNS TABLE (
    "TotalAmount" DECIMAL,
    "VAT" VARCHAR,
    "CreatedOn" TIMESTAMP,
    "Remarks" VARCHAR,
    "ReferenceIds" INT
) AS $$
BEGIN
    /*
    filename: "[sp_acc_getinvgoodsreceiptdata"]
    createdby/date: nageshbb/2018 july 03
    description:get all inventory goods receipt records group by date for transfer to accounting
    remarks:    
    change history
    s.no.    createdby/updatedby/date                        remarks
    1       nageshbb/2018 july 03							created the script
    */
    
    
    RETURN QUERY SELECT round(sum(gri.totalamount-gri.vatamount),2) AS "TotalAmount"
    ,sum(gri.vatamount)AS "VAT"
    ,(gri.createdon)::date AS "CreatedOn",
    'Inventory Goods Receipt entries to accounting on '||((gri.createdon)::date)::varchar AS "Remarks"
    ,(select string_agg((goodsreceiptid)::varchar, ',') from   inv_txn_goodsreceipt as g
           where ((gri.createdon)::date= (g.createdon)::date)) AS "ReferenceIds"
     from inv_txn_goodsreceipt gr
    join inv_txn_goodsreceiptitems gri
    on gr.goodsreceiptid=gri.goodsreceiptid
    where gr.istransferredtoacc !=1 or gr.istransferredtoacc is null
    group by (gri.createdon)::date;
END;
$$ LANGUAGE plpgsql;