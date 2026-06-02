CREATE PROCEDURE [dbo].[SP_Report_BILL_SalesDaybook]
	  @FromDate Date=null,
	  @ToDate Date=null,
	  @IsInsurance bit=0
AS
/*
--[SP_Report_BILL_SalesDaybook] '2018-08-18','2018-08-18'
FileName: [SP_Report_BILL_SalesDaybook]
CreatedBy/date: nagesh/2017-05-25
Description: to get the total of Billed, Unbilled, and Returned along with the total cash collection
Remarks:    We're querying same table multiple times here, check if we can do it in a better way.
       : Need to check again for CashDiscount and Trade Discount
	   : Apply date filter in each sub-query as well--
	   : totalAmount equals be TotalAmount-ReturnAmount in all cases---
Change History
S.No.    UpdatedBy/Date                                            Remarks
1       nagesh/umed/dinesh from May2017 to Nov2017	      created the script
2.      sud: 27May'18                                     modified as per new table designs      
3.      sud: 19Aug'18                                     Re-calculation for TotalAmount in Return Case. 
4.      sud: 6Aug'19                                      Added parameter for Insurance
5.		sud/Dhanashri: 27Sep'21							  If PaymentMode=Credit then that goes as Credit Sales no matter if it was paid on the same day
														  We're taking Only PaidAmount from Settlement
*/
BEGIN
 
     SELECT  d.BillingDate, 
	ISNULL(sales.CashSubtotal,0) Paid_SubTotal,
	ISNULL(sales.CashDiscount,0) Paid_DiscountAmount,
	ISNULL(sales.CashTotalAmount,0) Paid_TotalAmount,
	ISNULL(sales.CreditSubtotal,0)  CrSales_SubTotal,
	ISNULL(sales.CreditDiscount,0) CrSales_DiscountAmount,
	ISNULL(sales.CreditTotalAmount,0) CrSales_TotalAmount,
	ISNULL(retSales.Return_CashSubtotal,0) AS CashRet_SubTotal,
	ISNULL(retSales.Return_CashDiscount,0) AS CashRet_DiscountAmount,
	ISNULL(retSales.Return_CashTotalAmount,0) AS CashRet_TotalAmount,
	ISNULL(retSales.Return_CreditSubtotal,0) AS CrRet_SubTotal,
	ISNULL(retSales.Return_CreditDiscount,0) AS CrRet_DiscountAmount,
	ISNULL(retSales.Return_CreditTotalAmount,0) AS CrRet_TotalAmount,
	ISNULL(sett.Settl_PaidAmount,0) AS 'CreditReceivedAmount',
	ISNULL(dep.DepositReceived,0) AS DepositReceived,
	ISNULL(dep.DepositDeducted,0) AS DepositDeducted,
	ISNULL(dep.DepositRefund,0) AS DepositRefund,
	ISNULL(sales.CashSubtotal,0)+ISNULL(sales.CreditSubtotal,0) 'SubTotal',
	ISNULL(sales.CashDiscount,0)+ISNULL(sales.CreditDiscount,0) 'DiscountAmount',
	ISNULL(retSales.Return_CashSubtotal,0)+ISNULL(retSales.Return_CreditSubtotal,0) 'TotalSalesReturn',
	ISNULL(retSales.Return_CashDiscount,0)+ISNULL(retSales.Return_CreditDiscount,0) 'TotalReturnDiscount',
	ISNULL(sales.CashTotalAmount,0)+ISNULL(sales.CreditTotalAmount,0) - (ISNULL(retSales.Return_CashTotalAmount,0)+ISNULL(retSales.Return_CreditTotalAmount,0)) 'TotalAmount',
	ISNULL(sales.CashTotalAmount,0) - ISNULL(retSales.Return_CashTotalAmount,0) 
	   + ISNULL(dep.DepositReceived,0) - ISNULL(dep.DepositDeducted,0) - ISNULL(dep.DepositRefund,0)
	   + ISNULL(sett.Settl_PaidAmount,0) 'CashCollection'
FROM 
(
  SELECT Dates 'BillingDate' 
  FROM [FN_COMMON_GetAllDatesBetweenRange] (ISNULL(@FromDate,GETDATE()),ISNULL(@ToDate,GETDATE()))
) d 
LEFT JOIN 
 (
   --Cash Sales Information
  --Credit Sales Informations
  Select Convert(date,txn.CreatedOn) 'BillingDate',
      SUM( 
	    CASE WHEN PaymentMode='cash' THEN ISNULL(txn.SubTotal,0)
	    ELSE 0 END
		) 'CashSubtotal' ,
      SUM( 
	    CASE WHEN PaymentMode='cash' THEN ISNULL(txn.DiscountAmount,0)
	    ELSE 0 END
		) 'CashDiscount' ,
      SUM( 
	    CASE WHEN PaymentMode='cash' THEN ISNULL(txn.TotalAmount,0)
	    ELSE 0 END
		) 'CashTotalAmount' ,

      SUM( 
	    CASE WHEN PaymentMode='credit' THEN ISNULL(txn.SubTotal,0)
	    ELSE 0 END
		) 'CreditSubtotal' ,
      SUM( 
	    CASE WHEN PaymentMode='credit' THEN ISNULL(txn.DiscountAmount,0)
	    ELSE 0 END
		) 'CreditDiscount' ,
      SUM( 
	    CASE WHEN PaymentMode='credit' THEN ISNULL(txn.TotalAmount,0)
	    ELSE 0 END
		) 'CreditTotalAmount' 

  FROM BIL_TXN_BillingTransaction txn 
  WHERE  ---txn.PaymentMode = 'cash'
         Convert(Date,txn.CreatedOn) BETWEEN @FromDate and @ToDate
  Group by Convert(Date,txn.CreatedOn)
) sales 
ON d.BillingDate = sales.BillingDate


  --Cash Return Information
  --Credit Return Information
LEFT JOIN
(
  Select Convert(date,ret.CreatedOn) 'BillingDate',
      SUM( 
	    CASE WHEN PaymentMode='cash' THEN ISNULL(ret.SubTotal,0)
	    ELSE 0 END
		) 'Return_CashSubtotal' ,
      SUM( 
	    CASE WHEN PaymentMode='cash' THEN ISNULL(ret.DiscountAmount,0)
	    ELSE 0 END
		) 'Return_CashDiscount',
      SUM( 
	    CASE WHEN PaymentMode='cash' THEN ISNULL(ret.TotalAmount,0)
	    ELSE 0 END
		) 'Return_CashTotalAmount' ,

      SUM( 
	    CASE WHEN PaymentMode='credit' THEN ISNULL(ret.SubTotal,0)
	    ELSE 0 END
		) 'Return_CreditSubtotal' ,
      SUM( 
	    CASE WHEN PaymentMode='credit' THEN ISNULL(ret.DiscountAmount,0)
	    ELSE 0 END
		) 'Return_CreditDiscount' ,
      SUM( 
	    CASE WHEN PaymentMode='credit' THEN ISNULL(ret.TotalAmount,0)
	    ELSE 0 END
		) 'Return_CreditTotalAmount' 

  FROM BIL_TXN_InvoiceReturn ret 
  WHERE Convert(Date,ret.CreatedOn) BETWEEN @FromDate and @ToDate
  Group by Convert(Date,ret.CreatedOn)
) retSales  ON d.BillingDate = retSales.BillingDate


--Settement> Cash Discount Information
LEFT JOIN 
(
Select Convert(date,sett.SettlementDate) 'BillingDate',
         SUM(ISNULL(sett.PaidAmount,0) ) 'Settl_PaidAmount'
from BIL_TXN_Settlements sett 
GROUP BY Convert(date,sett.SettlementDate)
) sett ON d.BillingDate = sett.BillingDate

 --Deposit Informations
LEFT JOIN
(
  Select Convert(date,dep.CreatedOn) 'BillingDate',
      SUM( Case WHEN dep.DepositType='Deposit' then ISNULL(dep.Amount,0) ELSE 0 END ) AS 'DepositReceived',
      SUM( Case WHEN dep.DepositType='depositdeduct' then ISNULL(dep.Amount,0) ELSE 0  END) AS 'DepositDeducted',
      SUM( Case WHEN dep.DepositType='ReturnDeposit' then ISNULL(dep.Amount,0) ELSE 0  END) AS 'DepositRefund'  
  from BIL_TXN_Deposit dep
  Where Convert(date,dep.CreatedOn) BETWEEN @FromDate and @ToDate
  Group BY Convert(date,dep.CreatedOn)
) dep ON d.BillingDate = dep.BillingDate

order by d.BillingDate
END