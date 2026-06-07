CREATE OR REPLACE FUNCTION sp_report_inventory_purchasesummary(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_vendorid INT DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
BEGIN
    /*
    filename: "sp_report_inventory_purchasesummary" '2021-09-07','2021-09-14'
    example to execute:
    	execute sp_report_inventory_purchasesummary '2021-09-07','2021-09-14'
    createdby/date: nageshbb/16 sep 2020
    description: get records for inventory purchase summary report
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1.		nageshbb/16 sep 2020		created sp for get records for inventory purchase summary report
    2.		sanjit/14sep21				added othercharges in the report
    3.		nageshbb/19 sep 2021		changes for filter data with vendor id and add vendor bill date in result
    4.      rusha/07th sep 2022         remove category id 
    */
    begin
    	if(p_fromdate is not null or p_todate is not null)
    	then
    		if( coalesce(p_vendorid,0) > 0) --if vendor id is not provided then 
    		then
    				open ref1 for select 			
    				    gr.goodsreceiptid,	gr.goodsreceiptno,	to_char(gr.goodsreceiptdate, 'YYYY-MM-DD HH24:MI:SS') as goodsreceiptdate,
    					gr.purchaseorderid,	v.vendorname,	v.contactno,gr.billno,gr.subtotal,gr.discountamount,gr.vattotal,
    					gr.othercharges || (select sum(othercharge) from inv_txn_goodsreceiptitems where goodsreceiptid = gr.goodsreceiptid) as othercharges,
    					gr.totalamount,	gr.paymentmode,	gr.remarks,to_char(gr.createdon, 'YYYY-MM-DD HH24:MI:SS') as createdon,
    					to_char(gr.vendorbilldate, 'YYYY-MM-DD HH24:MI:SS') as vendorbilldate
    				from inv_txn_goodsreceipt gr
    					inner join inv_mst_vendor v on v.vendorid=gr.vendorid
    				where
    					(gr.goodsreceiptdate)::date between (p_fromdate)::date and (p_todate)::date
    					and gr.iscancel !=1 and gr.vendorid =p_vendorid;
        return next ref1;	
    						
    		
    		else
    		
    				open ref2 for select 			
    				    gr.goodsreceiptid,	gr.goodsreceiptno,	to_char(gr.goodsreceiptdate, 'YYYY-MM-DD HH24:MI:SS') as goodsreceiptdate,
    					gr.purchaseorderid,	v.vendorname,	v.contactno,gr.billno,gr.subtotal,gr.discountamount,gr.vattotal,
    					gr.othercharges || (select sum(othercharge) from inv_txn_goodsreceiptitems where goodsreceiptid = gr.goodsreceiptid) as othercharges,
    					gr.totalamount,	gr.paymentmode,	gr.remarks,to_char(gr.createdon, 'YYYY-MM-DD HH24:MI:SS') as createdon,
    					to_char(gr.vendorbilldate, 'YYYY-MM-DD HH24:MI:SS') as vendorbilldate
    				from inv_txn_goodsreceipt gr
    					inner join inv_mst_vendor v on v.vendorid=gr.vendorid
    				where
    				     (gr.goodsreceiptdate)::date between (p_fromdate)::date and (p_todate)::date
    					 and gr.iscancel !=1;
        return next ref2;
    		end if;
    	end if;	
    end;
END;
$$ LANGUAGE plpgsql;