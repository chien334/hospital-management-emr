CREATE OR REPLACE FUNCTION inv_rpt_expirablestockreport(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_itemid INT DEFAULT NULL,
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
    
    
     
    
       
    /*
    filename: inv_rpt_expirablestockreport '2022-03-29', '2022-03-29', 122, 5
    createdby/date: rohit/2022-06-06  
    description: sp to get the expirable stock  for inventory.
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1        rohit/2022-06-06                   created initial script
    */
        drop table if exists temp_temptxnstable;create temp table temp_temptxnstable as select txns.* , (0)::float as "balanceqty", (0)::decimal(16,4) as "balancerate" , (0)::decimal(16,4) as "balanceamount"
        
        from 
            (
    				select null as "transactiondate",null as "receiptqty", null as "receiptrate",null as "receiptamount",null as "issueqty", null as "issuerate", null as "issueamount", null as "referenceno", 'opening-item' as "remarks",  null as "username", openingqty as "openingqty",receiptrate as "openingrate",openingvalue as "openingvalue",expirydate
    				from	fn_rpt_inv_getitemsopeningqtyuptodateforexpirablestock(p_fiscalyearid, v_fystartdate, v_todateforopening,v_dispatchorconsumption)
    				where itemid=p_itemid
    
    			union all
    
                select   stkt.transactiondate, coalesce(stkt.inqty,0) as "receiptqty", coalesce(stkt.costprice,0) as "receiptrate", 
    			     round(coalesce(stkt.inqty,0) * coalesce(stkt.costprice,0),4) as "receiptamount",
                        null as "issueqty", null as "issuerate", null as "issueamount", 
                        gr.goodsreceiptno as "referenceno", gri.gritemspecification as "remarks", e.fullname as "username", 
    					null as "openingqty",null as "openingrate",null as "openingvalue",stkt.expirydate
                from    inv_txn_stocktransaction stkt inner join
                        emp_employee e on stkt.createdby = e.employeeid inner join 
                        inv_txn_goodsreceiptitems gri on stkt.referenceno = gri.goodsreceiptitemid inner join
                        inv_txn_goodsreceipt gr on gri.goodsreceiptid = gr.goodsreceiptid inner join
    					phrm_mst_store s on gr.storeid = s.storeid
                where  stkt.transactiontype ='goodreceipt-items'
    			        and   stkt.itemid = p_itemid 
    				    and (stkt.transactiondate)::date between p_fromdate and  p_todate
    
                union all
    
    			  select   stkt.transactiondate, coalesce(stkt.inqty,0) as "receiptqty", coalesce(stkt.costprice,0) as "receiptrate", 
    			     round(coalesce(stkt.inqty,0) * coalesce(stkt.costprice,0),4) as "receiptamount",
                        null as "issueqty", null as "issuerate", null as "issueamount", 
                        gr.goodsreceiptno as "referenceno", gri.gritemspecification as "remarks", e.fullname as "username", 
    					null as "openingqty",null as "openingrate",null as "openingvalue",stkt.expirydate
                from    inv_txn_stocktransaction stkt inner join
                        emp_employee e on stkt.createdby = e.employeeid inner join 
                        inv_txn_goodsreceiptitems gri on stkt.referenceno = gri.goodsreceiptitemid inner join
                        inv_txn_goodsreceipt gr on gri.goodsreceiptid = gr.goodsreceiptid inner join
    					phrm_mst_store s on gr.storeid = s.storeid
                where  stkt.transactiontype ='cancel-gr-items'
    			        and   stkt.itemid = p_itemid 
    				    and (stkt.transactiondate)::date between p_fromdate and  p_todate
    
                union all
                select  stkt.transactiondate, null as "receiptqty",null as "receiptrate",null as "receiptamount",
                        coalesce(stkt.outqty,0)  as "issueqty",coalesce(stkt.costprice,0) as "issuerate",round(coalesce(stkt.outqty,0) * coalesce(stkt.costprice,0),4) as "issueamount", 
                        d.dispatchid as "referenceno", d.remarks as "remarks", coalesce(e.fullname, 'Not Received') as "username", null as "openingqty",null as "openingrate",null as "openingvalue",stkt.expirydate
                from    inv_txn_stocktransaction stkt left join 
                        inv_txn_dispatchitems d on stkt.referenceno = d.dispatchitemsid left join
                        phrm_mst_store s on d.targetstoreid = s.storeid left join
                        emp_employee e on d.receivedbyid = e.employeeid
                where  stkt.transactiontype in ('dispatched-item-from') and
                        stkt.itemid =  p_itemid and
                        (stkt.transactiondate)::date  between p_fromdate and p_todate
    
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
            username,
            remarks,
            openingqty,
            openingrate,
            openingvalue,
            expirydate
        from temp_temptxnstable;
        return next ref1;
    
    --table 2 : for fetching item details like name,uom and subcategory and jinsikhatano-----------------------------------------------------------------------------------
    open ref2 for select  * from (
    select  mstitm.itemname
    	,uom.uomname
    	,gri.gritemspecification
    	,gri.itemcategory
    	,fy.fiscalyearname
    	,subcat.subcategoryname
    	,mstitm.registerpagenumber
    	,mstitm.itemid
    	,fy.fiscalyearid
    	,mstitm.code
    from inv_mst_item mstitm
    left join inv_txn_goodsreceiptitems gri on mstitm.itemid = gri.itemid
    inner join inv_txn_goodsreceipt gr on gri.goodsreceiptid=gr.goodsreceiptid
    inner join inv_cfg_fiscalyears fy on gr.fiscalyearid = fy.fiscalyearid
    left join inv_mst_unitofmeasurement uom on mstitm.unitofmeasurementid = uom.uomid
    left join inv_mst_itemsubcategory subcat on mstitm.subcategoryid = subcat.subcategoryid
    
    union
    
    select  mstitm.itemname
    	,uom.uomname
    	,null as "gritemspecification"
    	,cat.itemcategoryname
    	,fy.fiscalyearname
    	,subcat.subcategoryname
    	,mstitm.registerpagenumber
    	,mstitm.itemid
    	,fy.fiscalyearid
    	,mstitm.code
    from inv_mst_item mstitm
    inner join inv_fiscalyearstock fys on mstitm.itemid = fys.itemid
    inner join inv_cfg_fiscalyears fy on fys.fiscalyearid = fy.fiscalyearid
    left join inv_mst_unitofmeasurement uom on mstitm.unitofmeasurementid = uom.uomid
    left join inv_mst_itemsubcategory subcat on mstitm.subcategoryid = subcat.subcategoryid
    left join inv_mst_itemcategory cat on mstitm.itemcategoryid=cat.itemcategoryid
    )tbl
    where itemid = p_itemid
    	and fiscalyearid = p_fiscalyearid limit 1;
        return next ref2;
END;
$$ LANGUAGE plpgsql;