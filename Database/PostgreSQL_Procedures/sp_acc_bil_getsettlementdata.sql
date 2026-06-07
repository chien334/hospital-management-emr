CREATE OR REPLACE FUNCTION sp_acc_bil_getsettlementdata(
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
    -- exec sp_acc_bil_getsettlementdata '2023-03-20',3
    
    	RETURN QUERY SELECT settl.settlementid AS "BillingAccountingSyncId"
    		,settl.settlementid AS "ReferenceId"
    		,---4th-feb bikash, now settlementid taken AS "ReferenceId" as issynctoacc flag is in settlement table  
    		'CreditBillPaid' AS "ReferenceModelName"
    		,0 AS "ServiceDepartmentId"
    		,0 AS "ItemId"
    		,settl.patientid
    		,'CreditBillPaid' AS "TransactionType"
    		,settl.paymentmode
    		,0 AS "SubTotal"
    		,0 AS "TaxAmount"
    		,0 AS "DiscountAmount"
    		,0 AS "CoPaymentCashAmount"
    		,settl.collectionfromreceivable AS "TotalAmount"
    		,0 AS "IsTransferedToAcc"
    		,settl.createdon AS "TransactionDate"
    		,-- this is settlement date.. 
    		current_timestamp AS "CreatedOn"
    		,settl.createdby AS "CreatedBy"
    		,coalesce(settl.discountamount,0) AS "SettlementDiscountAmount"
    		,null AS "Remark"
    		,settl.organizationid AS "CreditOrganizationId"
    		,0 AS "LedgerId"
    		,0 AS "SubLedgerId"
    	from bil_txn_settlements settl
    	where (settl.settlementdate)::date = p_transactiondate
    		and coalesce(settl.discountreturnamount, 0) = 0 -- not including discount return case
    		-- and  ( settl.paymentmode='cash' or settl.paymentmode='card' or settl.paymentmode='cheque') 
    		and coalesce(settl.issynctoacc, 0) = 0; -- include only not-synced data for creditbillpaid case--
END;
$$ LANGUAGE plpgsql;