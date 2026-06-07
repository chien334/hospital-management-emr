CREATE OR REPLACE FUNCTION sp_report_bill_salesdaybook(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_isinsurance BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (
    "BillingDate" TIMESTAMP,
    "Paid_SubTotal" INT,
    "Paid_DiscountAmount" INT,
    "Paid_TotalAmount" INT,
    "CrSales_SubTotal" DECIMAL,
    "CrSales_DiscountAmount" INT,
    "CrSales_TotalAmount" DECIMAL,
    "CashRet_SubTotal" DECIMAL,
    "CashRet_DiscountAmount" INT,
    "CashRet_TotalAmount" DECIMAL,
    "CrRet_SubTotal" DECIMAL,
    "CrRet_DiscountAmount" INT,
    "CrRet_TotalAmount" DECIMAL,
    "CreditReceivedAmount" DECIMAL,
    "DepositReceived" VARCHAR,
    "DepositDeducted" VARCHAR,
    "DepositRefund" VARCHAR,
    "SubTotal" DECIMAL,
    "DiscountAmount" INT,
    "TotalSalesReturn" DECIMAL,
    "TotalReturnDiscount" INT,
    "TotalAmount" DECIMAL,
    "CashCollection" TIMESTAMP
) AS $$
BEGIN
    /*
    --"sp_report_bill_salesdaybook" '2018-08-18','2018-08-18'
    filename: "sp_report_bill_salesdaybook"
    createdby/date: nagesh/2017-05-25
    description: to get the total of billed, unbilled, and returned along with the total cash collection
    remarks:    we're querying same table multiple times here, check if we can do it in a better way.
           : Need to check again for CashDiscount and Trade Discount
    	   : Apply date filter in each sub-query as well--
    	   : totalAmount equals be TotalAmount-ReturnAmount in all cases---
    Change History
    S.No.    UpdatedBy/Date                                            Remarks
    1       nagesh/umed/dinesh from May2017 to Nov2017	      created the script
    2.      sud: 27May'18                                     modified as per new table designs      
    3.      sud: 19aug'18                                     Re-calculation for TotalAmount in Return Case. 
    4.      sud: 6Aug'19                                      added parameter for insurance
    5.		sud/dhanashri: 27sep'21							  If PaymentMode=Credit then that goes as Credit Sales no matter if it was paid on the same day
    														  We're taking only paidamount from settlement
    */
    
     
         RETURN QUERY SELECT  d.billingdate, 
    	coalesce(sales.cashsubtotal,0) AS "Paid_SubTotal",
    	coalesce(sales.cashdiscount,0) AS "Paid_DiscountAmount",
    	coalesce(sales.cashtotalamount,0) AS "Paid_TotalAmount",
    	coalesce(sales.creditsubtotal,0)  AS "CrSales_SubTotal",
    	coalesce(sales.creditdiscount,0) AS "CrSales_DiscountAmount",
    	coalesce(sales.credittotalamount,0) AS "CrSales_TotalAmount",
    	coalesce(retsales.return_cashsubtotal,0) AS "CashRet_SubTotal",
    	coalesce(retsales.return_cashdiscount,0) AS "CashRet_DiscountAmount",
    	coalesce(retsales.return_cashtotalamount,0) AS "CashRet_TotalAmount",
    	coalesce(retsales.return_creditsubtotal,0) AS "CrRet_SubTotal",
    	coalesce(retsales.return_creditdiscount,0) AS "CrRet_DiscountAmount",
    	coalesce(retsales.return_credittotalamount,0) AS "CrRet_TotalAmount",
    	coalesce(sett.settl_paidamount,0) AS "CreditReceivedAmount",
    	coalesce(dep.depositreceived,0) AS "DepositReceived",
    	coalesce(dep.depositdeducted,0) AS "DepositDeducted",
    	coalesce(dep.depositrefund,0) AS "DepositRefund",
    	coalesce(sales.cashsubtotal,0)+coalesce(sales.creditsubtotal,0) AS "SubTotal",
    	coalesce(sales.cashdiscount,0)+coalesce(sales.creditdiscount,0) AS "DiscountAmount",
    	coalesce(retsales.return_cashsubtotal,0)+coalesce(retsales.return_creditsubtotal,0) AS "TotalSalesReturn",
    	coalesce(retsales.return_cashdiscount,0)+coalesce(retsales.return_creditdiscount,0) AS "TotalReturnDiscount",
    	coalesce(sales.cashtotalamount,0)+coalesce(sales.credittotalamount,0) - (coalesce(retsales.return_cashtotalamount,0)+coalesce(retsales.return_credittotalamount,0)) AS "TotalAmount",
    	coalesce(sales.cashtotalamount,0) - coalesce(retsales.return_cashtotalamount,0) 
    	   + coalesce(dep.depositreceived,0) - coalesce(dep.depositdeducted,0) - coalesce(dep.depositrefund,0)
    	   + coalesce(sett.settl_paidamount,0) AS "CashCollection"
    from 
    (
      select dates AS "BillingDate" 
      from "fn_common_getalldatesbetweenrange" (coalesce(p_fromdate,current_timestamp),coalesce(p_todate,current_timestamp))
    ) d 
    left join 
     (
       --cash sales information
      --credit sales informations
      select (txn.createdon)::date AS "BillingDate",
          sum( 
    	    case when paymentmode='cash' then coalesce(txn.subtotal,0)
    	    else 0 end
    		) as "cashsubtotal" ,
          sum( 
    	    case when paymentmode='cash' then coalesce(txn.discountamount,0)
    	    else 0 end
    		) as "cashdiscount" ,
          sum( 
    	    case when paymentmode='cash' then coalesce(txn.totalamount,0)
    	    else 0 end
    		) as "cashtotalamount" ,
    
          sum( 
    	    case when paymentmode='credit' then coalesce(txn.subtotal,0)
    	    else 0 end
    		) as "creditsubtotal" ,
          sum( 
    	    case when paymentmode='credit' then coalesce(txn.discountamount,0)
    	    else 0 end
    		) as "creditdiscount" ,
          sum( 
    	    case when paymentmode='credit' then coalesce(txn.totalamount,0)
    	    else 0 end
    		) as "credittotalamount" 
    
      from bil_txn_billingtransaction txn 
      where  ---txn.paymentmode = 'cash'
             (txn.createdon)::date between p_fromdate and p_todate
      group by (txn.createdon)::date
    ) sales 
    on d.billingdate = sales.billingdate
    
    
      --cash return information
      --credit return information
    left join
    (
      select (ret.createdon)::date AS "BillingDate",
          sum( 
    	    case when paymentmode='cash' then coalesce(ret.subtotal,0)
    	    else 0 end
    		) as "return_cashsubtotal" ,
          sum( 
    	    case when paymentmode='cash' then coalesce(ret.discountamount,0)
    	    else 0 end
    		) as "return_cashdiscount",
          sum( 
    	    case when paymentmode='cash' then coalesce(ret.totalamount,0)
    	    else 0 end
    		) as "return_cashtotalamount" ,
    
          sum( 
    	    case when paymentmode='credit' then coalesce(ret.subtotal,0)
    	    else 0 end
    		) as "return_creditsubtotal" ,
          sum( 
    	    case when paymentmode='credit' then coalesce(ret.discountamount,0)
    	    else 0 end
    		) as "return_creditdiscount" ,
          sum( 
    	    case when paymentmode='credit' then coalesce(ret.totalamount,0)
    	    else 0 end
    		) as "return_credittotalamount" 
    
      from bil_txn_invoicereturn ret 
      where (ret.createdon)::date between p_fromdate and p_todate
      group by (ret.createdon)::date
    ) retsales  on d.billingdate = retsales.billingdate
    
    
    --settement> cash discount information
    left join 
    (
    select (sett.settlementdate)::date AS "BillingDate",
             sum(coalesce(sett.paidamount,0) ) as "settl_paidamount"
    from bil_txn_settlements sett 
    group by (sett.settlementdate)::date
    ) sett on d.billingdate = sett.billingdate
    
     --deposit informations
    left join
    (
      select (dep.createdon)::date AS "BillingDate",
          sum( case when dep.deposittype='Deposit' then coalesce(dep.amount,0) else 0 end ) AS "DepositReceived",
          sum( case when dep.deposittype='depositdeduct' then coalesce(dep.amount,0) else 0  end) AS "DepositDeducted",
          sum( case when dep.deposittype='ReturnDeposit' then coalesce(dep.amount,0) else 0  end) AS "DepositRefund"  
      from bil_txn_deposit dep
      where (dep.createdon)::date between p_fromdate and p_todate
      group by (dep.createdon)::date
    ) dep on d.billingdate = dep.billingdate
    
    order by d.billingdate;
END;
$$ LANGUAGE plpgsql;