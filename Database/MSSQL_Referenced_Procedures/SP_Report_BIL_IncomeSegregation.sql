CREATE PROCEDURE [dbo].[SP_Report_BIL_IncomeSegregation]
	@FromDate Date=null ,
	@ToDate Date=null,
	@billingType varchar(20)='all' -- available values: all, insurance, normal
AS
/*
FileName: [SP_Report_BIL_IncomeSegregation]
CreatedBy/date: Sud:5May'21
Description: to get the income head of different department and sales related data
Remarks:    
Change History
S.No.    UpdatedBy/Date				Remarks
1.      Sud:5May'21                Complete rewrite after new requirement and credit note in place. [JiraId:LPH-900]
2.      Sud:11Aug'21               Adding Quantity Fields and get billingtype as input parameter.
3.      Sud:26Aug'21               Removing Group Logic for ServiceDepartment Name. 
                                   Since it's different for different hospitals and hence creating confusions/issues.
*/
BEGIN

Declare @IsInsurance BIT;
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

Select 
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

	from 

	(
	SELECT Convert(Date,txn.CreatedOn) 'BillingDate',
	srv.ServiceDepartmentName AS ServDeptName,
	CASE WHEN txn.PaymentMode !='credit' THEN  itm.SubTotal ELSE 0 END AS CashSales, 
	CASE WHEN txn.PaymentMode !='credit' THEN  itm.DiscountAmount ELSE 0 END AS CashDiscount, 
	CASE WHEN txn.PaymentMode ='credit' THEN  itm.SubTotal ELSE 0 END AS CreditSales, 
	CASE WHEN txn.PaymentMode ='credit' THEN  itm.DiscountAmount ELSE 0 END AS CreditDiscount, 
	itm.SubTotal AS GrossSales,
	itm.DiscountAmount AS TotalDiscount,
	0 AS ReturnCashSales, 
	0 AS ReturnCashDiscount,
	0 AS ReturnCreditSales, 
	0 AS ReturnCreditDiscount, 
	0 AS TotalSalesReturn, 
	0 AS TotalReturnDiscount,
	--here return is zero so we're calculating only sales part --
	itm.SubTotal - itm.DiscountAmount AS 'NetSales',
	itm.Quantity AS SaleQuantity,
	0 AS ReturnQuantity

	from BIL_TXN_BillingTransaction txn
	  INNER JOIN BIL_TXN_BillingTransactionItems itm
		  ON txn.BillingTransactionId = itm.BillingTransactionId 
	 INNER JOIN BIL_MST_ServiceDepartment srv
	   ON itm.ServiceDepartmentId=srv.ServiceDepartmentId

	--WHERE ISNULL(txn.IsInsuranceBilling,0)=@IsInsurance
	  Where (ISNULL(@IsInsurance, ISNULL(txn.IsInsuranceBilling, 0)) = ISNULL(txn.IsInsuranceBilling, 0))

	UNION ALL
	SELECT Convert(Date,ret.CreatedOn) 'ReturnDate',
	srv.ServiceDepartmentName AS ServDeptName,
	0 AS CashSales, 0 AS CashDiscount,
	0 AS CreditSales,0 AS CreditDiscount,
	0 AS GrossSales,
	0 AS TotalDiscount,
	CASE WHEN ret.PaymentMode != 'credit' THEN  retItm.RetSubTotal ELSE 0 END AS ReturnCashSales, 
	CASE WHEN ret.PaymentMode != 'credit' THEN  retItm.RetDiscountAmount ELSE 0 END AS ReturnCashDiscount, 
	CASE WHEN ret.PaymentMode = 'credit' THEN  retItm.RetSubTotal ELSE 0 END AS ReturnCreditSales, 
	CASE WHEN ret.PaymentMode = 'credit' THEN  retItm.RetDiscountAmount ELSE 0 END AS ReturnCreditDiscount, 
	retItm.RetSubTotal as TotalSalesReturn,
	retItm.RetDiscountAmount AS TotalReturnDiscount,
	--here return is zero so we're calculating only sales part --
	- (retItm.RetSubTotal - retItm.RetDiscountAmount) AS 'NetSales',
	 0 AS SaleQuantity,
	 retitm.RetQuantity 'ReturnQuantity'

	from BIL_TXN_InvoiceReturn ret
	  INNER JOIN BIL_TXN_InvoiceReturnItems retItm
		  ON ret.BillReturnId = retItm.BillReturnId 
	 INNER JOIN BIL_MST_ServiceDepartment srv
	   ON retItm.ServiceDepartmentId=srv.ServiceDepartmentId

	--WHERE ISNULL(ret.IsInsuranceBilling,0)=@IsInsurance
	  Where (ISNULL(@IsInsurance, ISNULL(ret.IsInsuranceBilling, 0)) = ISNULL(ret.IsInsuranceBilling, 0))
	) A

	Where A.BillingDate Between @FromDate AND @ToDate
	Group by ServDeptName
	Order by ServDeptName

	--Select Sum(Isnull(AdvanceReceived,0)) 'Tot_DepReceived',
	--Sum(Isnull(AdvanceSettled,0)) 'Tot_DepSettled'
	--From FN_BIL_GetDepositNProvisionalBetnDateRange(@FromDate,@ToDate)

End