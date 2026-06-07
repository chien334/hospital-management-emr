CREATE OR REPLACE FUNCTION phrm_rpt_purchasesummary(
    p_fromdate TIMESTAMP DEFAULT '2021-01-01',
    p_todate TIMESTAMP DEFAULT '2022-01-01',
    p_storeid INT DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
BEGIN
    -- =============================================
    -- author:		sanjit
    -- create date: 18/06/2021
    -- description: generated purchase summary report
    -- example to execute the stored procedure we just created
    -- execute phrm_rpt_purchasesummary '2021-07-16','2022-07-15'
    -- =============================================
    /* change history
    s.no.    updatedby/date                        remarks
    1.		sanjit/sud - 2022-06-15		source table changed from stock transaction to gritem and rtsitem table
    */
    
        -- body of the stored procedure
        open ref1 for select coalesce(purchase.purchase,0) as "purchase", coalesce(purchasereturn.purchasereturn,0) as "purchasereturn", coalesce(purchase.purchase,0) - coalesce(purchasereturn.purchasereturn,0) as "balance"
        from (
    		
    		select sum(gri.totalamount) as purchase
    		from phrm_goodsreceiptitems gri
    			inner join phrm_goodsreceipt gr on gri.goodreceiptid = gr.goodreceiptid
    		where coalesce(gri.iscancel, 0) != 1 and 
    		(gr.goodreceiptdate)::date between (p_fromdate)::date and (p_todate)::date
        ) purchase,
        (
    		select sum(rtsi.totalamount) as purchasereturn
    		from phrm_returntosupplieritems rtsi
    			inner join phrm_returntosupplier rts on rtsi.returntosupplierid = rts.returntosupplierid
    		where (rts.returndate)::date between (p_fromdate)::date and (p_todate)::date
        ) purchasereturn;
        return next ref1;
END;
$$ LANGUAGE plpgsql;