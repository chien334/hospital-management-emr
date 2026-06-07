CREATE OR REPLACE FUNCTION sp_report_bil_departmentsummary(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
BEGIN
    /*
    change history
    s.no.	updatedby/date			remarks
    1		ramavtar/11sept'18      Initial Draft
    2		Ramavtar/30Nov'18		added summary and filtered report data for provisional and cancel
    3       sud/13mar'19            Changed to function FN_BILL_Get_BillingTxnItemSeggregation_ByBillingType_NoProvisional 
                                      from: FN_BIL_GetTxnItemsInfoWithDateSeparation_DepartmentSummary
    4.		Dinesh/ 28th May'19		added credit received amount in summary as previously it was not cleared and taking from previous dates
    5.      dinesh /7thdec'2020     Handled Settled Discount Amount 
    */
    
    	--table1: report data
    	 OPEN ref1 FOR SELECT
    	    "FN_BIL_GetSrvDeptReportingName_DepartmentSummary" (ServiceDepartmentName,ItemName) AS "ServiceDepartment",
    		--fnItems.ServiceDepartmentName 'servicedepartment',
    		SUM(COALESCE(fnItems.Quantity, 0)) AS "Quantity",
    		SUM(COALESCE(fnItems.SubTotal, 0)) AS "SubTotal",
    		SUM(COALESCE(fnItems.DiscountAmount, 0)) AS "DiscountAmount",
    		SUM(COALESCE(fnItems.TotalAmount, 0)) AS "TotalAmount",
    		SUM(COALESCE(fnItems.ReturnTotalAmount, 0)) AS "ReturnAmount",
    	    SUM(COALESCE(TotalAmount, 0) - COALESCE(ReturnTotalAmount, 0)) AS "NetSales",
    	    SUM(COALESCE(CreditAmount, 0)) AS "CreditAmount",
    		SUM(COALESCE(CreditReceived, 0)) AS "CreditReceivedAmount"
    
    	FROM FN_BILL_Get_BillingTxnItemSeggregation_ByBillingType_NoProvisional(p_fromdate, p_todate)  fnItems
    
    	GROUP BY  
    	  "FN_BIL_GetSrvDeptReportingName_DepartmentSummary" (ServiceDepartmentName,ItemName) 
    	ORDER BY 1;
        RETURN NEXT ref1;
    	--SELECT
    	--	fnItems.ServiceDepartmentName 'servicedepartment',
    	--	SUM(COALESCE(fnItems.Quantity, 0)) 'quantity',
    	--	SUM(COALESCE(fnItems.SubTotal, 0)) 'subtotal',
    	--	SUM(COALESCE(fnItems.DiscountAmount, 0)) 'discountamount',
    	--	SUM(COALESCE(fnItems.TotalAmount, 0)) 'totalamount',
    	--	SUM(COALESCE(fnItems.ReturnAmount, 0)) 'returnamount',
    	--	SUM(COALESCE(TotalAmount, 0) - COALESCE(ReturnAmount, 0)) 'netsales'
    	--FROM (SELECT
    	--	*
    	--FROM FN_BIL_GetTxnItemsInfoWithDateSeparation_DepartmentSummary(p_fromdate, p_todate)
    	--WHERE BillStatus != 'cancelled' AND BillStatus != 'provisional') fnItems
    	--GROUP BY fnItems.ServiceDepartmentName
    	--ORDER BY 1
    	--table2: provisional, cancel, credit amounts for summary
    	OPEN ref2 FOR SELECT 
    		SUM(CASE WHEN BillStatus='provisional' THEN ProvisionalAmount ELSE 0 END) AS "ProvisionalAmount",
    		SUM(CASE WHEN BillStatus='cancelled' THEN CancelledAmount ELSE 0 END) AS "CancelledAmount",
    		SUM(CASE WHEN BillStatus='credit' then creditamount else 0 end) as "creditamount",
    		(select sum(coalesce(creditreceived, 0)) from fn_bill_get_billingtxnitemseggregation_bybillingtype_noprovisional(p_fromdate,p_todate))  as "creditreceivedamount",
    		(select sum(coalesce(advancereceived,0)) from fn_bil_getdepositnprovisionalbetndaterange(p_fromdate,p_todate)) as "advancereceived",
    		(select sum(coalesce(advancesettled,0)) from fn_bil_getdepositnprovisionalbetndaterange(p_fromdate,p_todate)) as "advancesettled",
    		(select sum(coalesce(settleddiscountamount,0)) from "fn_bil_getsettledamountbetndaterange"(p_fromdate,p_todate)) as "settleddiscountamount"
    	from fn_bil_gettxnitemsinfowithdateseparation_departmentsummary(p_fromdate, p_todate);
        return next ref2;
END;
$$ LANGUAGE plpgsql;