CREATE OR REPLACE FUNCTION sp_dashboard_phrm_mostsoldmedicine(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL
)
RETURNS TABLE (
    "ItemName" VARCHAR,
    "SoldQuantity" INT
) AS $$
BEGIN
    /*
     sp_dashboard_phrm_mostsoldmedicine '2022-10-3','2022-10-31'
    filename: "sp_dashboard_phrm_mostsoldmedicine"
    createdby/date: rohit/2022-12-30
    description: to get information of top 10 sold medicine.
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1       rohit/2022-12-30                 created the script
    */
    
    
    RETURN QUERY SELECT  itm.itemname, sum(invitm.soldquantity) AS "SoldQuantity"
    from phrm_mst_item itm
    inner join (
    		select itemid, sum(quantity) AS "SoldQuantity"
    		from phrm_txn_invoiceitems
    		where (createdon)::date between p_fromdate and p_todate
    		group by itemid
    	) invitm on itm.itemid = invitm.itemid
    group by itm.itemname
    order by soldquantity desc limit 10;
END;
$$ LANGUAGE plpgsql;