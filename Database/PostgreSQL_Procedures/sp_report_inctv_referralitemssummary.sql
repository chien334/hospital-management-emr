CREATE OR REPLACE FUNCTION sp_report_inctv_referralitemssummary(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_employeeid INT DEFAULT NULL,
    p_isrefferalonly BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (
    "IncentiveReceiverName" VARCHAR,
    "TransactionDate" TIMESTAMP,
    "InvoiceNoFormatted" VARCHAR,
    "IncomeType" VARCHAR,
    "PatientId" INT,
    "PatientName" VARCHAR,
    "HospitalNum" VARCHAR,
    "ItemName" VARCHAR,
    "TotalAmount" DECIMAL,
    "FinalIncentivePercent" VARCHAR,
    "IncentiveAmount" DECIMAL,
    "TDSPercentage" VARCHAR,
    "IsReturnTxn" BOOLEAN,
    "SubTotal" DECIMAL,
    "DiscountAmount" INT,
    "TDSAmount" DECIMAL,
    "NetPayableAmt" VARCHAR,
    "InctvTxnItemId" INT,
    "IsPaymentProcessed" BOOLEAN,
    "PreviousAdjustedAmount" DECIMAL,
    "PriceCategoryId" INT,
    "PriceCategoryName" DECIMAL
) AS $$
BEGIN
    /*  
    author: pratik/20nov'19  
    Description: To get Incentive reports at items level for input doctor.  
    Change History-----  
    S.No. Date/Author					Remarks  
    1. 20Nov'19/pratik					initial draft  
    2. 12feb'20/Sud						TDS percent hardcoded for temporary purpose, need to revise it soon.  
    3. 25Feb'20/pratik					tds percentage is calculated from employee profile  
    4. 06aug'21/Aniket					Previous Adjusted Amount is added from INCTV_TXN_PaymentInfo  
    5. 24Aug'21/aniket					updated query, replaced right join with left join.  
    6. 09nov'21/Pratik					updated query, added return status, subtotal and discount amount of billing items  
    7. 22March'22/krishna				updated query to get previousadjustmentamount of specific employee (receiver)  
    8. 27apr'22/Krishna/Sud				Join with PaymentInfo removed since it's giving multiple records 
    									when there are multple payments made in past.  
    9. 23aug'22/Dev Narayan				Added filter IncentiveType = 'referral' for new Report ->'incentive referral summary'
    10.22ndSept'23/krishna				read pricecategory
    */  
      
     RETURN QUERY SELECT emp.fullname AS "IncentiveReceiverName",
    		incitm.transactiondate, 
    		incitm.invoicenoformatted, 
    		incitm.incentivetype AS "IncomeType", 
    		incitm.patientid, 
    		pat.firstname||' '||pat.lastname AS "PatientName",
    		pat.patientcode AS "HospitalNum", 
    		incitm.itemname,
    		incitm.totalbillamount AS "TotalAmount", 
    		incitm.finalincentivepercent, 
    		incitm.incentiveamount,
    		incitm.tdspercentage AS "TDSPercentage",
    		incitm.isreturntxn ,
    		txnitm.subtotal,txnitm.discountamount,  
    		--here tds percent is hard-coded, we need to add them to fractionitem table and calculate from there, 
    		--not from here--sud: 12feb'20  
    		incItm.TDSAmount AS "TDSAmount", 
    		incItm.IncentiveAmount - incItm.TDSAmount AS "NetPayableAmt", 
    		incItm.InctvTxnItemId,
    		incItm.IsPaymentProcessed,--,incItm.BillingTransactionId, incItm.BillingTransactionItemId  
      COALESCE((SELECT  AdjustedAmount   
       FROM INCTV_TXN_PaymentInfo p   
       WHERE p.ReceiverId = p_employeeid ORDER BY p.CreatedOn DESC LIMIT 1),0) AS "PreviousAdjustedAmount" ,
       priceCat.PriceCategoryId,
       priceCat.PriceCategoryName
      
     FROM INCTV_TXN_IncentiveFractionItem incItm  
     INNER JOIN PAT_Patient pat  
     ON incItm.PatientId=pat.PatientId  
    
     INNER JOIN EMP_Employee emp  
     ON incItm.IncentiveReceiverId=emp.EmployeeId  
     -- LEFT JOIN INCTV_TXN_PaymentInfo p  
     --ON incItm.IncentiveReceiverId = p.ReceiverId  
     INNER JOIN BIL_TXN_BillingTransactionItems txnitm  
     ON incItm.BillingTransactionItemId = txnitm.BillingTransactionItemId  
     INNER JOIN BIL_CFG_PriceCategory priceCat ON txnitm.PriceCategoryId = priceCat.PriceCategoryId
      
     WHERE  
      IncentiveReceiverId = p_employeeid  
      AND COALESCE(incItm.IsActive,0)=1  
      AND (incItm.TransactionDate)::Date BETWEEN p_fromdate AND p_todate  
      	 AND ((p_isrefferalonly = TRUE AND incItm.IncentiveType = 'referral')
    		or (p_isrefferalonly = false)
    	 );
END;
$$ LANGUAGE plpgsql;