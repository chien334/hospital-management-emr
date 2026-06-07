CREATE OR REPLACE FUNCTION sp_dashboard_phrm_cardsummarycalculation(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
    ref3 refcursor := 'cursor3';
    ref4 refcursor := 'cursor4';
    v_fromdateminusoneday DATE := DateAdd(day, -1, p_fromdate);
    v_fromdateminustwodays DATE := DateAdd(day, -2, p_fromdate);
    v_noofdaysingivenrange INT := DATEDIFF(day, p_fromdate, p_todate) + 1;
    v_fiscalyearid INT := (Select FiscalYearId From PHRM_CFG_FiscalYears WHERE p_todate BETWEEN (StartDate)::date and (EndDate)::date);
    v_ficalyearstartdate DATE := (Select StartDate From PHRM_CFG_FiscalYears WHERE FiscalYearId = v_fiscalyearid);
BEGIN
    /*
     sp_dashboard_phrm_cardsummarycalculation '2022-10-3','2022-10-31'
    filename: "sp_dashboard_phrm_cardsummarycalculation"
    createdby/date: sanjit/rohit/2022-12-29
    description: .
    remarks:    a
    change history
    s.no.    updatedby/date                        remarks
    1      sanjit/rohit/2022-12-29                 created the script
    */
    
    
    
    
    
    
    
    
    open ref1 for select 'Total' as transactiontype, coalesce(sum(subtotal),0) as totalamount
    from fn_phrm_pharmacytxn_bybillingtype_usercollection(p_fromdate, p_todate, null)
    union all
    select 'Cash' as transactiontype, coalesce(sum(subtotal),0) as totalamount
    from fn_phrm_pharmacytxn_bybillingtype_usercollection(p_fromdate, p_todate, null)
    where transactiontype in ('CashInvoice','CashInvoiceReturn')
    union all
    select 'Credit' as transactiontype, coalesce(sum(subtotal),0) as totalamount
    from fn_phrm_pharmacytxn_bybillingtype_usercollection(p_fromdate, p_todate, null)
    where transactiontype in ('CreditInvoice','CreditInvoiceReturn')
    union all
    select 'PreviousDay' as transactiontype, coalesce(sum(subtotal),0) as totalamount
    from fn_phrm_pharmacytxn_bybillingtype_usercollection(v_fromdateminustwodays, v_fromdateminusoneday, null)
    union all
    select 'Average' as transactiontype, coalesce(sum(subtotal),0)/v_noofdaysingivenrange as totalamount
    from fn_phrm_pharmacytxn_bybillingtype_usercollection(p_fromdate, p_todate, null);
        return next ref1;
    
    
    open ref2 for select 'Total' as transactiontype, coalesce(sum(totalamount),0) as "totalamount"
    from phrm_goodsreceipt where coalesce(iscancel,0 )!=1 
    		and (goodreceiptdate)::date between p_fromdate and p_todate
    
    union all
    select 'Cash' as transactiontype, coalesce(sum(totalamount),0) as "totalamount"
    from phrm_goodsreceipt where coalesce(iscancel,0 )!=1 
    		and (goodreceiptdate)::date between p_fromdate and p_todate
    		and transactiontype ='cash'
    
    union all
    select 'Credit' as transactiontype, coalesce(sum(totalamount),0) as "totalamount"
    from phrm_goodsreceipt where coalesce(iscancel,0 )!=1 
    		and (goodreceiptdate)::date between p_fromdate and p_todate
    		and transactiontype ='credit'
    
    union all
    select 'PreviousDay' as transactiontype, coalesce(sum(totalamount),0) as "totalamount"
    from phrm_goodsreceipt where coalesce(iscancel,0 )!=1 
    		and (goodreceiptdate)::date between v_fromdateminustwodays and v_fromdateminusoneday
    union all
    select 'Average' as transactiontype, coalesce(sum(totalamount),0)/v_noofdaysingivenrange as "totalamount"
    from phrm_goodsreceipt where coalesce(iscancel,0 )!=1 
    		and (goodreceiptdate)::date between p_fromdate and p_todate;
        return next ref2;
    
    
    open ref3 for select 'TotalDispatched' as transactiontype, coalesce(sum(dispatchedquantity * costprice),0) as "totalamount", count(dispatchedquantity) as totalunit
    from phrm_storedispatchitems where dispatcheddate between p_fromdate and p_todate
    union all
    select 'PendingRequisition' as transactiontype, null as totalamount, count(*) as totalunit
    from phrm_storerequisition 
    where requisitionstatus in ('active', 'partial', 'pending') and requisitiondate between p_fromdate and p_todate 
    
    union all
    
    select 'NotReceivedRequisition' as transactiontype, null as totalamount, count(*)  as totalunit
    from phrm_storerequisition 
    where requisitiondate between p_fromdate and p_todate 
    and requisitionid in
    (
    	select requisitionid
    	from phrm_storedispatchitems
    	where receivedbyid is null
    	group by requisitionid
    )
    
    union all
    
    select 'PreviousDay' as transactiontype, coalesce(sum(dispatchedquantity * costprice),0)  as "totalamount", count(dispatchedquantity) as totalunit
    from phrm_storedispatchitems where dispatcheddate between v_fromdateminustwodays and v_fromdateminusoneday
    
    union all
    
    select 'Average' as transactiontype, coalesce(sum(dispatchedquantity * costprice),0)/v_noofdaysingivenrange  as "totalamount", count(dispatchedquantity) as totalunit
    from phrm_storedispatchitems where (dispatcheddate)::date between p_fromdate and p_todate;
        return next ref3;
    
    
    
    
    open ref4 for select 'Total' as transactiontype, coalesce(sum(closingvalue),0) as "totalamount", coalesce(sum(closingqty),0) as "totalunit"
    from fn_rpt_phrm_getclosingstockdetailsongivendate(v_fiscalyearid, v_ficalyearstartdate, p_todate)
    union all
    select 'Narcotic' as transactiontype, coalesce(sum(rptitm.closingvalue),0) as "totalamount", coalesce(sum(rptitm.closingqty),0) as "totalunit"
    from fn_rpt_phrm_getclosingstockdetailsongivendate(v_fiscalyearid, v_ficalyearstartdate, p_todate) rptitm
    inner join phrm_mst_item itm on rptitm.itemid=itm.itemid
    where coalesce(isnarcotic,0) =1
    union all
    select 'NearlyExpiry' as transactiontype, coalesce(sum(rptitm.closingvalue),0) as "totalamount", coalesce(sum(rptitm.closingqty),0) as "totalunit"
    from fn_rpt_phrm_getclosingstockdetailsongivendate(v_fiscalyearid, v_ficalyearstartdate, p_todate) rptitm
    inner join phrm_mst_stock stk on rptitm.stockid=stk.stockid
    where (stk.expirydate)::date between p_todate and dateadd(month,3,p_todate) 
    union all
    select 'Expiry' as transactiontype, coalesce(sum(rptitm.closingvalue),0) as "totalamount", coalesce(sum(rptitm.closingqty),0) as "totalunit"
    from fn_rpt_phrm_getclosingstockdetailsongivendate(v_fiscalyearid, v_ficalyearstartdate, p_todate) rptitm
    inner join phrm_mst_stock stk on rptitm.stockid=stk.stockid
    where (stk.expirydate)::date < p_fromdate;
        return next ref4;
END;
$$ LANGUAGE plpgsql;