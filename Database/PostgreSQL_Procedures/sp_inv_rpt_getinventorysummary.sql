CREATE OR REPLACE FUNCTION sp_inv_rpt_getinventorysummary(
    p_fiscalyearid INT,
    p_fromdate DATE,
    p_todate DATE,
    p_storeid INT DEFAULT NULL
)
RETURNS TABLE (
    "StoreId" INT,
    "StoreName" VARCHAR,
    "ItemId" INT,
    "ItemCode" VARCHAR,
    "ItemName" VARCHAR,
    "ItemType" VARCHAR,
    "SubCategory" VARCHAR,
    "Unit" VARCHAR,
    "ItemType_1" VARCHAR,
    "OpeningQty" INT,
    "OpeningValue" DECIMAL,
    "PurchaseQty" INT,
    "PurchaseValue" DECIMAL,
    "TransInQty" INT,
    "TransInValue" DECIMAL,
    "TransOutQty" INT,
    "TransOutValue" DECIMAL,
    "ConsumptionQty" TIMESTAMP,
    "ConsumptionValue" TIMESTAMP,
    "StockManageInQty" INT,
    "StockManageInValue" DECIMAL,
    "StockManageOutQty" INT,
    "StockManageOutValue" DECIMAL,
    "ClosingQty" INT,
    "ClosingValue" DECIMAL
) AS $$
DECLARE
    v_fystartdate TIMESTAMP := (select  (StartDate)::Date from INV_CFG_FiscalYears where FiscalYearId=p_fiscalyearid LIMIT 1);
    v_todateforopening DATE := DATEADD(DAY, -1, p_fromdate);
BEGIN
    /************************************************************************
    filename: "sp_inv_rpt_getinventorysummary"
    description: get inventory summary report data for storeid, itemid 
    returns: 
            storeid, storename, itemid, itemcode, itemname, itemtype
    		,subcategory, unit, itemtype
    		,openingqty, openingvalue, purchaseqty, purchasevalue
    		,transinqty, transinvalue, transoutqty, transoutvalue
    		,consumptionqty,consumptionvalue, stockmanageinqty,stockmanageinvalue
    		,stockmanageoutqty,stockmanageoutvalue, closingqty,closingvalue
      
    usage : exec sp_inv_rpt_getinventorysummary 6,'2023-03-01','2023-03-27',null
    change history
    s.no.    updatedby/date                        remarks
    3.	 rohit/7jun'22								ItemType Filter removed
    4.   Sud/9Jun'22                                added new fields for closingqty, closingvalue with calculation
    5.   rohit/25jul'22								ItemType is fetched
    6.   Sud/27Mar'23                               added filter for storeid, 
                                                    replaced dispatch by transin/transout 
    *************************************************************************/
    
      
     
    
       --todateforopening = fromdate-1
    
     RETURN QUERY SELECT itmsinfo.storeid, itmsinfo.storename, itmsinfo.itemid, itmsinfo.itemcode, itmsinfo.itemname, itmsinfo.itemtype, itmsinfo.subcategory, itmsinfo.unit, itmsinfo.itemtype AS "ItemType_1", coalesce(opening.openingqty,0)  AS "OpeningQty", coalesce(opening.openingvalue,0) AS "OpeningValue", coalesce(txnsbetnrange.purchaseqty,0) AS "PurchaseQty", coalesce(txnsbetnrange.purchasevalue,0) AS "PurchaseValue", coalesce(txnsbetnrange.transinqty,0) AS "TransInQty", coalesce(txnsbetnrange.transinvalue,0) AS "TransInValue", coalesce(txnsbetnrange.transoutqty,0) AS "TransOutQty", coalesce(txnsbetnrange.transoutvalue,0) AS "TransOutValue", coalesce(txnsbetnrange.consumptionqty,0) AS "ConsumptionQty", coalesce(txnsbetnrange.consumptionvalue,0) AS "ConsumptionValue", coalesce(txnsbetnrange.stockmanageinqty,0) AS "StockManageInQty", coalesce(txnsbetnrange.stockmanageinvalue,0) AS "StockManageInValue", coalesce(txnsbetnrange.stockmanageoutqty,0) AS "StockManageOutQty", coalesce(txnsbetnrange.stockmanageoutvalue,0) AS "StockManageOutValue", coalesce(opening.openingqty,0) 
    			 + coalesce(txnsbetnrange.purchaseqty,0)  
    			 + coalesce(txnsbetnrange.transinqty,0)  
    			 - coalesce(txnsbetnrange.transoutqty,0) 
    			 - coalesce(txnsbetnrange.consumptionqty,0)
    			 || coalesce(txnsbetnrange.stockmanageinqty,0)
    			 - coalesce(txnsbetnrange.stockmanageoutqty,0)
    			  AS "ClosingQty", coalesce(opening.openingvalue,0) 
    			 + coalesce(txnsbetnrange.purchasevalue,0)  
    			 + coalesce(txnsbetnrange.transinvalue,0)  
    			 - coalesce(txnsbetnrange.transoutvalue,0) 
    			 - coalesce(txnsbetnrange.consumptionvalue,0)
    			 || coalesce(txnsbetnrange.stockmanageinvalue,0)
    			 - coalesce(txnsbetnrange.stockmanageoutvalue,0)
    			  AS "ClosingValue" from  
     (
      --table:1--leftmost table to get the store and item master details---
      select distinct stor.storeid, stor.name AS "StoreName",
            itm.itemid, itm.code AS "ItemCode", itm.itemname, itm.itemtype,  sub.subcategoryname AS "SubCategory", uom.uomname AS "Unit"
       from inv_txn_storestock storstk
    	inner join inv_mst_item itm on storstk.itemid=itm.itemid
    	inner join inv_mst_unitofmeasurement uom on itm.unitofmeasurementid=uom.uomid
    	inner join phrm_mst_store stor on storstk.storeid = stor.storeid
    	inner join inv_mst_itemsubcategory sub on itm.subcategoryid=sub.subcategoryid
     ) itmsinfo
    
    left join
    (
      --this function does opening+sum(in)-sum(out) and gives opening on the fromdate
        select * from "fn_rpt_inv_getitemsopeningqtyuptodate"(p_fiscalyearid, v_fystartdate, v_todateforopening)
    ) opening
    on itmsinfo.itemid = opening.itemid  and  itmsinfo.storeid=opening.storeid
    
    left join
    (
      --get transactions from: p_fromdate to p_todate---
      select * from "fn_rpt_inv_getitemstocktxnsbetndaterange"(p_fromdate, p_todate)
    )
    txnsbetnrange
     on itmsinfo.itemid = txnsbetnrange.itemid and itmsinfo.storeid=txnsbetnrange.storeid
    
    where p_storeid is null or itmsinfo.storeid = p_storeid
    
    order by itmsinfo.storename, itmsinfo.subcategory, itmsinfo.itemname;
END;
$$ LANGUAGE plpgsql;