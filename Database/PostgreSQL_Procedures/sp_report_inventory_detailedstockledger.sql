CREATE OR REPLACE FUNCTION sp_report_inventory_detailedstockledger(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_itemid INT DEFAULT NULL,
    p_storeid INT DEFAULT NULL
)
RETURNS TABLE (
    "TransactionDate" TIMESTAMP,
    "ReceiptQty" INT,
    "ReceiptRate" DECIMAL,
    "ReceiptAmount" DECIMAL,
    "IssueQty" INT,
    "IssueRate" DECIMAL,
    "IssueAmount" DECIMAL,
    "BalanceQty" INT,
    "BalanceRate" DECIMAL,
    "BalanceAmount" DECIMAL,
    "ReferenceNo" VARCHAR,
    "Store" VARCHAR,
    "Username" VARCHAR,
    "Remarks" VARCHAR,
    "ItemName" VARCHAR
) AS $$
DECLARE
    v_balanceqty FLOAT := 0;
    v_balanceamount DECIMAL(20,4) := 0;
BEGIN
    /*
    filename: sp_report_inventory_detailedstockledger '2021-05-13', '2021-09-13', null, null
    createdby/date: rajib/20-07-2021
    description: sp to get the stock detail ledger for inventory.
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1        ramesh/29-08-2021                    corrected for txn type and storeid for dispatch
    2.		 rohit/31mar22						  itemname is fetched.
    3.		 rohit/9jun'22						  ItemId is filter (mistake: before it was directly checking as null)
    */
        -- body of the stored procedure
        -- Drop the table if it already exists
        DROP TABLE IF EXISTS temp_TempTxnsTable;CREATE TEMP TABLE temp_TempTxnsTable AS SELECT TXNS.* , (0)::FLOAT AS "BalanceQty", (0)::DECIMAL(16,4) AS "BalanceRate" , (0)::DECIMAL(16,4) AS "BalanceAmount"
        
        FROM 
            (
                SELECT   STKT.TransactionDate, COALESCE(STKT.InQty,0) AS "ReceiptQty", COALESCE(STKT.CostPrice,0) AS "ReceiptRate", COALESCE(STKT.InQty,0) * COALESCE(STKT.CostPrice,0) AS "ReceiptAmount",
                        NULL AS "IssueQty", NULL AS "IssueRate", NULL AS "IssueAmount", 
                        GR.GoodsReceiptID AS "ReferenceNo", GRI.GRItemSpecification AS "Remarks",S.Name AS "Store", E.FullName AS "Username",I.ItemName
                FROM    INV_TXN_StockTransaction STKT JOIN
                        EMP_Employee E ON STKT.CreatedBy = E.EmployeeId LEFT JOIN 
                        INV_TXN_GoodsReceiptItems GRI ON STKT.ReferenceNo = GRI.GoodsReceiptItemId LEFT JOIN
                        INV_TXN_GoodsReceipt GR ON GRI.GoodsReceiptId = GR.GoodsReceiptID JOIN
    					PHRM_MST_Store S ON GR.StoreId = S.StoreId
    					JOIN INV_MST_Item I ON GRI.ItemId=I.ItemId
                WHERE  STKT.TransactionType IN ('opening-item', 'goodreceipt-items') AND
                        (STKT.ItemId = p_itemid OR p_itemid IS NULL) AND
                        (STKT.TransactionDate)::date BETWEEN p_fromdate AND  p_todate
    					AND (STKT.StoreId = p_storeid OR p_storeid IS NULL)
    
                UNION ALL
    
                SELECT  STKT.TransactionDate, NULL AS "ReceiptQty",NULL AS "ReceiptRate",NULL AS "ReceiptAmount",
                        COALESCE(STKT.OutQty,0)  AS "IssueQty",COALESCE(STKT.CostPrice,0) AS "IssueRate",COALESCE(STKT.OutQty,0) * COALESCE(STKT.CostPrice,0) AS "IssueAmount", 
                        D.DispatchId AS "ReferenceNo", D.Remarks AS "Remarks",S.Name AS "Store", COALESCE(E.FullName, 'not received') AS "Username",I.ItemName
                FROM    INV_TXN_StockTransaction STKT LEFT JOIN 
                        INV_TXN_DispatchItems D ON STKT.ReferenceNo = D.DispatchItemsId LEFT JOIN
                        PHRM_MST_Store S ON D.TargetStoreId = S.StoreId LEFT JOIN
                        EMP_Employee E ON D.ReceivedById = E.EmployeeId
    					JOIN INV_MST_Item I ON D.ItemId=I.ItemId
                WHERE  STKT.TransactionType IN ('dispatched-item-from', 'dispatched-item-to') and
                        (stkt.itemid = p_itemid or p_itemid is null) and
                        (stkt.transactiondate)::date  between p_fromdate and p_todate
    					and (stkt.storeid = p_storeid or p_storeid is null)
            ) txns
      order by txns.transactiondate;
    
    
        
        
        RETURN QUERY SELECT
            transactiondate,
            receiptqty,
            receiptrate,
            receiptamount,
            issueqty,
            issuerate,
            issueamount,
            sum(coalesce(coalesce(receiptqty, -issueqty), openingqty)) over (order by transactiondate, (case when openingqty is not null then 0 else 1 end)) AS "BalanceQty",
            coalesce(coalesce(receiptrate, issuerate), openingrate) AS "BalanceRate",
            sum(coalesce(coalesce(receiptqty, -issueqty), openingqty) * coalesce(coalesce(receiptrate, issuerate), openingrate)) over (order by transactiondate, (case when openingqty is not null then 0 else 1 end)) AS "BalanceAmount",
            referenceno,
            store,
            username,
            remarks,
            itemname
        from temp_temptxnstable;
END;
$$ LANGUAGE plpgsql;