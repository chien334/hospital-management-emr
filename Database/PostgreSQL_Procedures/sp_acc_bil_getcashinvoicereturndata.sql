CREATE OR REPLACE FUNCTION sp_acc_bil_getcashinvoicereturndata(
    p_transactiondate DATE,
    p_hospitalid INT
)
RETURNS TABLE (
    "BillingAccountingSyncId" INT,
    "ReferenceId" INT,
    "ReferenceModelName" VARCHAR,
    "ServiceDepartmentId" INT,
    "ItemId" INT,
    "PatientId" INT,
    "TransactionType" TIMESTAMP,
    "PaymentMode" VARCHAR,
    "SubTotal" DECIMAL,
    "TaxAmount" DECIMAL,
    "DiscountAmount" INT,
    "CoPaymentCashAmount" DECIMAL,
    "TotalAmount" DECIMAL,
    "IsTransferedToAcc" BOOLEAN,
    "TransactionDate" TIMESTAMP,
    "CreatedOn" TIMESTAMP,
    "CreatedBy" VARCHAR,
    "SettlementDiscountAmount" INT,
    "Remark" VARCHAR,
    "CreditOrganizationId" INT,
    "LedgerId" INT,
    "SubLedgerId" INT
) AS $$
BEGIN
    --change history
    /*
    sn.                auther/timestamp                   description
    1.                 devn/20th march 23                separated from sp_acc_bill_getbillingdataforacctransfer
    2.                 devn/19th may 23                  added subledgerid field in select statement.
    */
    -- exec sp_acc_bil_getcashinvoicereturndata '2023-03-20',3
    begin
    	RETURN QUERY SELECT billreturnitemid AS "BillingAccountingSyncId"
    		,itm.billreturnitemid AS "ReferenceId"
    		,'InvoiceReturnItem' AS "ReferenceModelName"
    		,servicedepartmentid
    		,serviceitemid AS "ItemId"
    		,itm.patientid
    		,'CashBillReturn' AS "TransactionType"
    		,'cash' AS "PaymentMode"
    		,itm.retsubtotal AS "SubTotal"
    		,itm.rettaxamount AS "TaxAmount"
    		,itm.retdiscountamount AS "DiscountAmount"
    		,0 AS "CoPaymentCashAmount"
    		,case 
    			when (txn.billstatus = 'paid')
    				then itm.retsubtotal
    			when (
    					txn.billstatus = 'unpaid'
    					and coalesce(txn.returncashamount, 0) != 0
    					)
    				then (txn.returncashamount / txn.totalamount) * itm.rettotalamount --since we do not have itemlevel copayment we have break it down into percent and then amount, sud/krishna, 22feb'23
    			END AS "TotalAmount"
    		--,itm.RetTotalAmount AS "TotalAmount"
    		,0 AS "IsTransferedToAcc"
    		,txn.CreatedOn AS "TransactionDate"
    		,CURRENT_TIMESTAMP AS "CreatedOn"
    		,txn.CreatedBy AS "CreatedBy"
    		,0 AS "SettlementDiscountAmount"
    		,NULL AS "Remark"
    		,NULL AS "CreditOrganizationId"
    		,(
    			SELECT FN_ACC_GetIncomeLedgerId(ServiceDepartmentId, ServiceItemId, p_hospitalid)
    			) AS "LedgerId"
    		,(SELECT "FN_ACC_GetIncomeSubLedgerId"(ServiceDepartmentId, ServiceItemId, p_hospitalid)) AS "SubLedgerId"
    	FROM BIL_TXN_InvoiceReturnItems itm
    		,BIL_TXN_InvoiceReturn txn
    	WHERE txn.BillReturnId = itm.BillReturnId
    		AND (txn.CreatedOn)::DATE = p_transactiondate
    		--and  ( txn.PaymentMode='cash' OR txn.PaymentMode='card' OR txn.PaymentMode='cheque' OR (txn.PaymentMode ='credit'and itm.BillStatus='paid'))  ---we considering all payment mode as cash , except credit
    		AND (
    			txn.BillStatus = 'paid'
    			OR (
    				txn.BillStatus = 'unpaid'
    				AND COALESCE(txn.ReturnCashAmount, 0) != 0
    				)
    			)
    		--Sud/Krishna, 22Feb'23, we have added a condition for unpaid billstatus as well to get copayment cash as well
    		and coalesce(itm.iscashbillsynctoacc, 0) = 0; -- include only not-synced data for cashbill return case--	
    end;
END;
$$ LANGUAGE plpgsql;