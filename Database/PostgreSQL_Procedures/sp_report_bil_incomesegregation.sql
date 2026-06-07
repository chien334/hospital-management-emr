CREATE OR REPLACE FUNCTION sp_report_bil_incomesegregation(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_billingtype VARCHAR DEFAULT 'all'
)
RETURNS TABLE (
    "ServDeptName" VARCHAR,
    "CashSales" VARCHAR,
    "CashDiscount" INT,
    "CreditSales" VARCHAR,
    "CreditDiscount" INT,
    "GrossSales" VARCHAR,
    "TotalDiscount" INT,
    "ReturnCashSales" VARCHAR,
    "ReturnCashDiscount" INT,
    "ReturnCreditSales" VARCHAR,
    "ReturnCreditDiscount" INT,
    "TotalSalesReturn" DECIMAL,
    "TotalReturnDiscount" INT,
    "NetSales" VARCHAR,
    "TotalSaleQuantity" INT,
    "TotalReturnQuantity" INT,
    "NetQuantity" INT
) AS $$
DECLARE
    v_isinsurance BOOLEAN;
BEGIN
    /*
    filename: "sp_report_bil_incomesegregation"
    createdby/date: sud:5may'21
    Description: to get the income head of different department and sales related data
    Remarks:    
    Change History
    S.No.    UpdatedBy/Date				Remarks
    1.      Sud:5May'21                complete rewrite after new requirement and credit note in place. "jiraid:lph-900"
    2.      sud:11aug'21               Adding Quantity Fields and get billingtype as input parameter.
    3.      Sud:26Aug'21               removing group logic for servicedepartment name. 
                                       since it's different for different hospitals and hence creating confusions/issues.
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
    
    RETURN QUERY SELECT 
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
    
    	from 
    
    	(
    	SELECT (txn.CreatedOn)::Date AS "BillingDate",
    	srv.ServiceDepartmentName AS "ServDeptName",
    	CASE WHEN txn.PaymentMode !='credit' THEN  itm.SubTotal ELSE 0 END AS "CashSales", 
    	CASE WHEN txn.PaymentMode !='credit' THEN  itm.DiscountAmount ELSE 0 END AS "CashDiscount", 
    	CASE WHEN txn.PaymentMode ='credit' THEN  itm.SubTotal ELSE 0 END AS "CreditSales", 
    	CASE WHEN txn.PaymentMode ='credit' THEN  itm.DiscountAmount ELSE 0 END AS "CreditDiscount", 
    	itm.SubTotal AS "GrossSales",
    	itm.DiscountAmount AS "TotalDiscount",
    	0 AS "ReturnCashSales", 
    	0 AS "ReturnCashDiscount",
    	0 AS "ReturnCreditSales", 
    	0 AS "ReturnCreditDiscount", 
    	0 AS "TotalSalesReturn", 
    	0 AS "TotalReturnDiscount",
    	--here return is zero so we're calculating only sales part --
    	itm.subtotal - itm.discountamount AS "NetSales",
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
    	select (ret.createdon)::date as "returndate",
    	srv.servicedepartmentname AS "ServDeptName",
    	0 AS "CashSales", 0 AS "CashDiscount",
    	0 AS "CreditSales",0 AS "CreditDiscount",
    	0 AS "GrossSales",
    	0 AS "TotalDiscount",
    	case when ret.paymentmode != 'credit' then  retitm.retsubtotal else 0 end AS "ReturnCashSales", 
    	case when ret.paymentmode != 'credit' then  retitm.retdiscountamount else 0 end AS "ReturnCashDiscount", 
    	case when ret.paymentmode = 'credit' then  retitm.retsubtotal else 0 end AS "ReturnCreditSales", 
    	case when ret.paymentmode = 'credit' then  retitm.retdiscountamount else 0 end AS "ReturnCreditDiscount", 
    	retitm.retsubtotal AS "TotalSalesReturn",
    	retitm.retdiscountamount AS "TotalReturnDiscount",
    	--here return is zero so we're calculating only sales part --
    	- (retItm.RetSubTotal - retItm.RetDiscountAmount) AS "NetSales",
    	 0 AS SaleQuantity,
    	 retitm.RetQuantity AS "ReturnQuantity"
    
    	from BIL_TXN_InvoiceReturn ret
    	  INNER JOIN BIL_TXN_InvoiceReturnItems retItm
    		  ON ret.BillReturnId = retItm.BillReturnId 
    	 INNER JOIN BIL_MST_ServiceDepartment srv
    	   ON retItm.ServiceDepartmentId=srv.ServiceDepartmentId
    
    	--WHERE COALESCE(ret.IsInsuranceBilling,0)=v_isinsurance
    	  Where (COALESCE(v_isinsurance, COALESCE(ret.IsInsuranceBilling, 0)) = COALESCE(ret.IsInsuranceBilling, 0))
    	) A
    
    	Where A.BillingDate Between p_fromdate AND p_todate
    	Group by ServDeptName
    	Order by ServDeptName;
    
    	--Select Sum(COALESCE(AdvanceReceived,0)) 'tot_depreceived',
    	--Sum(COALESCE(AdvanceSettled,0)) 'tot_depsettled'
    	--from fn_bil_getdepositnprovisionalbetndaterange(p_fromdate,p_todate)
    
    end;
END;
$$ LANGUAGE plpgsql;