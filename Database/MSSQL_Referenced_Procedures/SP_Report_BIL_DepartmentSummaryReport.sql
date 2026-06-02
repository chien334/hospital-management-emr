CREATE PROCEDURE [dbo].[SP_Report_BIL_DepartmentSummaryReport]
	@FromDate Date=null ,
	@ToDate Date=null,
	@billingType varchar(20)='all' 
-- available values: all, insurance, normal
AS
/*FileName: [SP_Report_BIL_DepartmentSummerrReport]
CreatedBy/date: Pratik:14Nov'21
Remarks:
Change History
S.No.    UpdatedBy/Date          Remarks
1.      Pratik:14Nov'21            inital Draft
2.      Krishna:20thFeb'23         Update Settlement info (CollectionFromReceivable and Settlement Discount)
*/
BEGIN
DECLARE @IsInsurance BIT; 
	IF(LOWER(@billingType)='insurance')
BEGIN 
	SET @IsInsurance = 1;
END
ELSE IF(LOWER(@billingType)='normal')
BEGIN 
	SET @IsInsurance = 0;
END
ELSE IF(LOWER(@billingType)='all')
BEGIN 
	SET @IsInsurance = NULL;
END
SELECT     
	ServDeptName,    
	SUM(ISNULL(CashSales,0)) CashSales,    
	SUM(ISNULL(CashDiscount,0)) CashDiscount,    
	SUM(ISNULL(CreditSales, 0)) CreditSales,    
	SUM(ISNULL(CreditDiscount,0)) CreditDiscount,    
	SUM(ISNULL(GrossSales,0)) GrossSales,    
	SUM(ISNULL(TotalDiscount, 0)) TotalDiscount,    
	SUM(ISNULL(ReturnCashSales, 0)) ReturnCashSales,    
	SUM(ISNULL(ReturnCashDiscount,0)) ReturnCashDiscount,    
	SUM(ISNULL(ReturnCreditSales,0)) ReturnCreditSales,    
	SUM(ISNULL(ReturnCreditDiscount,0)) ReturnCreditDiscount,    
	SUM(ISNULL(TotalSalesReturn,0)) TotalSalesReturn,    
	SUM(ISNULL(TotalReturnDiscount,0)) TotalReturnDiscount,    
	SUM(ISNULL(NetSales,0)) NetSales,    
	SUM(ISNULL(SaleQuantity,0)) 'TotalSaleQuantity',    
	SUM(ISNULL(ReturnQuantity,0)) 'TotalReturnQuantity',    
	SUM(ISNULL(SaleQuantity,0)-ISNULL(ReturnQuantity,0)) 'NetQuantity'    
FROM    
(    
SELECT 
	Convert(Date,txn.CreatedOn) 'BillingDate',    
	srv.ServiceDepartmentName AS ServDeptName,    
	CASE WHEN txn.PaymentMode !='credit' THEN  itm.SubTotal ELSE 0 END AS CashSales,    
	CASE WHEN txn.PaymentMode !='credit' THEN  itm.DiscountAmount ELSE 0 END AS CashDiscount,    
	CASE WHEN txn.PaymentMode ='credit' THEN  itm.SubTotal ELSE 0 END AS CreditSales,    
	CASE WHEN txn.PaymentMode ='credit' THEN  itm.DiscountAmount ELSE 0 END AS CreditDiscount,    
	itm.SubTotal AS GrossSales,    
	itm.DiscountAmount AS TotalDiscount,    
	0 AS ReturnCashSales,    0 AS ReturnCashDiscount,    
	0 AS ReturnCreditSales,    0 AS ReturnCreditDiscount,    
	0 AS TotalSalesReturn,    0 AS TotalReturnDiscount,    
	--Net Sales = Gross Sales - Total Discount - (Total Sales Return - Total Return Discount)    
	--here return is zero so we're calculating only sales part --    
	itm.SubTotal - itm.DiscountAmount AS 'NetSales',    
	itm.Quantity AS SaleQuantity,    
	0 AS ReturnQuantity
    
	FROM BIL_TXN_BillingTransaction txn
      INNER JOIN BIL_TXN_BillingTransactionItems itm
          ON txn.BillingTransactionId = itm.BillingTransactionId 
     INNER JOIN BIL_MST_ServiceDepartment srv
       ON itm.ServiceDepartmentId=srv.ServiceDepartmentId
    --WHERE ISNULL(txn.IsInsuranceBilling,0)=@IsInsurance      
	WHERE (ISNULL(@IsInsurance, ISNULL(txn.IsInsuranceBilling, 0)) = ISNULL(txn.IsInsuranceBilling, 0))   
	
UNION ALL    

SELECT 
	Convert(Date,ret.CreatedOn) 'ReturnDate',    
	srv.ServiceDepartmentName AS ServDeptName,    
	0 AS CashSales, 
	0 AS CashDiscount,    
	0 AS CreditSales,
	0 AS CreditDiscount,   
	0 AS GrossSales,    
	0 AS TotalDiscount,    
	CASE WHEN ret.PaymentMode != 'credit' THEN  retItm.RetSubTotal ELSE 0 END AS ReturnCashSales,    
	CASE WHEN ret.PaymentMode != 'credit' THEN  retItm.RetDiscountAmount ELSE 0 END AS ReturnCashDiscount,    
	CASE WHEN ret.PaymentMode = 'credit' THEN  retItm.RetSubTotal ELSE 0 END AS ReturnCreditSales,    
	CASE WHEN ret.PaymentMode = 'credit' THEN  retItm.RetDiscountAmount ELSE 0 END AS  ReturnCreditDiscount, retItm.RetSubTotal as TotalSalesReturn,    
	retItm.RetDiscountAmount AS TotalReturnDiscount,    
	--Net Sales = Gross Sales - Total Discount - (Total Sales Return - Total Return Discount)    
	--here return is zero so we're calculating only sales part --
	- (retItm.RetSubTotal - retItm.RetDiscountAmount) AS 'NetSales',     
	0 AS SaleQuantity,     
	retitm.RetQuantity 'ReturnQuantity'    
	FROM BIL_TXN_InvoiceReturn ret
      INNER JOIN BIL_TXN_InvoiceReturnItems retItm
          ON ret.BillReturnId = retItm.BillReturnId 
     INNER JOIN BIL_MST_ServiceDepartment srv
       ON retItm.ServiceDepartmentId=srv.ServiceDepartmentId
    --WHERE ISNULL(ret.IsInsuranceBilling,0)=@IsInsurance      
	WHERE (ISNULL(@IsInsurance, ISNULL(ret.IsInsuranceBilling, 0)) = ISNULL(ret.IsInsuranceBilling, 0))    
	) A
    WHERE A.BillingDate Between @FromDate AND @ToDate    
	GROUP BY ServDeptName
    ORDER BY ServDeptName

	SELECT 
	SUM(ISNULL(AdvanceReceived,0)) 'Tot_DepReceived',    
	SUM(ISNULL(AdvanceReturned,0)) 'Tot_DepReturned',    
	SUM(ISNULL(AdvanceSettled,0)) 'Tot_DepositDeduct'    
	FROM FN_BIL_GetDepositNProvisionalBetnDateRange(@FromDate,@ToDate)    
	
	--Select Sum(Isnull(PayableAmount,0)) 'CollectionFromRecivables',Sum(Isnull(DiscountAmount,0))'CashSettlementDiscount'    
	--From BIL_TXN_Settlements     
	--where CreatedOn between  @FromDate and @ToDate    
	--group by  CONVERT(date, CreatedOn)    

	--Krishna, 20thFeb'23, update Settlement info (CollectionFromReceivable and SettlementDiscount)    
	SELECT        
	SUM(ISNULL(CollectionFromReceivable,0)) 'CollectionFromRecivables',        
	SUM(ISNULL(DiscountAmount,0)) 'CashSettlementDiscount'    
	FROM BIL_TXN_Settlements
    WHERE CONVERT(DATE,CreatedOn) BETWEEN @FromDate AND @ToDate    
	GROUP BY CONVERT(DATE, CreatedOn)
END