CREATE OR REPLACE FUNCTION sp_phrmreport_returnfromcustomerreport(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_userid INT DEFAULT NULL,
    p_dispensaryid INT DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
BEGIN
    /*
     filename: "sp_phrmreport_returnfromcustomerreport" 
     created: 2021-05-01/ramesh
     description: to get details about return from customer
     example to execute the stored procedure we just created:
    	execute sp_phrmreport_returnfromcustomerreport '2021-05-01','2021-07-13'
     remarks: 
     change history
     s.no.    date/user              change          remarks
     1.	     2021-05-01/ramesh		                inital draft
     2.      2021-07-30/ramesh                      add dispensarywise filter and show dispensary name in grid.
     3.		 2021-09-01/sanjit						added patientname and hospital code, removed stocktxn from join logic, instead used as nested query for expirydate
     4.      rohit/13feb'23						    MRP-> SalePrice
    */
    
    	-- body of the stored procedure
    	OPEN ref1 FOR SELECT G.GenericName
    		,I.ItemName
    		,(IR.CreatedOn)::DATE AS ReturnedDate
    		,IRI.CreditNoteNumber AS CreditNoteNumber
    		,E.FullName AS UserName
    		,C.CounterName
    		,IRI.ReturnedQty
    		,IRI.SalePrice
    		,IRI.BatchNo
    		,
    		--> must remove the dependency from stock transaction table asap
    		(
    			SELECT  ExpiryDate
    			FROM PHRM_TXN_StockTransaction ST
    			WHERE IRI.InvoiceReturnItemId = ST.ReferenceNo
    				AND (
    					ST.TransactionType = 'sale-returned-item'
    					OR ST.TransactionType = 'manual-sales-return'
    					) LIMIT 1
    			) AS ExpiryDate
    		,COALESCE(IRI.TotalAmount, 0) AS TotalAmount
    		,'ph' || coalesce((inv.invoiceprintid)::varchar, ir.referenceinvoiceno) as issueno
    		,s.name as dispensaryname
    		,pat.patientcode
    		,pat.shortname as patientname
    	from phrm_txn_invoicereturnitems iri
    	inner join phrm_txn_invoicereturn ir on iri.invoicereturnid = ir.invoicereturnid
    	left join phrm_txn_invoice inv on ir.invoiceid = inv.invoiceid -- left join for manual sales return
    	inner join pat_patient pat on inv.patientid = pat.patientid
    	inner join phrm_mst_item i on iri.itemid = i.itemid
    	inner join phrm_mst_generic g on i.genericid = g.genericid
    	inner join emp_employee e on iri.createdby = e.employeeid
    	inner join phrm_mst_counter c on iri.counterid = c.counterid
    	inner join phrm_mst_store s on iri.storeid = s.storeid
    	where (
    			iri.createdby = p_userid
    			or p_userid is null
    			and iri.storeid = p_dispensaryid
    			or p_dispensaryid is null
    			)
    		and (ir.createdon)::date between p_fromdate
    			and p_todate;
        return next ref1;
END;
$$ LANGUAGE plpgsql;