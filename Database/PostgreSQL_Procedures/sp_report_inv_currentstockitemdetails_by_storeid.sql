CREATE OR REPLACE FUNCTION sp_report_inv_currentstockitemdetails_by_storeid(
    p_storeids VARCHAR DEFAULT NULL,
    p_itemid INT DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
    v_mainstoreid INT := null;
BEGIN
    /*
    change history
    s.no.    updatedby/date					remarks
    1		nagesh/19 sep 2020			 updated script for available quantity column
    2		nageshbb/22 sep 2020		 exclued items which available quantity is 0 and added storename column
    3. 		vikas/1-oct-2020 			 added missed column storename and price.
    */
    
    v_mainstoreid := (select storeid from phrm_mst_store where "name"='Main Store');	
    
    if(v_mainstoreid in (select distinct(value) from string_split(p_storeids, ',') where rtrim(value) <> ''))
    
    then
    	open ref1 for select 
    	x.goodsreceiptno,
    	goodsreceiptdate,
    	x.quantity,
    	x.price,
    	x.availablequantity,
    	x.storename
    	from (
    			select 
    
    			gr.goodsreceiptdate, 
    			gr.goodsreceiptno,
    			stk.availablequantity,
    			gritm.receivedquantity+gritm.freequantity as "quantity" ,
    			stk.price,
    			'Main Store' as storename
    		from inv_txn_stock stk
    			join inv_txn_goodsreceiptitems gritm on stk.goodsreceiptitemid = gritm.goodsreceiptitemid
    			join inv_txn_goodsreceipt gr on gritm.goodsreceiptid = gr.goodsreceiptid			
    		where stk.itemid=p_itemid and stk.availablequantity>0
    		union 
    		select 
    			gr.goodsreceiptdate, 
    			gr.goodsreceiptno,
    			stk.availablequantity,
    			gritm.receivedquantity+gritm.freequantity,
    			stk.price,
    			store.name as storename			
    		from ward_inv_stock stk
    			join inv_txn_goodsreceiptitems gritm on stk.goodsreceiptitemid = gritm.goodsreceiptitemid
    			join inv_txn_goodsreceipt gr on gritm.goodsreceiptid = gr.goodsreceiptid
    			join phrm_mst_store store on store.storeid =stk.storeid
    		where  stk.availablequantity>0 and 
    		  stk.itemid=p_itemid and stk.storeid in (select distinct(value) from string_split(p_storeids, ',') where rtrim(value) <> '')
    
    		) as x
    		
    group by goodsreceiptdate,x.goodsreceiptno,x.price,x.quantity,x.availablequantity,x.storename
    	order by x.storename,(x.goodsreceiptdate)::date;
        return next ref1;
    
    
    else
    	
    		open ref2 for select 
    			gr.goodsreceiptdate, 
    			gr.goodsreceiptno,
    			stk.availablequantity,
    			(gritm.receivedquantity)+ (gritm.freequantity) as quantity,
    			stk.price,
    			store.name as storename
    		from ward_inv_stock stk
    			join inv_txn_goodsreceiptitems gritm on stk.goodsreceiptitemid = gritm.goodsreceiptitemid
    			join inv_txn_goodsreceipt gr on gritm.goodsreceiptid = gr.goodsreceiptid
    			join phrm_mst_store store on store.storeid =stk.storeid
    		where  stk.availablequantity>0 and 
    		stk.itemid=p_itemid and stk.storeid in (select distinct(value) from string_split(p_storeids, ',') where rtrim(value) <> '')
    		group by goodsreceiptdate,gr.goodsreceiptno,stk.price,gritm.receivedquantity,gritm.freequantity,stk.availablequantity,store.name
    	    order by store.name, (gr.goodsreceiptdate)::date;
        return next ref2;
    	end if;
END;
$$ LANGUAGE plpgsql;