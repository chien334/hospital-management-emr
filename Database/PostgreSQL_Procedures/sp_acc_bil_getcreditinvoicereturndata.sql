CREATE OR REPLACE FUNCTION sp_acc_bil_getcreditinvoicereturndata(
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
    --exec sp_acc_bil_getcreditinvoicereturndata '2023-01-10',3
    
    	RETURN QUERY SELECT itm.billreturnitemid AS "BillingAccountingSyncId"
    		,billreturnitemid AS "ReferenceId"
    		,'InvoiceReturnItem' AS "ReferenceModelName"
    		,servicedepartmentid
    		,serviceitemid AS "ItemId"
    		,itm.patientid
    		,'CreditBillReturn' AS "TransactionType"
    		,txn.paymentmode AS "PaymentMode"
    		,itm.retsubtotal AS "SubTotal"
    		,itm.rettaxamount AS "TaxAmount"
    		,itm.retdiscountamount AS "DiscountAmount"
    		,0 AS "CoPaymentCashAmount"
    		,itm.retsubtotal AS "TotalAmount"
    		,0 AS "IsTransferedToAcc"
    		,txn.createdon AS "TransactionDate"
    		,current_timestamp AS "CreatedOn"
    		,txn.createdby AS "CreatedBy"
    		,0 AS "SettlementDiscountAmount"
    		,null AS "Remark"
    		,biltxn.organizationid AS "CreditOrganizationId"
    		,(
    			select fn_acc_getincomeledgerid(servicedepartmentid, serviceitemid, p_hospitalid)
    			) AS "LedgerId"
    		,(select "fn_acc_getincomesubledgerid"(servicedepartmentid, serviceitemid, p_hospitalid)) AS "SubLedgerId"
    	from bil_txn_invoicereturnitems itm
    		,bil_txn_invoicereturn txn
    		,bil_txn_billingtransaction biltxn
    	where txn.billreturnid = itm.billreturnid
    		and txn.billingtransactionid = biltxn.billingtransactionid
    		and (txn.createdon)::date = p_transactiondate
    		and itm.billstatus = 'unpaid' --and txn.paymentmode='credit' w
    		and coalesce(itm.iscreditbillsynctoacc, 0) = 0; -- include only not-synced data for credit return case--
END;
$$ LANGUAGE plpgsql;