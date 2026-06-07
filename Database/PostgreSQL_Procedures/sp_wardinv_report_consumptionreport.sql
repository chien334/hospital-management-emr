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
    "TotalConsumedValue" DECIMAL,
    "ConsumptionReceiptId" INT,
    "SubCategoryId" INT,
    "SubCategoryName" VARCHAR
) AS $$
BEGIN
    /*
    filename: "sp_wardinv_report_consumptionreport"
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
    		RETURN QUERY SELECT 
    			(con."ConsumptionDate")::date::timestamp AS "Date"
    			,con."ItemName"::VARCHAR
    			,con."Quantity"::INT
    			,uom."UOMName"::VARCHAR
    			,con."UsedBy"::VARCHAR AS "User"
    			,(COALESCE(con."Remark", '') || COALESCE(' "' || p."PatientCode" || '   (' || p."FirstName" || COALESCE(p."MiddleName", ' ') || p."LastName" || ')"', ''))::VARCHAR AS "Remark"
    			,stk."CostPrice"::DECIMAL
    			,(con."Quantity" * stk."CostPrice")::DECIMAL AS "TotalConsumedValue"
    			,con."ConsumptionReceiptId"::INT
    			,itemcategory."SubCategoryId"::INT
    			,itemcategory."SubCategoryName"::VARCHAR
    		FROM "WARD_INV_Consumption" AS con
    		LEFT JOIN "WARD_INV_ConsumptionReceipt" cr ON con."ConsumptionReceiptId" = cr."ConsumptionReceiptId"
    		LEFT JOIN "PAT_Patient" p ON cr."PatientId" = p."PatientId"
    		INNER JOIN "INV_MST_Stock" stk ON con."StockId" = stk."StockId"
    		INNER JOIN "INV_MST_Item" AS itm ON con."ItemId" = itm."ItemId"
    		INNER JOIN "INV_MST_ItemSubCategory" AS itemcategory ON itm."SubCategoryId" = itemcategory."SubCategoryId"
    		INNER JOIN "INV_MST_UnitOfMeasurement" uom ON itm."UnitOfMeasurementId" = uom."UOMId"
    		WHERE con."StoreId" = p_storeid
    			AND (con."ConsumptionDate")::DATE BETWEEN (p_fromdate)::DATE AND (p_todate)::DATE
    			AND itm."ItemType" = 'consumables'
    		group by con."ConsumptionDate"
    			,con."ItemName"
    			,con."Quantity"
    			,con."UsedBy"
    			,con."Remark"
    			,stk."CostPrice"
    			,uom."UOMName"
    			,con."ConsumptionReceiptId"
    			,p."FirstName"
    			,p."MiddleName"
    			,p."LastName"
    			,p."PatientCode"
    			,itemcategory."SubCategoryId"
    			,itemcategory."SubCategoryName"
    		order by con."ConsumptionDate" desc;
    	end if;
    end;
END;
$$ LANGUAGE plpgsql;