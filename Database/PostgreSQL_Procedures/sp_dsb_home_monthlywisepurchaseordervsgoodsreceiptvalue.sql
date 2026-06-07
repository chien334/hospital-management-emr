CREATE OR REPLACE FUNCTION sp_dsb_home_monthlywisepurchaseordervsgoodsreceiptvalue(
    p_sourcestoreid INT DEFAULT NULL
)
RETURNS TABLE (
    "TxnDisplayDate" TIMESTAMP,
    "PurchaseValue" DECIMAL,
    "GoodsArrivalValue" DECIMAL,
    "GoodsReceiptValue" DECIMAL
) AS $$
DECLARE
    v_datetimenow DATE := CURRENT_TIMESTAMP;
    v_datetimeoneyearbefore DATE := DATEADD(YEAR, -1, v_datetimenow);
BEGIN
    /*
    filename: "sp_dsb_home_monthlywisepurchaseordervsgoodsreceiptvalue"
    createdby/date: rajib/2022-sept-13
    description: to get dashboard statistics of the home dashboards. these are used to fill labels.
    remarks:  
    note:  
    change history
    s.no.    updatedby/date                        remarks
    1       rajib/2022-sept-16               created
    
    */
    begin
    if ((p_sourcestoreid is not null) )
    
    
    
    then RETURN QUERY SELECT 
    	--purchase.txndate, 
    	purchase.txndisplaydate, 
    	purchasevalue,
    	goodsarrivalvalue,
    	goodsreceiptvalue
    from
    (
    	select 
    		((extract(year from podate))::varchar || '-' || (extract(month from podate))::varchar || '-01')::timestamp as txndate, 
    		to_char(podate, 'YYYY') || '-' || substring( trim(to_char(podate, 'Month')), 1, 3) AS "TxnDisplayDate", 
    		sum(totalamount) AS "PurchaseValue"
    	from 
    		inv_txn_purchaseorder
    	where 
    		coalesce(postatus,'cancelled') in ('active', 'complete')  and
    		storeid = p_sourcestoreid
    		and (podate)::timestamp >= v_datetimeoneyearbefore
    	group by 
    		((extract(year from podate))::varchar || '-' || (extract(month from podate))::varchar || '-01')::timestamp, 
    		to_char(podate, 'YYYY') || '-' || substring( trim(to_char(podate, 'Month')), 1, 3)
    ) purchase
     left join 
    (
    	select 
    		((extract(year from goodsarrivaldate))::varchar || '-' || (extract(month from goodsarrivaldate))::varchar || '-01')::timestamp as "txndate",
    		to_char(goodsarrivaldate, 'YYYY') || '-' || substring( trim(to_char(goodsarrivaldate, 'Month')), 1, 3) AS "TxnDisplayDate", 
    		sum(totalamount) AS "GoodsArrivalValue"
    	from 
    		inv_txn_goodsreceipt
    	where 
    		grstatus != 'cancelled' and
    		storeid = p_sourcestoreid and
    		(goodsarrivaldate)::timestamp >= v_datetimeoneyearbefore
    	group by 
    		((extract(year from goodsarrivaldate))::varchar || '-' || (extract(month from goodsarrivaldate))::varchar || '-01')::timestamp, 
    		to_char(goodsarrivaldate, 'YYYY') || '-' || substring( trim(to_char(goodsarrivaldate, 'Month')), 1, 3)
    )goodarrival
    on  purchase.txndate = goodarrival.txndate and purchase.txndisplaydate = goodarrival.txndisplaydate
    left join
    (
    	select 
    		((extract(year from goodsreceiptdate))::varchar || '-' || (extract(month from goodsreceiptdate))::varchar || '-01')::timestamp as "txndate",
    		to_char(goodsreceiptdate, 'YYYY') || '-' || substring( trim(to_char(goodsreceiptdate, 'Month')), 1, 3) AS "TxnDisplayDate", 
    		sum(totalamount) AS "GoodsReceiptValue"
    	from 
    		inv_txn_goodsreceipt
    	where 
    		receivedby is not null and
    		grstatus != 'cancelled' and
    		storeid = p_sourcestoreid and
    		(goodsreceiptdate)::timestamp >= v_datetimeoneyearbefore
    	group by 
    		((extract(year from goodsreceiptdate))::varchar || '-' || (extract(month from goodsreceiptdate))::varchar || '-01')::timestamp, 
    		to_char(goodsreceiptdate, 'YYYY') || '-' || substring( trim(to_char(goodsreceiptdate, 'Month')), 1, 3)
    ) goodreceipt 
    on  purchase.txndate = goodreceipt.txndate and purchase.txndisplaydate = goodreceipt.txndisplaydate
    order by purchase.txndate; end if; 
    
    
    end;
END;
$$ LANGUAGE plpgsql;