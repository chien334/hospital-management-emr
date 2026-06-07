CREATE OR REPLACE FUNCTION sp_report_bil_departmentsummaryreport(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_billingtype VARCHAR DEFAULT 'all'
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
    ref3 refcursor := 'cursor3';
    v_isinsurance BOOLEAN;
BEGIN
    /*filename: "sp_report_bil_departmentsummerrreport"
    createdby/date: pratik:14nov'21
    Remarks:
    Change History
    S.No.    UpdatedBy/Date          Remarks
    1.      Pratik:14Nov'21            inital draft
    2.      krishna:20thfeb'23         Update Settlement info (CollectionFromReceivable and Settlement Discount)
    */
    BEGIN
     
    	IF(LOWER(p_billingtype)='insurance')
    THEN 
    	v_isinsurance := 1;
    
    ELSIF(LOWER(p_billingtype)='normal')
    THEN 
    	v_isinsurance := 0;
    
    ELSIF(LOWER(p_billingtype)='all')
    THEN 
    	v_isinsurance := NULL;
    END IF;
    OPEN ref1 FOR SELECT     
    	ServDeptName,    
    	SUM(COALESCE(CashSales,0)) AS "CashSales",    
    	SUM(COALESCE(CashDiscount,0)) AS "CashDiscount",    
    	SUM(COALESCE(CreditSales, 0)) AS "CreditSales",    
    	SUM(COALESCE(CreditDiscount,0)) AS "CreditDiscount",    
    	SUM(COALESCE(GrossSales,0)) AS "GrossSales",    
    	SUM(COALESCE(TotalDiscount, 0)) AS "TotalDiscount",    
    	SUM(COALESCE(ReturnCashSales, 0)) AS "ReturnCashSales",    
    	SUM(COALESCE(ReturnCashDiscount,0)) AS "ReturnCashDiscount",    
    	SUM(COALESCE(ReturnCreditSales,0)) AS "ReturnCreditSales",    
    	SUM(COALESCE(ReturnCreditDiscount,0)) AS "ReturnCreditDiscount",    
    	SUM(COALESCE(TotalSalesReturn,0)) AS "TotalSalesReturn",    
    	SUM(COALESCE(TotalReturnDiscount,0)) AS "TotalReturnDiscount",    
    	SUM(COALESCE(NetSales,0)) AS "NetSales",    
    	SUM(COALESCE(SaleQuantity,0)) AS "TotalSaleQuantity",    
    	SUM(COALESCE(ReturnQuantity,0)) AS "TotalReturnQuantity",    
    	SUM(COALESCE(SaleQuantity,0)-COALESCE(ReturnQuantity,0)) AS "NetQuantity"    
    FROM    
    (    
    SELECT 
    	(txn.CreatedOn)::Date AS "BillingDate",    
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
    	itm.subtotal - itm.discountamount as "netsales",    
    	itm.quantity as salequantity,    
    	0 as returnquantity
        
    	from bil_txn_billingtransaction txn
          inner join bil_txn_billingtransactionitems itm
              on txn.billingtransactionid = itm.billingtransactionid 
         inner join bil_mst_servicedepartment srv
           on itm.servicedepartmentid=srv.servicedepartmentid
        --where coalesce(txn.isinsurancebilling,0)=v_isinsurance      
    	where (coalesce(v_isinsurance, coalesce(txn.isinsurancebilling, 0)) = coalesce(txn.isinsurancebilling, 0))   
    	
    union all    
    
    select 
    	(ret.createdon)::date as "returndate",    
    	srv.servicedepartmentname as servdeptname,    
    	0 as cashsales, 
    	0 as cashdiscount,    
    	0 as creditsales,
    	0 as creditdiscount,   
    	0 as grosssales,    
    	0 as totaldiscount,    
    	case when ret.paymentmode != 'credit' then  retitm.retsubtotal else 0 end as returncashsales,    
    	case when ret.paymentmode != 'credit' then  retitm.retdiscountamount else 0 end as returncashdiscount,    
    	case when ret.paymentmode = 'credit' then  retitm.retsubtotal else 0 end as returncreditsales,    
    	case when ret.paymentmode = 'credit' then  retitm.retdiscountamount else 0 end as  returncreditdiscount, retitm.retsubtotal as totalsalesreturn,    
    	retitm.retdiscountamount as totalreturndiscount,    
    	--net sales = gross sales - total discount - (total sales return - total return discount)    
    	--here return is zero so we're calculating only sales part --
    	- (retItm.RetSubTotal - retItm.RetDiscountAmount) AS "NetSales",     
    	0 AS SaleQuantity,     
    	retitm.RetQuantity AS "ReturnQuantity"    
    	FROM BIL_TXN_InvoiceReturn ret
          INNER JOIN BIL_TXN_InvoiceReturnItems retItm
              ON ret.BillReturnId = retItm.BillReturnId 
         INNER JOIN BIL_MST_ServiceDepartment srv
           ON retItm.ServiceDepartmentId=srv.ServiceDepartmentId
        --WHERE COALESCE(ret.IsInsuranceBilling,0)=v_isinsurance      
    	WHERE (COALESCE(v_isinsurance, COALESCE(ret.IsInsuranceBilling, 0)) = COALESCE(ret.IsInsuranceBilling, 0))    
    	) A
        WHERE A.BillingDate Between p_fromdate AND p_todate    
    	GROUP BY ServDeptName
        ORDER BY ServDeptName;
        RETURN NEXT ref1;
    
    	OPEN ref2 FOR SELECT 
    	SUM(COALESCE(AdvanceReceived,0)) AS "Tot_DepReceived",    
    	SUM(COALESCE(AdvanceReturned,0)) AS "Tot_DepReturned",    
    	SUM(COALESCE(AdvanceSettled,0)) AS "Tot_DepositDeduct"    
    	FROM FN_BIL_GetDepositNProvisionalBetnDateRange(p_fromdate,p_todate);
        RETURN NEXT ref2;    
    	
    	--Select Sum(COALESCE(PayableAmount,0)) 'collectionfromrecivables',Sum(COALESCE(DiscountAmount,0))'cashsettlementdiscount'    
    	--From BIL_TXN_Settlements     
    	--where CreatedOn between  p_fromdate and p_todate    
    	--group by  CONVERT(date, CreatedOn)    
    
    	--Krishna, 20thFeb'23, update settlement info (collectionfromreceivable and settlementdiscount)    
    	open ref3 for select        
    	sum(coalesce(collectionfromreceivable,0)) as "collectionfromrecivables",        
    	sum(coalesce(discountamount,0)) as "cashsettlementdiscount"    
    	from bil_txn_settlements
        where (createdon)::date between p_fromdate and p_todate    
    	group by (createdon)::date;
        return next ref3;
    end;
END;
$$ LANGUAGE plpgsql;