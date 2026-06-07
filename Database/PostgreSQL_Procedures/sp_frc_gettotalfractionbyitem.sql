CREATE OR REPLACE FUNCTION sp_frc_gettotalfractionbyitem(

)
RETURNS TABLE (
    "ItemId" INT,
    "ItemName" VARCHAR,
    "ServiceDepartmentName" VARCHAR,
    "Price" DECIMAL,
    "FractionAmount" TIMESTAMP
) AS $$
BEGIN
    
     RETURN QUERY SELECT itm.itemid,itm.itemname, billingitems.servicedepartmentname, itm.price, sum(frac.finalamount) AS "FractionAmount" from frc_fractioncalculation frac
    join bil_txn_billingtransactionitems billingitems on frac.billtxnitemid= billingitems.billingtransactionitemid
    join bil_cfg_billitemprice itm on billingitems.itemid= itm.itemid 
    where billingitems.servicedepartmentid=itm.servicedepartmentid and itm.isfractionapplicable= 1 
    group by itm.itemid, itm.itemname, billingitems.servicedepartmentname, itm.price
    order by itm.itemid;
END;
$$ LANGUAGE plpgsql;