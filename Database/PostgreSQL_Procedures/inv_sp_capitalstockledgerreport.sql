CREATE OR REPLACE FUNCTION inv_sp_capitalstockledgerreport(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_itemid INT DEFAULT NULL,
    p_storeid INT DEFAULT NULL,
    p_fiscalyearid INT DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
    v_fystartdate TIMESTAMP := (select  (StartDate)::Date from INV_CFG_FiscalYears where FiscalYearId=p_fiscalyearid LIMIT 1);
    v_dispatchorconsumption VARCHAR := (Select  ParameterValue from CORE_CFG_Parameters Where ParameterGroupName='Inventory' and ParameterName='ConsumptionOrDispatchForReports' LIMIT 1);
    v_todateforopening DATE := DATEADD(DAY, -1, p_fromdate);
    v_balanceqty FLOAT := 0;
    v_balanceamount DECIMAL(20,4) := 0;
BEGIN
    
     
       --todateforopening = fromdate-1
    /*
    filename: inv_sp_capitalstockledgerreport '2021-01-30', '2022-03-30',1916,7,5
    createdby/date: rohit/2022-03-29
    description: sp to get the capital stock ledger for inventory.
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1        rohit/2022-03-30                   created initial script
    2.		 rohit/2022-07-12					roundoff is done in openingqty, receiptqty and dispatchqty
    											fix: referenceno is taken as goodreceiptno, dispatchno
    */
        drop table if exists temp_temptxnstable;create temp table temp_temptxnstable as select txns.* , (0)::float as "balanceqty", (0)::decimal(16,4) as "balancerate" , (0)::decimal(16,4) as "balanceamount"
        
        from 
            (
    				select null as "transactiondate",null as "receiptqty", null as "receiptrate",null as "receiptamount",null as "issueqty", null as "issuerate", null as "issueamount", null as "referenceno", 'opening-item' as "remarks",storename as store, null as "username", round(openingqty,4) as "openingqty",coalesce(receiptrate,0) as "openingrate",openingvalue as "openingvalue",null as "specification",null as "vendorname",null as "code"
    				from	fn_inv_opening_stock_details(p_fiscalyearid, v_fystartdate, v_todateforopening, v_dispatchorconsumption)
    				where itemid=p_itemid
    
    			union all
    
                select   stkt.transactiondate, round(coalesce(stkt.inqty,0),4) as "receiptqty", coalesce(stkt.costprice,0) as "receiptrate", round(coalesce(stkt.inqty,0) * coalesce(stkt.costprice,0),4) as "receiptamount",
                        null as "issueqty", null as "issuerate", null as "issueamount", 
                        gr.goodsreceiptno as "referenceno", gri.gritemspecification as "remarks",s.name as store, e.fullname as "username", null as "openingqty",null as "openingrate",null as "openingvalue",gri.gritemspecification as "specification",v.vendorname as "vendorname",i.code as "code"
                from    inv_txn_stocktransaction stkt join
                        emp_employee e on stkt.createdby = e.employeeid left join 
                        inv_txn_goodsreceiptitems gri on stkt.referenceno = gri.goodsreceiptitemid left join
                        inv_txn_goodsreceipt gr on gri.goodsreceiptid = gr.goodsreceiptid join
    					inv_mst_vendor v on gr.vendorid=v.vendorid join
    					phrm_mst_store s on gr.storeid = s.storeid join
    					inv_mst_item i on stkt.itemid=i.itemid
                where  stkt.transactiontype in ('opening-item', 'goodreceipt-items','cancelled-donated-item') and
                        stkt.itemid = p_itemid and
                        (stkt.transactiondate)::date between p_fromdate and  p_todate
    					and stkt.storeid = p_storeid
    
                union all
    
                select  stkt.transactiondate, null as "receiptqty",null as "receiptrate",null as "receiptamount",
                        round(coalesce(stkt.outqty,0),4)  as "issueqty",coalesce(stkt.costprice,0) as "issuerate",round(coalesce(stkt.outqty,0) * coalesce(stkt.costprice,0),4) as "issueamount", 
                        d.dispatchno as "referenceno", d.remarks as "remarks",s.name as store, coalesce(e.fullname, 'Not Received') as "username", null as "openingqty",null as "openingrate",null as "openingvalue",d.specification as "specification", null as "vendorname",i.code as "code"
                from    inv_txn_stocktransaction stkt left join 
                        inv_txn_dispatchitems d on stkt.referenceno = d.dispatchitemsid left join
                        phrm_mst_store s on d.targetstoreid = s.storeid left join
                        emp_employee e on d.receivedbyid = e.employeeid join
    					inv_mst_item i on stkt.itemid=i.itemid
                where  stkt.transactiontype in ('dispatched-item-from', 'dispatched-item-to') and
                        stkt.itemid =  p_itemid and
                        (stkt.transactiondate)::date  between p_fromdate and p_todate
    					and stkt.storeid = p_storeid
    
            ) txns
      order by txns.transactiondate;
    
    
        
        
        open ref1 for select
            transactiondate,
            receiptqty,
            receiptrate,
            receiptamount,
            issueqty,
            issuerate,
            issueamount,
            sum(coalesce(coalesce(receiptqty, -issueqty), openingqty)) over (order by transactiondate, (case when openingqty is not null then 0 else 1 end)) as balanceqty,
            coalesce(coalesce(receiptrate, issuerate), openingrate) as balancerate,
            sum(coalesce(coalesce(receiptqty, -issueqty), openingqty) * coalesce(coalesce(receiptrate, issuerate), openingrate)) over (order by transactiondate, (case when openingqty is not null then 0 else 1 end)) as balanceamount,
            referenceno,
            store,
            username,
            remarks,
            openingqty,
            openingrate,
            openingvalue,
            specification,
            vendorname,
            code
        from temp_temptxnstable;
        return next ref1;
    
    --table 2 : for fetching item details like name,uom and subcategory and jinsikhatano-----------------------------------------------------------------------------------
    
    	open ref2 for select mstitm.itemname
    	,uom.uomname
    	,fy.fiscalyearname
    	,subcat.subcategoryname
    	,mstitm.registerpagenumber
    from inv_mst_item mstitm
    left join inv_txn_goodsreceiptitems gri on mstitm.itemid = gri.itemid
    join inv_txn_goodsreceipt gr on gri.goodsreceiptid=gr.goodsreceiptid
    join inv_mst_unitofmeasurement uom on mstitm.unitofmeasurementid = uom.uomid
    join inv_cfg_fiscalyears fy on gr.fiscalyearid = fy.fiscalyearid
    join inv_mst_itemsubcategory subcat on mstitm.subcategoryid = subcat.subcategoryid
    where mstitm.itemid = p_itemid
    	and fy.fiscalyearid = p_fiscalyearid;
        return next ref2;
END;
$$ LANGUAGE plpgsql;