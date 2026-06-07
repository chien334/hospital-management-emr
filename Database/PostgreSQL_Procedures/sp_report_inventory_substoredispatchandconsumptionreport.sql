CREATE OR REPLACE FUNCTION sp_report_inventory_substoredispatchandconsumptionreport(
    p_storeid INT DEFAULT NULL,
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_subcategoryid INT DEFAULT NULL,
    p_itemid INT DEFAULT NULL
)
RETURNS TABLE (
    "ItemCategoryName" VARCHAR,
    "SubCategoryName" VARCHAR,
    "StoreId" INT,
    "SubstoreName" VARCHAR,
    "ItemId" INT,
    "ItemName" VARCHAR,
    "Unit" VARCHAR,
    "CostPrice" DECIMAL,
    "DispatchedQty" INT,
    "DispatchedValue" DECIMAL,
    "ConsumedQty" TIMESTAMP,
    "ConsumedValue" TIMESTAMP,
    "Remarks" VARCHAR,
    "TotalAmountValue" DECIMAL
) AS $$
BEGIN
    /*
    filename: "sp_report_inventory_substoredispatchandconsumptionreport" null, '2022-05-18','2022-05-19'
    created: 18may'22/Rohit
    Description: To Get Substore Dispatched And Consumption Report Data With StoreId,FromDate,ToDate.
    Change History
    S.No.    Date/User              Change          Remarks
    1.	     18May'22/rohit		                  inital draft
    2.		 12oct'22/Rohit						  get CostPrice and TotalAmountValue
    3.	     31Oct'22/rohit						  calculation changes for totalamountvalue
    4.       22feb'23/Nirmala                     Add Filter Based On SubCategory and ItemName
    */
    
    	RETURN QUERY SELECT X.ItemCategoryName
    		,X.SubCategoryName
    		,X.StoreId
    		,X.SubstoreName
    		,X.ItemId
    		,X.ItemName
    		,X.UOMName AS "Unit"
    		,X.CostPrice
    		,SUM(COALESCE(X.DisatchedQty, 0)) AS "DispatchedQty"
    		,SUM(COALESCE((X.DisatchedQty)::MONEY * X.CostPrice, 0)) AS "DispatchedValue"
    		,SUM(COALESCE(X.ConsumedQty, 0)) AS "ConsumedQty"
    		,SUM(COALESCE((X.ConsumedQty)::MONEY * X.CostPrice, 0)) AS "ConsumedValue"
    		,X.Remarks
    		,(SUM(COALESCE((X.ConsumedQty)::MONEY * X.CostPrice, 0)) + SUM(COALESCE((X.DisatchedQty)::MONEY * X.CostPrice, 0))) AS "TotalAmountValue"
    	FROM (
    		SELECT IC.ItemCategoryName
    			,ISC.SubCategoryName
    			,Store.Name AS "SubstoreName"
    			,I.ItemId
    			,I.ItemName
    			,UOM.UOMName
    			,ST.CostPrice
    			,Store.StoreId
    			,CASE 
    				WHEN ST.TransactionType = 'dispatched-item-to'
    					THEN SUM(COALESCE(ST.INQty, 0))
    				ELSE 0
    				END AS DisatchedQty
    			,CASE 
    				WHEN ST.TransactionType = 'consumption-items'
    					THEN SUM(COALESCE(ST.OutQty, 0))
    				ELSE 0
    				END AS "ConsumedQty"
    			,ST.Remarks
    		FROM INV_TXN_StockTransaction ST
    		INNER JOIN INV_MST_Item I ON ST.ItemId = I.ItemId
    		INNER JOIN INV_MST_ItemCategory IC ON I.ItemCategoryId = IC.ItemCategoryId
    		INNER JOIN INV_MST_ItemSubCategory ISC ON I.SubCategoryId = ISC.SubCategoryId
    		INNER JOIN INV_MST_UnitOfMeasurement UOM ON I.UnitOfMeasurementId = UOM.UOMId
    		INNER JOIN PHRM_MST_Store Store ON ST.StoreId = Store.StoreId
    		LEFT JOIN INV_TXN_DispatchItems DI ON ST.ReferenceNo = DI.DispatchItemsId
    			AND ST.TransactionType = 'dispatched-item-to'
    		LEFT JOIN WARD_INV_Consumption C ON ST.ReferenceNo = C.ConsumptionId
    			AND ST.TransactionType = 'consumption-items'
    		WHERE ST.TransactionType IN (
    				'dispatched-item-to'
    				,'consumption-items'
    				)
    			and (st.transactiondate)::date between p_fromdate
    				and p_todate
    			and (
    				st.storeid = p_storeid
    				or p_storeid is null
    				)
    			and (
    				isc.subcategoryid = p_subcategoryid
    				or p_subcategoryid is null
    				)
    			and (
    				i.itemid = p_itemid
    				or p_itemid is null
    				)
    		group by ic.itemcategoryname
    			,isc.subcategoryname
    			,i.itemname
    			,i.itemid
    			,uom.uomname
    			,st.transactiondate
    			,st.transactiontype
    			,st.costprice
    			,store.storeid
    			,store.name
    			,st.remarks
    		) x
    	group by x.itemcategoryname
    		,x.subcategoryname
    		,x.storeid
    		,x.substorename
    		,x.itemid
    		,x.itemname
    		,x.uomname
    		,x.costprice
    		,x.remarks
    	order by x.substorename
    		,x.itemname asc;
END;
$$ LANGUAGE plpgsql;