CREATE OR REPLACE FUNCTION sp_report_pharmacy_supplierwisestock(
    p_fromdate TIMESTAMP,
    p_todate TIMESTAMP,
    p_itemid INT DEFAULT NULL,
    p_storeid INT DEFAULT NULL,
    p_supplierid INT DEFAULT NULL
)
RETURNS TABLE (
    "OpeningStock" VARCHAR,
    "SupplierName" VARCHAR,
    "ItemCode" VARCHAR,
    "GenericName" VARCHAR,
    "ItemName" VARCHAR,
    "StoreName" VARCHAR,
    "PurchaseQty" INT,
    "BatchNo" VARCHAR,
    "ExpiryDate" TIMESTAMP,
    "SalesQty" INT,
    "SalesRetQty" INT,
    "OtherQtyTxn" INT,
    "ClosingStock" VARCHAR
) AS $$
BEGIN
    begin
     RETURN QUERY SELECT
            coalesce(gr.openingqty,0) AS "OpeningStock", 
            s.suppliername AS "SupplierName",
            --c.categoryname as category,
            i.itemcode AS "ItemCode",
    		g.genericname AS "GenericName",
            i.itemname AS "ItemName",
            str.name AS "StoreName",
            coalesce(gr.purchaseqty,0) AS "PurchaseQty",
            gr.batchno AS "BatchNo",
            gr.expirydate AS "ExpiryDate",
            coalesce(gr.salesqty,0) AS "SalesQty",
            coalesce(gr.salesretqty,0) AS "SalesRetQty",
            case when gr.writeoffqty > 0 then (-gr.writeoffqty)::varchar || ' (write-off) ' else '' end +
            case when gr.purchasereturnqty > 0 then (-gr.purchasereturnqty)::varchar || ' (purchase-return) ' else '' end ||
            case when gr.stkmanageqty > 0 then (gr.stkmanageqty)::varchar || ' (stock-manage)' else '' end
            AS "OtherQtyTxn",
            coalesce(gr.openingqty,0) + coalesce(gr.purchaseqty,0) - coalesce(gr.salesqty,0) + coalesce(gr.salesretqty,0) - coalesce(gr.writeoffqty,0) - coalesce(gr.purchasereturnqty,0) || coalesce(gr.stkmanageqty,0) AS "ClosingStock"
        from
            phrm_mst_item i
            cross join phrm_mst_supplier s
            cross join phrm_mst_store str
            join phrm_mst_generic g on i.genericid = g.genericid
            inner join
             (
                select
                    x.storeid, x.itemid, x.batchno, x.expirydate, x.supplierid, sum(x.openingqty) as openingqty, sum(x.purchaseqty) AS "PurchaseQty", sum(x.salesqty) AS "SalesQty",sum(x.salesretqty) AS "SalesRetQty", sum(x.writeoffqty) as writeoffqty, sum(x.purchasereturnqty) as purchasereturnqty, sum(stkmanageqty) as stkmanageqty
                from
                (
                    --to calculate the opening quantity, we take the goods receipts upto the from date provided
                    select gr.storeid, gri.itemid, s.batchno, s.expirydate, gr.supplierid, sum(coalesce(st.inqty,0)) - sum(coalesce(st.outqty,0)) as openingqty, 0 AS "PurchaseQty", 0 AS "SalesQty", 0 AS "SalesRetQty",0 as writeoffqty, 0 as purchasereturnqty, 0 as stkmanageqty
                    from
                        phrm_goodsreceiptitems gri 
                        inner join phrm_goodsreceipt gr on gri.goodreceiptitemid = gr.goodreceiptid
                        inner join phrm_mst_stock s on gri.stockid = s.stockid
                        inner join phrm_txn_stocktransaction st on s.stockid = st.stockid
                    where (st.transactiondate)::date <= p_fromdate and
                    --used stocktxn date instead of grdate since calculation of opening depends on stktxn date. taking gr date may bring unwanted data in the output                
                        (gr.supplierid = p_supplierid or p_supplierid is null) and
                        (gri.itemid = p_itemid or p_itemid is null) and
                        (gr.storeid = p_storeid or p_storeid is null) and
    					coalesce(gri.iscancel,0) != 1 --exclude items from cancelled grs
                    group by gr.storeid, gri.itemid, s.batchno, s.expirydate, gr.supplierid
                    union all
                    --to calculate the purchased, consumed and closing quantity, we take the goods receipts from the provided date range
                    select
                        gr.storeid, gri.itemid, s.batchno, s.expirydate, gr.supplierid, 
                        0 as openingqty, 
                        sum( 
                            case 
                                when st.transactiontype in ('gr-item') then st.inqty 
                                when st.transactiontype = 'cancel-gr-items' then -st.outqty 
                                else 0
                            end
                           ) AS "PurchaseQty", 
                        sum( 
                                case
                                    when st.transactiontype in ('sale-item','provisional-sale-item') then st.outqty
                                    when st.transactiontype in ('provisiona-cancel-item','provisional-to-sale') then -st.inqty
                                    else 0
                                end
                            ) AS "SalesQty",   
                            sum( 
                                case
                                    when st.transactiontype in ('sale-returned-item','manual-sales-return') then st.inqty
                                    else 0
                                end
                            ) AS "SalesRetQty", 
                        sum(
                                case
                                    when st.transactiontype = 'write-off-item' then st.outqty
                                    else 0
                                end
                           ) as writeoffqty,
                             sum(
                                case
                                    when st.transactiontype = 'rts-item' then st.outqty
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
                        phrm_goodsreceiptitems gri 
                        inner join phrm_goodsreceipt gr on gri.goodreceiptid = gr.goodreceiptid
                        inner join phrm_mst_stock s on gri.stockid = s.stockid
                        inner join phrm_txn_stocktransaction st on s.stockid = st.stockid
                    where (st.transactiondate)::date between p_fromdate and p_todate and
                    --used stocktxn date instead of grdate since calculation of opening depends on stktxn date. taking gr date may bring unwanted data in the output            
                        (gr.supplierid = p_supplierid or p_supplierid is null) and
                        (gri.itemid = p_itemid or p_itemid is null) and
                        (gr.storeid = p_storeid or p_storeid is null) and
    				    coalesce(gri.iscancel,0) != 1 --exclude items from cancelled grs
                    group by gr.storeid, gri.itemid, s.batchno, s.expirydate, gr.supplierid
                ) x
                -- if a same item with same batch and expiry date was supplied from same vendor, then report will show them as a single row, hence the group by is used as below
                group by x.storeid, x.itemid, x.batchno, x.expirydate, x.supplierid
            )
            gr on i.itemid = gr.itemid and s.supplierid = gr.supplierid and str.storeid = gr.storeid
        where (coalesce(gr.openingqty,0) != 0 or coalesce(gr.purchaseqty,0) != 0 or coalesce(gr.salesqty,0) != 0 or coalesce(gr.salesretqty,0)!=0)
        order by coalesce(gr.purchaseqty,0) desc;
    end;
END;
$$ LANGUAGE plpgsql;