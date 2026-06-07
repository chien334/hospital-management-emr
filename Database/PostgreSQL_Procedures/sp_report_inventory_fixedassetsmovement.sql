/*
FileName: [SP_Report_Inventory_FixedAssetsMovement] '2020-01-20','2021-01-20',null,null,null
CreatedBy/date: Aniket/29-09-2021
Description: To get the Details of report Quotion rates
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1.    Aniket/29-09-2021                    created the script
2.	  Rohit/20Jan'22					   Added IsFixedAssets filter and also Item Specification
*/
CREATE OR REPLACE FUNCTION sp_report_inventory_fixedassetsmovement(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_employeeid INT DEFAULT NULL,
    p_departmentid INT DEFAULT NULL,
    p_itemid INT DEFAULT NULL,
    p_referencenumber VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "BarCodeNumber" VARCHAR,
    "MovementDate" TIMESTAMP,
    "ItemName" VARCHAR,
    "UOMName" VARCHAR,
    "Quantity" INT,
    "Amount" DECIMAL,
    "StoreName" VARCHAR,
    "AssetHolder" VARCHAR,
    "Specification" TIMESTAMP
) AS $$
BEGIN
    begin
        if ((p_fromdate is not null) and (p_todate is not null))
    then
            RETURN QUERY SELECT fs.barcodenumber,
                alh.startdate AS "MovementDate",
                i.itemname,
                uot.uomname AS "UOMName",
                count(*) AS "Quantity",
                (fs.itemrate * count(*)) AS "Amount",
                s.name AS "StoreName",
                coalesce(e.fullname,'N/A') AS "AssetHolder",
                gri.gritemspecification AS "Specification"
            from inv_assetlocationhistory alh
                join inv_txn_fixedassetstock fs on alh.fixedassetstockid = fs.fixedassetstockid
                join inv_txn_goodsreceiptitems gri on fs.goodsreceiptitemid = gri.goodsreceiptitemid
                join inv_mst_item i on fs.itemid = i.itemid
                left join emp_employee e on alh.oldassetholderid = e.employeeid
                join phrm_mst_store s on alh.oldstoreid = s.storeid
                join inv_mst_unitofmeasurement as  uot on i.unitofmeasurementid = uot.uomid
            where (((alh.startdate)::date between coalesce(p_fromdate,current_timestamp) and coalesce(p_todate,current_timestamp)) and i.isfixedassets  = 1
                or ((alh.enddate)::date between coalesce(p_fromdate,current_timestamp) and coalesce(p_todate,current_timestamp)))
                and ((fs.assetholderid = p_employeeid or p_employeeid is null) and (fs.substoreid = p_departmentid or p_departmentid is null) and (fs.itemid = p_itemid or p_itemid is null) and (fs.barcodenumber = p_referencenumber or p_referencenumber is null))
            group by fs.itemid, alh.fixedassetstockid, alh.oldassetholderid, alh.oldstoreid, alh.startdate, fs.itemrate, i.itemname, s.name, uot.uomname, i.code, e.fullname,fs.barcodenumber, gri.gritemspecification;
        end if;
    end;
END;
$$ LANGUAGE plpgsql;