/*
CreatedDate:---
FileName: [SP_Report_Inventory_InventoryValuation] 
Description: To get the Details of report Inventory Valuation
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1.                                         created the script
2.	  Rohit/20Jan'22					   Added ItemCategory,Specification,BarCodes
*/
CREATE OR REPLACE FUNCTION sp_report_inventory_inventoryvaluation(

)
RETURNS TABLE (
    "ItemName" VARCHAR,
    "UOMName" VARCHAR,
    "Code" VARCHAR,
    "Rate" DECIMAL,
    "Quantity" INT,
    "Amount" DECIMAL,
    "ItemCategory" VARCHAR,
    "Specification" TIMESTAMP,
    "BarCodes" VARCHAR
) AS $$
BEGIN
    
        /* 
    here we take item rate from inv_txn_goodsreceiptitems and its  available quantity from inv_txn_stock 
    and then calculate amount for the item.
    */
        RETURN QUERY SELECT
            a.itemname,
            a.uomname,
            a.code,
            round((sum(a.amt)/sum(a.qty)),2) AS "Rate",
            sum(a.qty) AS "Quantity",
            sum(a.amt) AS "Amount",
            a.itemcategory,
            a.gritemspecification AS "Specification",
           string_agg(a.barcodenumber,', ')  AS "BarCodes"
        from
            (
    	select
                itm.itemname,
                gritm.itemrate, stk.availablequantity as "qty",
                gritm.itemrate * stk.availablequantity as "amt",
                unit.uomname,
                itm.code,
                gritm.gritemspecification,
                gritm.itemcategory,
                fas.barcodenumber
            from inv_txn_stock stk
                join inv_txn_goodsreceiptitems gritm on stk.goodsreceiptitemid = gritm.goodsreceiptitemid
                join inv_mst_item itm on stk.itemid = itm.itemid
                join inv_txn_fixedassetstock fas on stk.itemid =fas.itemid
                left join inv_mst_unitofmeasurement unit on itm.unitofmeasurementid = unit.uomid
            where stk.availablequantity > 0
    ) a
        group by a.itemname,a.uomname,a.code,a.itemcategory,a.gritemspecification;
END;
$$ LANGUAGE plpgsql;