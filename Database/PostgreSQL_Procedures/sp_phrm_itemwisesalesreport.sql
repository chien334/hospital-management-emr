CREATE OR REPLACE FUNCTION sp_phrm_itemwisesalesreport(
    p_fromdate DATE,
    p_todate DATE,
    p_itemid INT DEFAULT NULL,
    p_storeid INT DEFAULT NULL,
    p_counterid INT DEFAULT NULL,
    p_createdby INT DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
BEGIN
    /*
    example to execute sp: sp_phrm_itemwisesalesreport '2022-02-15','2022-02-16',435,null,null,null
    filename: "[sp_phrm_itemwisesalesreport"]
    createdby/date: rohit/2022-02-16
    description: to get daily sales report for particular item.
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1       rohit/2022-02-16                     created the script
    2.      rohit/13feb'23						 MRP-> SalePrice
    */
    
    	OPEN ref1 FOR SELECT InvoicePrintId
    		,GenericName
    		,ItemName
    		,PatientName
    		,BatchNo
    		,ExpiryDate
    		,Quantity
    		,Price
    		,SalePrice
    		,StockValue
    		,TotalAmount
    		,CreatedOn
    		,StoreName
    		,CounterName
    		,CreatedByName
    		,TransactionType
    		,Remark
    	FROM (
    		SELECT 'ph' || (inv.InvoicePrintId)::VARCHAR AS "InvoicePrintId"
    			,pat.FirstName || COALESCE(pat.MiddleName, ' ') || pat.LastName AS "PatientName"
    			,generic.GenericName AS "GenericName"
    			,mstitm.ItemName AS "ItemName"
    			,invitm.BatchNo AS "BatchNo"
    			,invitm.ExpiryDate AS "ExpiryDate"
    			,invitm.Quantity AS "Quantity"
    			,invitm.Price AS "Price"
    			,invitm.SalePrice AS "SalePrice"
    			,invitm.Quantity * invitm.Price AS "StockValue"
    			,invitm.TotalAmount AS "TotalAmount"
    			,invitm.CreatedOn AS "CreatedOn"
    			,CASE 
    				WHEN inv.PaymentMode = 'cash'
    					THEN 'cashsales'
    				ELSE 'creditsales'
    				END AS "TransactionType"
    			,store.Name AS "StoreName"
    			,counter.CounterName AS "CounterName"
    			,emp.FullName AS "CreatedByName"
    			,inv.Remark AS "Remark"
    		FROM PHRM_TXN_InvoiceItems invitm
    		JOIN PHRM_TXN_Invoice inv ON invitm.InvoiceId = inv.InvoiceId
    		JOIN PHRM_MST_Item mstitm ON invitm.ItemId = mstitm.ItemId
    		JOIN PHRM_MST_Generic generic ON mstitm.GenericId = generic.GenericId
    		JOIN PAT_Patient pat ON invitm.PatientId = pat.PatientId
    		JOIN PHRM_MST_Store store ON invitm.StoreId = store.StoreId
    		JOIN PHRM_MST_Counter counter ON invitm.CounterId = counter.CounterId
    		JOIN EMP_Employee emp ON invitm.CreatedBy = emp.EmployeeId
    		WHERE (invitm.CreatedOn)::DATE BETWEEN p_fromdate
    				AND p_todate
    			AND (
    				invitm.StoreId = p_storeid
    				OR p_storeid IS NULL
    				)
    			AND (
    				invitm.CounterId = p_counterid
    				OR p_counterid IS NULL
    				)
    			AND (
    				invitm.CreatedBy = p_createdby
    				OR p_createdby IS NULL
    				)
    			AND (
    				invitm.ItemId = p_itemid
    				OR p_itemid IS NULL
    				)
    		
    		UNION ALL
    		
    		SELECT 'cr-ph' || (invret.CreditNoteID)::VARCHAR AS "InvoicePrintId"
    			,pat.FirstName || COALESCE(pat.MiddleName, ' ') || pat.LastName AS "PatientName"
    			,generic.GenericName AS "GenericName"
    			,mstitm.ItemName AS "ItemId"
    			,invitmret.BatchNo AS "BatchNo"
    			,invitm.ExpiryDate AS "ExpiryDate"
    			,- invitmret.ReturnedQty AS "Quantity"
    			,invitmret.Price AS "Price"
    			,invitmret.SalePrice AS "SalePrice"
    			,- (invitmret.ReturnedQty * invitmret.Price) AS "StockValue"
    			,- invitmret.TotalAmount AS "TotalAmount"
    			,invitmret.CreatedOn AS "CreatedOn"
    			,CASE 
    				WHEN invret.PaymentMode = 'cash'
    					THEN 'cashsalesreturn'
    				ELSE 'creditsalesreturn'
    				END AS "TransactionType"
    			,store.Name AS "StoreName"
    			,counter.CounterName AS "CounterName"
    			,emp.FullName AS "CreatedByName"
    			,invret.Remarks || ' reference invoiceno: ' || '(' || (inv.InvoicePrintID)::VARCHAR || ')' as "remark"
    		from phrm_txn_invoicereturnitems invitmret
    		join phrm_txn_invoicereturn invret on invitmret.invoicereturnid = invret.invoicereturnid
    		join phrm_txn_invoiceitems invitm on invitmret.invoiceitemid = invitm.invoiceitemid
    		join phrm_txn_invoice inv on invitm.invoiceid = inv.invoiceid
    		join phrm_mst_item mstitm on invitmret.itemid = mstitm.itemid
    		join phrm_mst_generic generic on mstitm.genericid = generic.genericid
    		join pat_patient pat on invret.patientid = pat.patientid
    		join phrm_mst_store store on invitmret.storeid = store.storeid
    		join phrm_mst_counter counter on invitmret.counterid = counter.counterid
    		join emp_employee emp on invitmret.createdby = emp.employeeid
    		where (invitmret.createdon)::date between p_fromdate
    				and p_todate
    			and (
    				invitmret.storeid = p_storeid
    				or p_storeid is null
    				)
    			and (
    				invitmret.counterid = p_counterid
    				or p_counterid is null
    				)
    			and (
    				invitmret.createdby = p_createdby
    				or p_createdby is null
    				)
    			and (
    				invitmret.itemid = p_itemid
    				or p_itemid is null
    				)
    		) a
    	order by createdon desc;
        return next ref1;
END;
$$ LANGUAGE plpgsql;