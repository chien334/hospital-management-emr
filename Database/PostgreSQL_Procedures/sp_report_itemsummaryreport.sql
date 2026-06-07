/*
File: SP_Report_ItemSummaryReport
Author:     20April'20/Pratik 
Description:  To get Items item summary report

Change History
S.No.   Date/Author           Remarks
1.     20April'20/Pratik   Initial Draft
2. Sud:23Apr'20            Correction in TotalQty and ReturnStatus
3. Krishna:19thOct'22	   SP revised handling Return conditions 
*/
CREATE OR REPLACE FUNCTION sp_report_itemsummaryreport(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL
)
RETURNS TABLE (
    "ServiceDepartmentName" VARCHAR,
    "ItemName" VARCHAR,
    "SubTotal" DECIMAL,
    "TotalQty" INT,
    "TotalAmount" DECIMAL,
    "DiscountAmount" INT
) AS $$
BEGIN
    
    	RETURN QUERY SELECT 
    tbl1.servicedepartmentname,
    tbl1.itemname,
    sum(coalesce(tbl1.subtotal,0)) -  sum(coalesce(tbl2.retsubtotal,0)) AS "SubTotal",
    sum(coalesce(tbl1.totalquantity,0)) - sum(coalesce(tbl2.retquantity,0)) AS "TotalQty",
    sum(coalesce(tbl1.totalamount,0)) - sum(coalesce(tbl2.rettotalamount,0)) AS "TotalAmount",
    sum(coalesce(tbl1.discountamount,0)) - sum(coalesce(tbl2.retdiscountamount,0)) AS "DiscountAmount"
    from(
    select 
    itms.servicedepartmentname,
    itms.itemname,
    sum(coalesce(itms.subtotal,0)) AS "SubTotal",
    sum(coalesce(itms.quantity,0)) as "totalquantity",
    sum(coalesce(itms.totalamount,0)) AS "TotalAmount",
    sum(coalesce(itms.discountamount,0)) AS "DiscountAmount"
    from bil_txn_billingtransactionitems itms
    join bil_txn_billingtransaction txn
    on itms.billingtransactionid = txn.billingtransactionid
    where 
    (txn.createdon)::date between p_fromdate and p_todate
    and (itms.billstatus='paid' or itms.billstatus='unpaid')
    group by itms.servicedepartmentname, itms.itemname
    ) tbl1
    left join(
    select itemname, sum(coalesce(retsubtotal,0)) as "retsubtotal",
    		    sum(coalesce(rettotalamount,0)) as "rettotalamount", sum(coalesce(retquantity,0)) as "retquantity", sum(coalesce(retdiscountamount,0)) as "retdiscountamount"	from bil_txn_invoicereturnitems 
    			where (createdon)::date between p_fromdate and p_todate
    			group by itemname
    			) tbl2
    			on tbl1.itemname = tbl2.itemname
    group by tbl1.servicedepartmentname,tbl1.itemname
    order by tbl1.servicedepartmentname,tbl1.itemname;
END;
$$ LANGUAGE plpgsql;