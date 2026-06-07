CREATE OR REPLACE FUNCTION sp_all_ird_invoicedetails(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL
)
RETURNS TABLE (
    "*" VARCHAR
) AS $$
BEGIN
    /*
        filename: "sp_all_ird_invoicedetails" 
        createdby/date: umed/2017-09-294
        description: to get all the invoice details as per ird requirements 
        change history
        s.no.    updatedby/date				 remarks
        1        sanjeev/2023-june-11        return all invoice details as per new ird requirements
    	2		 krishna/2023-july-9		 copy from emr_v2.2.10 version to emr_v3.1
        */
    begin
    	if (p_fromdate is not null)
    		or (p_todate is not null)
    	then
    		
    
    		RETURN QUERY SELECT *
    		from (
    			(
    				select fiscyr.fiscalyearformatted as fiscal_year
    					,(ret.creditnotenumber)::varchar as bill_no
    					,pats.shortname as customer_name
    					,pats.pannumber
    					,(ret.returnedon)::timestamp as billdate
    					,ret.returnsubtotal as amount
    					,ret.returndiscountamount as discountamount
    					,(0.00)::float as taxable_amount
    					,(0.00)::float as tax_amount
    					,ret.returntotalamount as total_amount
    					,txnitms.itemnameandquantity
    					,case 
    						when ret.isreturnsyncedwithird = 1
    							then 'Yes'
    						else 'No'
    						end as syncedwithird
    					,case 
    						when biltxn.printcount > 0
    							then 'Yes'
    						else 'No'
    						end as is_printed
    					,to_char((ret.returnedon)::time, 'YYYY-MM-DD') as printed_time
    					,ret.returnedby as entered_by
    					,ret.returnedby as printed_by
    					,case 
    						when coalesce(ret.isreturnrealtime, 0) = 1
    							then 'Yes'
    						else 'No'
    						end as is_realtime
    					,'True' as is_bill_active
    					,ret.returnpaymentmethod as payment_method
    					,'N/A' as transactionid
    					,(0.00)::float as vat_refund_amount
    				from bil_txn_billingtransaction biltxn
    				inner join (
    					(
    						select billingtransactionid
    							,(
    								(select json_agg(t) from (select itemname as "itemname"
    									,(- retquantity)::int as "quantity"
    								from bil_txn_invoicereturnitems as inneritms
    								where inneritms.billingtransactionid = outeritems.billingtransactionid) as "t")::text
    								) as itemnameandquantity
    						from bil_txn_billingtransactionitems as outeritems
    						group by billingtransactionid
    						)
    					) txnitms on biltxn.billingtransactionid = txnitms.billingtransactionid
    				inner join emp_employee emp on emp.employeeid = biltxn.createdby
    				inner join pat_patient pats on pats.patientid = biltxn.patientid
    				inner join bil_cfg_fiscalyears fiscyr on biltxn.fiscalyearid = fiscyr.fiscalyearid
    				inner join (
    					select billingtransactionid as "returntxnid"
    						,'CRN' || (creditnotenumber)::varchar as "creditnotenumber"
    						,- subtotal as "returnsubtotal"
    						,- discountamount as "returndiscountamount"
    						,- totalamount as "returntotalamount"
    						,isremotesynced as "isreturnsyncedwithird"
    						,1 as returnprintcount
    						,0 as "returnvatrefundamount"
    						,e.fullname as "returnedby"
    						,r.createdon as "returnedon"
    						,paymentmode as "returnpaymentmethod"
    						,isrealtime as "isreturnrealtime"
    					from bil_txn_invoicereturn r
    					join emp_employee e on r.createdby = e.employeeid
    					where r.isactive = 1
    					) ret on biltxn.billingtransactionid = ret.returntxnid
    				where (biltxn.createdon)::date between (p_fromdate)::date
    						and (p_todate)::date
    				)
    			
    			union all
    			
    			(
    				(
    					select fiscyr.fiscalyearformatted as fiscal_year
    						,coalesce(biltxn.invoicecode, 'BL') || (biltxn.invoiceno)::varchar as bill_no
    						,pats.shortname as customer_name
    						,
    						--sud:2july'21--revised column to take Customer_name
    						pats.PANNumber
    						,(biltxn.CreatedOn)::TIMESTAMP AS BillDate
    						,biltxn.SubTotal AS Amount
    						,biltxn.DiscountAmount AS DiscountAmount
    						,(0.00)::FLOAT AS Taxable_Amount
    						,(0.00)::FLOAT AS Tax_Amount
    						,biltxn.TotalAmount AS Total_Amount
    						,txnItms.ItemNameAndQuantity
    						,CASE 
    							WHEN biltxn.IsRemoteSynced = 1
    								THEN 'yes'
    							ELSE 'no'
    							END AS SyncedWithIRD
    						,CASE 
    							WHEN biltxn.PrintCount > 0
    								THEN 'yes'
    							ELSE 'no'
    							END AS Is_Printed
    						,to_char((biltxn.CreatedOn)::TIME, 'yyyy-mm-dd') AS Printed_Time
    						,emp.FullName AS Entered_By
    						,emp.FullName AS Printed_by
    						,CASE 
    							WHEN COALESCE(biltxn.IsRealtime, 0) = 1
    								THEN 'yes'
    							ELSE 'no'
    							END AS Is_Realtime
    						,'true' AS Is_Bill_Active
    						,biltxn.PaymentMode AS Payment_Method
    						,'n/a' AS TransactionId
    						,(0.00)::FLOAT AS VAT_Refund_Amount
    					FROM BIL_TXN_BillingTransaction biltxn
    					INNER JOIN (
    						(
    							SELECT BillingTransactionId
    								,(
    									(SELECT json_agg(t) FROM (SELECT ItemName AS "ItemName"
    										,(Quantity)::INT AS "Quantity"
    									FROM BIL_TXN_BillingTransactionItems AS innerItms
    									WHERE innerItms.BillingTransactionId = outerItems.BillingTransactionId) AS "t")::text
    									) AS ItemNameAndQuantity
    							FROM BIL_TXN_BillingTransactionItems AS outerItems
    							GROUP BY BillingTransactionId
    							)
    						) txnItms ON biltxn.BillingTransactionId = txnItms.BillingTransactionId
    					INNER JOIN EMP_Employee emp ON emp.EmployeeId = biltxn.CreatedBy
    					INNER JOIN PAT_Patient pats ON pats.PatientId = biltxn.PatientId
    					INNER JOIN BIL_CFG_FiscalYears fiscYr ON biltxn.FiscalYearId = fiscYr.FiscalYearId
    					WHERE (biltxn.CreatedOn)::DATE BETWEEN (p_fromdate)::DATE
    							AND (p_todate)::DATE
    					)
    				
    				UNION ALL
    				
    				(
    					(
    						SELECT fisc.FiscalYearFormatted AS Fiscal_Year
    							,ret.CreditNoteNumber AS Bill_No
    							,pat.ShortName AS Customer_name
    							,pat.PANNumber
    							,(ret.ReturnedOn)::TIMESTAMP AS BillDate
    							,ret.ReturnSubTotal AS Amount
    							,ret.ReturnDiscountAmount AS DiscountAmount
    							,(0.00)::FLOAT AS Taxable_Amount
    							,(0.00)::FLOAT AS Tax_Amount
    							,ret.ReturnTotalAmount AS Total_Amount
    							,txnItms.ItemNameAndQuantity
    							,CASE 
    								WHEN ret.IsReturnSyncedWithIRD = 1
    									THEN 'yes'
    								ELSE 'no'
    								END AS SyncedWithIRD
    							,CASE 
    								WHEN inv.PrintCount > 0
    									THEN 'yes'
    								ELSE 'no'
    								END AS Is_Printed
    							,to_char((ret.ReturnedOn)::TIME, 'yyyy-mm-dd') AS Printed_Time
    							,ret.ReturnedBy AS Entered_By
    							,ret.ReturnedBy AS Printed_by
    							,CASE 
    								WHEN COALESCE(ret.IsReturnRealTime, 0) = 1
    									THEN 'yes'
    								ELSE 'no'
    								END AS Is_Realtime
    							,'true' AS Is_Bill_Active
    							,ret.ReturnPaymentMethod AS Payment_Method
    							,'n/a' AS TransactionId
    							,(0.00)::FLOAT AS VAT_Refund_Amount
    						FROM PHRM_TXN_Invoice inv
    						INNER JOIN (
    							(
    								SELECT InvoiceId
    									,(
    										(SELECT json_agg(t) FROM (SELECT invItem.ItemName AS "ItemName"
    											,(- ReturnedQty)::INT AS "Quantity"
    											,(uom.UOMName) AS "UOM"
    										FROM PHRM_TXN_InvoiceReturnItems AS innerItms
    										INNER JOIN PHRM_TXN_InvoiceItems invItem ON innerItms.InvoiceItemId = invItem.InvoiceItemId
    										INNER JOIN PHRM_MST_Item mstItem ON mstItem.ItemId = invItem.ItemId
    										INNER JOIN PHRM_MST_UnitOfMeasurement uom ON uom.UOMId = mstItem.UOMId
    										WHERE innerItms.InvoiceId = outerItems.InvoiceId) AS "t")::text
    										) AS ItemNameAndQuantity
    								FROM PHRM_TXN_InvoiceItems AS outerItems
    								GROUP BY InvoiceId
    								)
    							) txnItms ON inv.InvoiceId = txnItms.InvoiceId
    						INNER JOIN EMP_Employee emp ON emp.EmployeeId = inv.CreatedBy
    						INNER JOIN PAT_Patient pat ON pat.PatientId = inv.PatientId
    						INNER JOIN BIL_CFG_FiscalYears fisc ON inv.FiscalYearId = fisc.FiscalYearId
    						INNER JOIN (
    							SELECT InvoiceId AS "ReturnTxnId"
    								,'cr-ph' || (CreditNoteID)::VARCHAR AS "CreditNoteNumber"
    								,- SubTotal AS "ReturnSubTotal"
    								,- DiscountAmount AS "ReturnDiscountAmount"
    								,- TotalAmount AS "ReturnTotalAmount"
    								,IsRemoteSynced AS "IsReturnSyncedWithIRD"
    								,1 AS ReturnPrintCount
    								,0 AS "ReturnVATRefundAmount"
    								,e.FullName AS "ReturnedBy"
    								,invRet.CreatedOn AS "ReturnedOn"
    								,PaymentMode AS "ReturnPaymentMethod"
    								,IsRealtime AS "IsReturnRealTime"
    							FROM PHRM_TXN_InvoiceReturn invRet
    							JOIN EMP_Employee e ON invRet.CreatedBy = e.EmployeeId
    							JOIN PHRM_CFG_FiscalYears fisc ON invRet.FiscalYearId = fisc.FiscalYearId
    							) ret ON inv.InvoiceId = ret.ReturnTxnId
    						WHERE (
    								(inv.CreateOn)::DATE BETWEEN (p_fromdate)::DATE
    									AND (p_todate)::DATE
    								)
    						)
    					
    					UNION ALL
    					
    					(
    						(
    							SELECT fiscYr.FiscalYearFormatted AS Fiscal_Year
    								,'ph' || (inv.InvoicePrintId)::VARCHAR AS Bill_No
    								,pats.ShortName AS Customer_name
    								,pats.PANNumber
    								,(inv.CreateOn)::TIMESTAMP AS BillDate
    								,inv.SubTotal AS Amount
    								,inv.DiscountAmount AS DiscountAmount
    								,(0.00)::FLOAT AS Taxable_Amount
    								,(0.00)::FLOAT AS Tax_Amount
    								,inv.TotalAmount AS Total_Amount
    								,txnItms.ItemNameAndQuantity
    								,CASE 
    									WHEN inv.IsRemoteSynced = 1
    										THEN 'yes'
    									ELSE 'no'
    									END AS SyncedWithIRD
    								,CASE 
    									WHEN inv.PrintCount > 0
    										THEN 'yes'
    									ELSE 'no'
    									END AS Is_Printed
    								,to_char((inv.CreateOn)::TIME, 'yyyy-mm-dd') AS Printed_Time
    								,emp.FullName AS Entered_By
    								,emp.FullName AS Printed_by
    								,CASE 
    									WHEN COALESCE(inv.IsRealtime, 0) = 1
    										THEN 'yes'
    									ELSE 'no'
    									END AS Is_Realtime
    								,'true' AS Is_Bill_Active
    								,inv.PaymentMode AS Payment_Method
    								,'n/a' as transactionid
    								,(0.00)::float as vat_refund_amount
    							from phrm_txn_invoice inv
    							inner join (
    								(
    									select invoiceid
    										,(
    											(select json_agg(t) from (select inneritms.itemname as "itemname"
    												,(quantity)::int as "quantity"
    												,uom.uomname as "uom"
    											from phrm_txn_invoiceitems as inneritms
    											inner join phrm_mst_item as mstitem on mstitem.itemid = inneritms.itemid
    											inner join phrm_mst_unitofmeasurement as uom on uom.uomid = mstitem.uomid
    											where inneritms.invoiceid = outeritems.invoiceid) as "t")::text
    											) as itemnameandquantity
    									from phrm_txn_invoiceitems as outeritems
    									group by invoiceid
    									)
    								) txnitms on inv.invoiceid = txnitms.invoiceid
    							inner join emp_employee emp on emp.employeeid = inv.createdby
    							inner join pat_patient pats on pats.patientid = inv.patientid
    							inner join bil_cfg_fiscalyears fiscyr on inv.fiscalyearid = fiscyr.fiscalyearid
    							where (inv.createon)::date between (p_fromdate)::date
    									and (p_todate)::date
    							)
    						)
    					)
    				)
    			) as irddetails
    		order by irddetails.billdate desc;
    	end if;
    end;
END;
$$ LANGUAGE plpgsql;