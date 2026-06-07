CREATE OR REPLACE FUNCTION sp_acc_bil_getdepositreturndata(
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
    -- exec sp_acc_bil_getdepositreturndata '2023-03-20',3
    
    	RETURN QUERY SELECT depositid AS "BillingAccountingSyncId"
    		,depositid AS "ReferenceId"
    		,'Deposit' AS "ReferenceModelName"
    		,0 AS "ServiceDepartmentId"
    		,0 AS "ItemId"
    		,patientid
    		,'DepositReturn' AS "TransactionType"
    		,
    		--	 paymentmode AS "PaymentMode", --nbb: 16jul20-card payment not handle yet
    		'cash' AS "PaymentMode"
    		,0 AS "SubTotal"
    		,0 AS "TaxAmount"
    		,0 AS "DiscountAmount"
    		,0 AS "CoPaymentCashAmount"
    		,outamount AS "TotalAmount"
    		,0 AS "IsTransferedToAcc"
    		,createdon AS "TransactionDate"
    		,current_timestamp AS "CreatedOn"
    		,createdby AS "CreatedBy"
    		,0 AS "SettlementDiscountAmount"
    		,null AS "Remark"
    		,0 AS "CreditOrganizationId"
    		,0 AS "LedgerId"
    		,0 AS "SubLedgerId"
    	from bil_txn_deposit
    	where (createdon)::date = p_transactiondate
    		and transactiontype = 'ReturnDeposit'
    		and coalesce(isdepositsync, 0) = 0; -- include only not-synced data
END;
$$ LANGUAGE plpgsql;