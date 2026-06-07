CREATE OR REPLACE FUNCTION sp_opening_stock_valuation_report(
    p_tilldate DATE DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
BEGIN
    -- ===========================================================================
    -- author:		rohit
    -- create date: 10apr'22
    -- Description: generated inventory opening stock valuation report
    -- Example : EXECUTE SP_Opening_Stock_Valuation_Report '2022-04-10'
    -- ===========================================================================
    /* Change History
    S.No.    UpdatedBy/Date                        Remarks
    1.		Rohit/10Apr'22	                created initial script
    */
    
        open ref1 for select store.storeid,store.name as storename, coalesce(stxn.purchasevalue,0) as "purchasevalue"
        from phrm_mst_store store
        left join 
        (
            select str.storeid, 
            (sum(coalesce(stxn.inqty,0) * coalesce(stxn.costprice,0)) - sum(coalesce(stxn.outqty,0) * coalesce(stxn.costprice,0)))::money as "purchasevalue"
            from inv_txn_stocktransaction stxn
                join phrm_mst_store str on stxn.storeid = str.storeid
                join inv_mst_item itm on itm.itemid = stxn.itemid
            where coalesce(stxn.isactive,0) = 1 and (stxn.transactiondate)::date < p_tilldate
            group by str.storeid
        ) stxn
        on store.storeid = stxn.storeid
        where store.category in ('substore') or store.subcategory ='inventory'
    	union
    	select 0 as "storeid",'Total' as storename, stxn.purchasevalue
        from 
        (
            select 
            (sum(coalesce(stxn.inqty,0) * coalesce(stxn.costprice,0)) - sum(coalesce(stxn.outqty,0) * coalesce(stxn.costprice,0)))::money as "purchasevalue"
            from inv_txn_stocktransaction stxn
            where coalesce(stxn.isactive,0) = 1 and (stxn.transactiondate)::date < p_tilldate
        ) stxn;
        return next ref1;
END;
$$ LANGUAGE plpgsql;