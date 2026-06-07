/* =================================================  
 Author:      Sanjit  
 Create date: 2022-06-22  
 Description: The report shows the profit%, return of investment for each stock in the system  
 Example:   EXEC SP_PHRM_Report_ReturnOnInvestment @FromDate = '2022-01-08', @ToDate = '2022-01-14'  
 ===================================================  
 SP History  
 ===================================================  
 SN. Update Date  Updated by  Description  
 1.  22Jun'22	  Sanjit      Get Return On Investment Report Data  
 2.  11Jul'22	  Sanjit      Purchase Returns added in calculation
 3.  Rohit/13Feb'23						MRP-> SalePrice
 ===================================================  
*/
CREATE OR REPLACE FUNCTION sp_phrm_report_returnoninvestment(
    p_fromdate DATE,
    p_todate DATE
)
RETURNS TABLE (
    "SupplierName" VARCHAR,
    "GoodReceiptPrintId" INT,
    "TransactionDate" TIMESTAMP,
    "ItemName" VARCHAR,
    "BatchNo" VARCHAR,
    "ItemRate" DECIMAL,
    "DiscountOnRate" TIMESTAMP,
    "RateAfterDiscount" INT,
    "InvoicedQuantity" INT,
    "FreeQuantity" INT,
    "TotalQuantity" INT,
    "TotalTax" DECIMAL,
    "OtherCharges" VARCHAR,
    "DiscountAmount" INT,
    "TotalAmount" DECIMAL,
    "CostPricePerUnit" DECIMAL,
    "StockValue" DECIMAL,
    "SalesValue" DECIMAL,
    "Profit" VARCHAR,
    "ProfitPercentage" VARCHAR,
    "ReturnOnInvestmentPercentage" TIMESTAMP
) AS $$
BEGIN
    begin
    	--  added to prevent extra result sets from  
    	-- interfering with select statements.  
    
    	RETURN QUERY SELECT s.suppliername
    		,gr.goodreceiptprintid
    		,gr.goodreceiptdate AS "TransactionDate"
    		,i.itemname
    		,gri.batchno
    		,gri.gritemprice AS "ItemRate"
    		,
    		-- discountonrate = (discountpercent * rate)/100
    		((gri.gritemprice * gri.discountpercentage) / 100)::decimal(18, 4) AS "DiscountOnRate"
    		,
    		-- rate after discount = rate - discountonrate
    		(gri.gritemprice - ((gri.gritemprice * gri.discountpercentage) / 100))::decimal(18, 4) AS "RateAfterDiscount"
    		,
    		-- invoicedqty = purchaseqty - returnedqty (if any)
    		gri.receivedquantity - coalesce(rtsi.quantity, 0) AS "InvoicedQuantity"
    		,
    		-- freeqty = freeqtyreceivedonpurchase - freeqtyreturned (if any)
    		gri.freequantity - coalesce(rtsi.freequantity, 0) AS "FreeQuantity"
    		,
    		-- totalqty = invoicedqty - freeqty (ref from above)
    		gri.receivedquantity + gri.freequantity - coalesce(rtsi.quantity, 0) - coalesce(rtsi.freequantity, 0) AS "TotalQuantity"
    		,
    		-- totaltax = vatonpurchase -  vatonreturn = ((vatpercentage * subtotalwithdiscount )/100) - vatonreturn
    		(gri.vatpercentage * (gri.receivedquantity * gri.gritemprice - ((gri.receivedquantity * gri.gritemprice * gri.discountpercentage) / 100)) / 100)::decimal(18, 4) - coalesce(rtsi.vatamount, 0) AS "TotalTax"
    		,
    		-- othercharges = ccamount - returnccamount = (freeqty * rate * ccpercent)/100  - returnccamount
    		((gri.freequantity * gri.gritemprice * coalesce(gri.cccharge, 0)) / 100)::decimal(18, 4) - coalesce(rtsi.ccamount, 0) AS "OtherCharges"
    		,
    		-- discountamount = dicountonpurchase - discountonreturn
    		((gri.discountpercentage * gri.gritemprice * gri.receivedquantity) / 100)::decimal(18, 4) - coalesce(rtsi.discountedamount, 0) AS "DiscountAmount"
    		,
    		-- totalamount = totalamountonpurchase - totalamountonreturn
    		gri.totalamount - coalesce(rtsi.totalamount, 0) AS "TotalAmount"
    		,
    		-- costpriceperunit = totalamount / totalqty  (ref from above)
    		case 
    			when (gri.receivedquantity + gri.freequantity - coalesce(rtsi.quantity, 0) - coalesce(rtsi.freequantity, 0)) = 0
    				then 0
    			else ((gri.totalamount - coalesce(rtsi.totalamount, 0)) / (gri.receivedquantity + gri.freequantity - coalesce(rtsi.quantity, 0) - coalesce(rtsi.freequantity, 0)))::decimal(18, 4)
    			end AS "CostPricePerUnit"
    		,
    		-- stockvalue = totalamountonpurchase - totalamountonreturn
    		(gri.totalamount - coalesce(rtsi.totalamount, 0))::decimal(18, 4) AS "StockValue"
    		,
    		--salesvalue = totalqty * saleprice 
    		((gri.receivedquantity + gri.freequantity - coalesce(rtsi.quantity, 0) - coalesce(rtsi.freequantity, 0)) * gri.saleprice)::decimal(18, 4) AS "SalesValue"
    		,
    		-- profit = salesvalue - stockvalue = (totalqty * saleprice ) - (totalamountonpurchase - totalamountonreturn)
    		(((gri.receivedquantity + gri.freequantity - coalesce(rtsi.quantity, 0) - coalesce(rtsi.freequantity, 0)) * gri.saleprice) - (gri.totalamount - coalesce(rtsi.totalamount, 0)))::decimal(18, 4) AS "Profit"
    		,
    		-- profitpercent = ((saleprice - costpriceperunit)/saleprice) * 100
    		case 
    			when gri.saleprice = 0
    				or gri.saleprice is null
    				then 0
    			when (gri.receivedquantity + gri.freequantity - coalesce(rtsi.quantity, 0) - coalesce(rtsi.freequantity, 0)) = 0
    				then 0
    			else (((gri.saleprice - ((gri.totalamount - coalesce(rtsi.totalamount, 0)) / (gri.receivedquantity + gri.freequantity - coalesce(rtsi.quantity, 0) - coalesce(rtsi.freequantity, 0)))) / gri.saleprice) * 100)::decimal(18, 4)
    			end AS "ProfitPercentage"
    		,
    		-- roipercent = (profit/costpriceperunit) *100 ((saleprice-costpriceperunit) / costpriceperunit)* 100
    		case 
    			when gri.totalamount = 0
    				then 0
    			when (gri.receivedquantity + gri.freequantity - coalesce(rtsi.quantity, 0) - coalesce(rtsi.freequantity, 0)) = 0
    				then 0
    			when (gri.totalamount - coalesce(rtsi.totalamount, 0)) / (gri.receivedquantity + gri.freequantity - coalesce(rtsi.quantity, 0) - coalesce(rtsi.freequantity, 0)) <= 0
    				then 100
    			else (((gri.saleprice - ((gri.totalamount - coalesce(rtsi.totalamount, 0)) / (gri.receivedquantity + gri.freequantity - coalesce(rtsi.quantity, 0) - coalesce(rtsi.freequantity, 0)))) / ((gri.totalamount - coalesce(rtsi.totalamount, 0)) / (gri.receivedquantity + gri.freequantity - coalesce(rtsi.quantity, 0) - coalesce(rtsi.freequantity, 0)))) * 100)::decimal(18, 4)
    			end AS "ReturnOnInvestmentPercentage"
    	from phrm_goodsreceiptitems gri
    	inner join phrm_goodsreceipt gr on gri.goodreceiptid = gr.goodreceiptid
    	inner join phrm_mst_supplier s on gr.supplierid = s.supplierid
    	inner join phrm_mst_item i on gri.itemid = i.itemid
    	left join (
    		select rtsi.goodreceiptitemid
    			,sum(rtsi.quantity) as quantity
    			,sum(rtsi.freequantity) AS "FreeQuantity"
    			,sum(rtsi.discountedamount) as discountedamount
    			,sum(rtsi.vatamount) as vatamount
    			,sum(rtsi.ccamount) as ccamount
    			,sum(rtsi.totalamount) AS "TotalAmount"
    		from phrm_returntosupplieritems rtsi
    		group by rtsi.goodreceiptitemid
    		) rtsi on gri.goodreceiptitemid = rtsi.goodreceiptitemid
    	where (gr.goodreceiptdate)::date between p_fromdate
    			and p_todate
    		and coalesce(gri.iscancel, 0) != 1
    	
    	union all
    	
    	select 'OPENING' AS "SupplierName"
    		,null AS "GoodReceiptPrintId"
    		,st.transactiondate
    		,i.itemname
    		,st.batchno
    		,st.costprice AS "ItemRate"
    		,0 AS "DiscountOnRate"
    		,st.costprice AS "RateAfterDiscount"
    		,st.inqty AS "InvoicedQuantity"
    		,0 AS "FreeQuantity"
    		,st.inqty AS "TotalQuantity"
    		,0 AS "TotalTax"
    		,0 AS "OtherCharges"
    		,0 AS "DiscountAmount"
    		,(st.inqty * st.costprice)::decimal(18, 4) AS "TotalAmount"
    		,st.costprice AS "CostPricePerUnit"
    		,(st.inqty * st.costprice)::decimal(18, 4) AS "StockValue"
    		,(st.inqty * st.saleprice)::decimal(18, 4) AS "SalesValue"
    		,(st.inqty * st.saleprice)::decimal(18, 4) - (st.inqty * st.costprice)::decimal(18, 4) AS "Profit"
    		,case 
    			when st.saleprice = 0
    				or st.saleprice is null
    				then 0
    			else (((st.saleprice - st.costprice) / st.saleprice) * 100)::decimal(18, 4)
    			end AS "ProfitPercentage"
    		,case 
    			when st.costprice = 0
    				or st.costprice is null
    				then 0
    			else (((st.saleprice - st.costprice) / st.costprice) * 100)::decimal(18, 4)
    			end AS "ReturnOnInvestmentPercentage"
    	from phrm_txn_stocktransaction st
    	inner join phrm_mst_item i on st.itemid = i.itemid
    	where (st.transactiondate)::date between p_fromdate
    			and p_todate
    		and st.transactiontype = 'opening-item'
    	order by transactiondate asc;
    end;
END;
$$ LANGUAGE plpgsql;