CREATE OR REPLACE FUNCTION sp_wardinv_report_consumptionreport(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_storeid INT DEFAULT NULL
)
RETURNS TABLE (
    "Date" TIMESTAMP,
    "ItemName" VARCHAR,
    "Quantity" INT,
    "UOMName" VARCHAR,
    "User" VARCHAR,
    "Remark" VARCHAR,
    "CostPrice" DECIMAL,
    "TotalConsumedValue" TIMESTAMP,
    "ConsumptionReceiptId" INT,
    "SubCategoryId" INT,
    "SubCategoryName" VARCHAR
) AS $$
BEGIN
    /*
    filename: "sp_wardinv_report_consumptionreport" '2022-04-02','2022-04-02','41'
    createdby/date: rusha/06-25-2019
    description: to get the consumption details of inventory items consume by ward
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1.		rusha/07-12-2019					only show consumable items
    2.		rohit/2feb'22						Fetched UnitOfMeasurement,ItemRate,TotalConsumedValue and also order by CreatedOn in descending order.
    3.		Rohit/3Apr'22						fetched remarks(& patientcode,patientname for patient consumption) and also consumptionreceiptid (for      patient consumption)
    4.		rohit/13apr'22						Remove Department Column
    5.		Rohit/22Apr'22					    join ward_inv_consumption and inv_mst_stock with stockid to get the exact cost price of consumptionitem.
    6.		rohit/31oct'22					    CreatedOn-> ConsumptionDate
    7.      Nirmala/8Nov'22                     remove current date filter
    8.      nirmala/23jan'23                    Fetch SubcategoryId and SubCategoryName
    */
    BEGIN
    	IF (
    			(p_fromdate IS NOT NULL)
    			AND (p_todate IS NOT NULL)
    			)
    	THEN
    		RETURN QUERY SELECT (con.ConsumptionDate)::DATE AS "Date"
    			,con.ItemName
    			,con.Quantity
    			,uom.UOMName
    			,UsedBy AS "User"
    			,(con.Remark || '"' || (p.PatientCode) || '   (' || p.FirstName || COALESCE(p.MiddleName, ' ') || p.LastName || ')"') AS "Remark"
    			,stk.CostPrice
    			,con.Quantity * stk.CostPrice AS "TotalConsumedValue"
    			,con.ConsumptionReceiptId
    			,itemcategory.SubCategoryId
    			,itemcategory.SubCategoryName
    		FROM WARD_INV_Consumption AS con
    		LEFT JOIN WARD_INV_ConsumptionReceipt cr ON con.ConsumptionReceiptId = cr.ConsumptionReceiptId
    		LEFT JOIN PAT_Patient p ON cr.PatientId = p.PatientId
    		INNER JOIN INV_MST_Stock stk ON con.StockId = stk.StockId
    		INNER JOIN INV_MST_Item AS itm ON con.ItemId = itm.ItemId
    		INNER JOIN INV_MST_ItemSubCategory AS itemcategory ON itm.SubCategoryId = itemcategory.SubCategoryId
    		INNER JOIN INV_MST_UnitOfMeasurement uom ON itm.UnitOfMeasurementId = uom.UOMId
    		WHERE con.StoreId = p_storeid
    			AND (con.ConsumptionDate)::DATE BETWEEN p_fromdate
    				AND p_todate
    			AND itm.ItemType = 'consumables'
    		group by con.consumptiondate
    			,con.itemname
    			,con.quantity
    			,usedby
    			,con.remark
    			,stk.costprice
    			,uom.uomname
    			,con.consumptionreceiptid
    			,p.firstname
    			,p.middlename
    			,p.lastname
    			,patientcode
    			,itemcategory.subcategoryid
    			,itemcategory.subcategoryname
    		order by con.consumptiondate desc;
    	end if;
    end;
END;
$$ LANGUAGE plpgsql;