CREATE PROCEDURE SP_All_IRD_InvoiceDetails
	 @FromDate DATETIME = NULL
	,@ToDate DATETIME = NULL
AS
/*
    FileName: [SP_All_IRD_InvoiceDetails] 
    CreatedBy/date: Umed/2017-09-294
    Description: to get all the Invoice Details as per IRD requirements 
    Change History
    S.No.    UpdatedBy/Date				 Remarks
    1        Sanjeev/2023-June-11        Return all Invoice Details as per new ird requirements
	2		 Krishna/2023-July-9		 Copy from EMR_V2.2.10 version to EMR_V3.1
    */
BEGIN
	IF (@FromDate IS NOT NULL)
		OR (@ToDate IS NOT NULL)
	BEGIN
		SET NOCOUNT ON

		SELECT *
		FROM (
			(
				SELECT fiscYr.FiscalYearFormatted AS Fiscal_Year
					,CONVERT(VARCHAR(30), ret.CreditNoteNumber) AS Bill_No
					,pats.ShortName AS Customer_name
					,pats.PANNumber
					,CONVERT(DATETIME, ret.ReturnedOn) AS BillDate
					,ret.ReturnSubTotal AS Amount
					,ret.ReturnDiscountAmount AS DiscountAmount
					,CONVERT(FLOAT, 0.00) AS Taxable_Amount
					,CONVERT(FLOAT, 0.00) AS Tax_Amount
					,ret.ReturnTotalAmount AS Total_Amount
					,txnItms.ItemNameAndQuantity
					,CASE 
						WHEN ret.IsReturnSyncedWithIRD = 1
							THEN 'Yes'
						ELSE 'No'
						END AS SyncedWithIRD
					,CASE 
						WHEN biltxn.PrintCount > 0
							THEN 'Yes'
						ELSE 'No'
						END AS Is_Printed
					,CONVERT(VARCHAR(20), CONVERT(TIME, ret.ReturnedOn), 100) AS Printed_Time
					,ret.ReturnedBy AS Entered_By
					,ret.ReturnedBy AS Printed_by
					,CASE 
						WHEN ISNULL(ret.IsReturnRealTime, 0) = 1
							THEN 'Yes'
						ELSE 'No'
						END AS Is_Realtime
					,'True' AS Is_Bill_Active
					,ret.ReturnPaymentMethod AS Payment_Method
					,'N/A' AS TransactionId
					,CONVERT(FLOAT, 0.00) AS VAT_Refund_Amount
				FROM BIL_TXN_BillingTransaction biltxn
				INNER JOIN (
					(
						SELECT BillingTransactionId
							,(
								SELECT ItemName AS 'ItemName'
									,CONVERT(INT, - RetQuantity) AS 'Quantity'
								FROM BIL_TXN_InvoiceReturnItems AS innerItms
								WHERE innerItms.BillingTransactionId = outerItems.BillingTransactionId
								FOR JSON PATH
								) AS ItemNameAndQuantity
						FROM BIL_TXN_BillingTransactionItems AS outerItems
						GROUP BY BillingTransactionId
						)
					) txnItms ON biltxn.BillingTransactionId = txnItms.BillingTransactionId
				INNER JOIN EMP_Employee emp ON emp.EmployeeId = biltxn.CreatedBy
				INNER JOIN PAT_Patient pats ON pats.PatientId = biltxn.PatientId
				INNER JOIN BIL_CFG_FiscalYears fiscYr ON biltxn.FiscalYearId = fiscYr.FiscalYearId
				INNER JOIN (
					SELECT BillingTransactionId 'ReturnTxnId'
						,'CRN' + CONVERT(VARCHAR(10), CreditNoteNumber) 'CreditNoteNumber'
						,- SubTotal 'ReturnSubTotal'
						,- DiscountAmount 'ReturnDiscountAmount'
						,- TotalAmount 'ReturnTotalAmount'
						,IsRemoteSynced 'IsReturnSyncedWithIRD'
						,1 AS ReturnPrintCount
						,0 AS 'ReturnVATRefundAmount'
						,e.FullName 'ReturnedBy'
						,r.CreatedOn 'ReturnedOn'
						,PaymentMode AS 'ReturnPaymentMethod'
						,IsRealtime AS 'IsReturnRealTime'
					FROM BIL_TXN_InvoiceReturn r
					JOIN EMP_Employee e ON r.CreatedBy = e.EmployeeId
					WHERE r.IsActive = 1
					) ret ON biltxn.BillingTransactionId = ret.ReturnTxnId
				WHERE CONVERT(DATE, biltxn.CreatedOn) BETWEEN CONVERT(DATE, @FromDate)
						AND CONVERT(DATE, @ToDate)
				)
			
			UNION ALL
			
			(
				(
					SELECT fiscYr.FiscalYearFormatted AS Fiscal_Year
						,ISNULL(biltxn.InvoiceCode, 'BL') + CONVERT(VARCHAR(30), biltxn.InvoiceNo) AS Bill_No
						,pats.ShortName AS Customer_name
						,
						--sud:2July'21--revised column to take Customer_name
						pats.PANNumber
						,CONVERT(DATETIME, biltxn.CreatedOn) AS BillDate
						,biltxn.SubTotal AS Amount
						,biltxn.DiscountAmount AS DiscountAmount
						,CONVERT(FLOAT, 0.00) AS Taxable_Amount
						,CONVERT(FLOAT, 0.00) AS Tax_Amount
						,biltxn.TotalAmount AS Total_Amount
						,txnItms.ItemNameAndQuantity
						,CASE 
							WHEN biltxn.IsRemoteSynced = 1
								THEN 'Yes'
							ELSE 'No'
							END AS SyncedWithIRD
						,CASE 
							WHEN biltxn.PrintCount > 0
								THEN 'Yes'
							ELSE 'No'
							END AS Is_Printed
						,CONVERT(VARCHAR(20), CONVERT(TIME, biltxn.CreatedOn), 100) AS Printed_Time
						,emp.FullName AS Entered_By
						,emp.FullName AS Printed_by
						,CASE 
							WHEN ISNULL(biltxn.IsRealtime, 0) = 1
								THEN 'Yes'
							ELSE 'No'
							END AS Is_Realtime
						,'True' AS Is_Bill_Active
						,biltxn.PaymentMode AS Payment_Method
						,'N/A' AS TransactionId
						,CONVERT(FLOAT, 0.00) AS VAT_Refund_Amount
					FROM BIL_TXN_BillingTransaction biltxn
					INNER JOIN (
						(
							SELECT BillingTransactionId
								,(
									SELECT ItemName AS 'ItemName'
										,CONVERT(INT, Quantity) AS 'Quantity'
									FROM BIL_TXN_BillingTransactionItems AS innerItms
									WHERE innerItms.BillingTransactionId = outerItems.BillingTransactionId
									FOR JSON PATH
									) AS ItemNameAndQuantity
							FROM BIL_TXN_BillingTransactionItems AS outerItems
							GROUP BY BillingTransactionId
							)
						) txnItms ON biltxn.BillingTransactionId = txnItms.BillingTransactionId
					INNER JOIN EMP_Employee emp ON emp.EmployeeId = biltxn.CreatedBy
					INNER JOIN PAT_Patient pats ON pats.PatientId = biltxn.PatientId
					INNER JOIN BIL_CFG_FiscalYears fiscYr ON biltxn.FiscalYearId = fiscYr.FiscalYearId
					WHERE CONVERT(DATE, biltxn.CreatedOn) BETWEEN CONVERT(DATE, @FromDate)
							AND CONVERT(DATE, @ToDate)
					)
				
				UNION ALL
				
				(
					(
						SELECT fisc.FiscalYearFormatted AS Fiscal_Year
							,ret.CreditNoteNumber AS Bill_No
							,pat.ShortName AS Customer_name
							,pat.PANNumber
							,CONVERT(DATETIME, ret.ReturnedOn) AS BillDate
							,ret.ReturnSubTotal AS Amount
							,ret.ReturnDiscountAmount AS DiscountAmount
							,CONVERT(FLOAT, 0.00) AS Taxable_Amount
							,CONVERT(FLOAT, 0.00) AS Tax_Amount
							,ret.ReturnTotalAmount AS Total_Amount
							,txnItms.ItemNameAndQuantity
							,CASE 
								WHEN ret.IsReturnSyncedWithIRD = 1
									THEN 'Yes'
								ELSE 'No'
								END AS SyncedWithIRD
							,CASE 
								WHEN inv.PrintCount > 0
									THEN 'Yes'
								ELSE 'No'
								END AS Is_Printed
							,CONVERT(VARCHAR(20), CONVERT(TIME, ret.ReturnedOn), 100) AS Printed_Time
							,ret.ReturnedBy AS Entered_By
							,ret.ReturnedBy AS Printed_by
							,CASE 
								WHEN ISNULL(ret.IsReturnRealTime, 0) = 1
									THEN 'Yes'
								ELSE 'No'
								END AS Is_Realtime
							,'True' AS Is_Bill_Active
							,ret.ReturnPaymentMethod AS Payment_Method
							,'N/A' AS TransactionId
							,CONVERT(FLOAT, 0.00) AS VAT_Refund_Amount
						FROM PHRM_TXN_Invoice inv
						INNER JOIN (
							(
								SELECT InvoiceId
									,(
										SELECT invItem.ItemName AS 'ItemName'
											,CONVERT(INT, - ReturnedQty) AS 'Quantity'
											,(uom.UOMName) AS 'UOM'
										FROM PHRM_TXN_InvoiceReturnItems AS innerItms
										INNER JOIN PHRM_TXN_InvoiceItems invItem ON innerItms.InvoiceItemId = invItem.InvoiceItemId
										INNER JOIN PHRM_MST_Item mstItem ON mstItem.ItemId = invItem.ItemId
										INNER JOIN PHRM_MST_UnitOfMeasurement uom ON uom.UOMId = mstItem.UOMId
										WHERE innerItms.InvoiceId = outerItems.InvoiceId
										FOR JSON PATH
										) AS ItemNameAndQuantity
								FROM PHRM_TXN_InvoiceItems AS outerItems
								GROUP BY InvoiceId
								)
							) txnItms ON inv.InvoiceId = txnItms.InvoiceId
						INNER JOIN EMP_Employee emp ON emp.EmployeeId = inv.CreatedBy
						INNER JOIN PAT_Patient pat ON pat.PatientId = inv.PatientId
						INNER JOIN BIL_CFG_FiscalYears fisc ON inv.FiscalYearId = fisc.FiscalYearId
						INNER JOIN (
							SELECT InvoiceId 'ReturnTxnId'
								,'CR-PH' + CONVERT(VARCHAR(10), CreditNoteID) 'CreditNoteNumber'
								,- SubTotal 'ReturnSubTotal'
								,- DiscountAmount 'ReturnDiscountAmount'
								,- TotalAmount 'ReturnTotalAmount'
								,IsRemoteSynced 'IsReturnSyncedWithIRD'
								,1 AS ReturnPrintCount
								,0 AS 'ReturnVATRefundAmount'
								,e.FullName 'ReturnedBy'
								,invRet.CreatedOn 'ReturnedOn'
								,PaymentMode AS 'ReturnPaymentMethod'
								,IsRealtime AS 'IsReturnRealTime'
							FROM PHRM_TXN_InvoiceReturn invRet
							JOIN EMP_Employee e ON invRet.CreatedBy = e.EmployeeId
							JOIN PHRM_CFG_FiscalYears fisc ON invRet.FiscalYearId = fisc.FiscalYearId
							) ret ON inv.InvoiceId = ret.ReturnTxnId
						WHERE (
								CONVERT(DATE, inv.CreateOn) BETWEEN CONVERT(DATE, @FromDate)
									AND CONVERT(DATE, @ToDate)
								)
						)
					
					UNION ALL
					
					(
						(
							SELECT fiscYr.FiscalYearFormatted AS Fiscal_Year
								,'PH' + CONVERT(VARCHAR(30), inv.InvoicePrintId) AS Bill_No
								,pats.ShortName AS Customer_name
								,pats.PANNumber
								,CONVERT(DATETIME, inv.CreateOn) AS BillDate
								,inv.SubTotal AS Amount
								,inv.DiscountAmount AS DiscountAmount
								,CONVERT(FLOAT, 0.00) AS Taxable_Amount
								,CONVERT(FLOAT, 0.00) AS Tax_Amount
								,inv.TotalAmount AS Total_Amount
								,txnItms.ItemNameAndQuantity
								,CASE 
									WHEN inv.IsRemoteSynced = 1
										THEN 'Yes'
									ELSE 'No'
									END AS SyncedWithIRD
								,CASE 
									WHEN inv.PrintCount > 0
										THEN 'Yes'
									ELSE 'No'
									END AS Is_Printed
								,CONVERT(VARCHAR(20), CONVERT(TIME, inv.CreateOn), 100) AS Printed_Time
								,emp.FullName AS Entered_By
								,emp.FullName AS Printed_by
								,CASE 
									WHEN ISNULL(inv.IsRealtime, 0) = 1
										THEN 'Yes'
									ELSE 'No'
									END AS Is_Realtime
								,'True' AS Is_Bill_Active
								,inv.PaymentMode AS Payment_Method
								,'N/A' AS TransactionId
								,CONVERT(FLOAT, 0.00) AS VAT_Refund_Amount
							FROM PHRM_TXN_Invoice inv
							INNER JOIN (
								(
									SELECT InvoiceId
										,(
											SELECT innerItms.ItemName AS 'ItemName'
												,CONVERT(INT, Quantity) AS 'Quantity'
												,uom.UOMName AS 'UOM'
											FROM PHRM_TXN_InvoiceItems AS innerItms
											INNER JOIN PHRM_MST_Item AS mstItem ON mstItem.ItemId = innerItms.ItemId
											INNER JOIN PHRM_MST_UnitOfMeasurement AS uom ON uom.UOMId = mstItem.UOMId
											WHERE innerItms.InvoiceId = outerItems.InvoiceId
											FOR JSON PATH
											) AS ItemNameAndQuantity
									FROM PHRM_TXN_InvoiceItems AS outerItems
									GROUP BY InvoiceId
									)
								) txnItms ON inv.InvoiceId = txnItms.InvoiceId
							INNER JOIN EMP_Employee emp ON emp.EmployeeId = inv.CreatedBy
							INNER JOIN PAT_Patient pats ON pats.PatientId = inv.PatientId
							INNER JOIN BIL_CFG_FiscalYears fiscYr ON inv.FiscalYearId = fiscYr.FiscalYearId
							WHERE CONVERT(DATE, inv.CreateOn) BETWEEN CONVERT(DATE, @FromDate)
									AND CONVERT(DATE, @ToDate)
							)
						)
					)
				)
			) AS IRDDetails
		ORDER BY IRDDetails.BillDate DESC
	END
END