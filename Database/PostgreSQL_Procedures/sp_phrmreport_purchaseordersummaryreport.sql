CREATE OR REPLACE FUNCTION sp_phrmreport_purchaseordersummaryreport(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_status VARCHAR DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
    ref3 refcursor := 'cursor3';
BEGIN
    /*
    filename: "sp_phrmreport_purcaseordersummary" '2022/04/14','2022/07/19',''
    createdby/date: umed/2017-11-23
    description: .
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1       umed/2017-05-25	                     created the script
    2		rusha/2019-04-26					 recreated of script
    3		naveed/2019-12-13					 updated script for exclude zero quantity items from report
    4		rohit/2022-05-10					 total amount mismatch resolve (before it was taking mainlevel total amount)
    5       rusha/21thjuly22				     added generic name in column
    6.		rohit/28mar'23						 Alter Column Name StandardRate -> SalePrice
    7.		Nirmala/4Jul'23						 alter column name saleprice -> standardrate
    */
    begin
    	if (
    			(p_fromdate is not null)
    			)
    		and (p_status is not null)
    	then
    
    		if (p_status = 'all')
    		then
    			open ref1 for select (po.podate)::date as "date"
    				,itm.itemname
    				,gen.genericname
    				,po.postatus
    				,poitm.subtotal
    				,poitm.vatamount
    				,poitm.totalamount
    				,sum(poitm.quantity) as quantity
    				,poitm.standardrate
    				,sum(poitm.receivedquantity) as receivedquantity
    			from phrm_purchaseorder as po
    			join phrm_purchaseorderitems as poitm on poitm.purchaseorderid = po.purchaseorderid
    			join phrm_mst_item as itm on itm.itemid = poitm.itemid
    			join phrm_mst_generic as gen on itm.genericid = gen.genericid
    			where (po.podate)::timestamp between coalesce(p_fromdate, current_timestamp)
    					and coalesce(p_todate, current_timestamp) + 1
    				and poitm.quantity > 0
    			group by (po.podate)::date
    				,itm.itemname
    				,gen.genericname
    				,po.postatus
    				,poitm.subtotal
    				,poitm.vatamount
    				,poitm.totalamount
    				,poitm.quantity
    				,poitm.standardrate
    				,poitm.receivedquantity
    			order by (po.podate)::date desc;
        return next ref1;
    		
    
    		elsif (p_status = 'active')
    		then
    			open ref2 for select (po.podate)::date as "date"
    				,itm.itemname
    				,gen.genericname
    				,po.postatus
    				,poitm.subtotal
    				,poitm.vatamount
    				,poitm.totalamount
    				,sum(poitm.quantity) as quantity
    				,poitm.standardrate
    				,sum(poitm.receivedquantity) as receivedquantity
    			from phrm_purchaseorder as po
    			join phrm_purchaseorderitems as poitm on poitm.purchaseorderid = po.purchaseorderid
    			join phrm_mst_item as itm on itm.itemid = poitm.itemid
    			join phrm_mst_generic as gen on itm.genericid = gen.genericid
    			where po.postatus = 'active'
    				and (po.podate)::timestamp between coalesce(p_fromdate, current_timestamp)
    					and coalesce(p_todate, current_timestamp) + 1
    				and poitm.quantity > 0
    			group by (po.podate)::date
    				,itm.itemname
    				,gen.genericname
    				,po.postatus
    				,poitm.subtotal
    				,poitm.vatamount
    				,poitm.totalamount
    				,poitm.quantity
    				,poitm.standardrate
    				,poitm.receivedquantity
    			order by (po.podate)::date desc;
        return next ref2;
    		
    
    		elsif (p_status = 'complete')
    		then
    			open ref3 for select (po.podate)::date as "date"
    				,itm.itemname
    				,gen.genericname
    				,po.postatus
    				,poitm.subtotal
    				,poitm.vatamount
    				,poitm.totalamount
    				,sum(poitm.quantity) as quantity
    				,poitm.standardrate
    				,sum(poitm.receivedquantity) as receivedquantity
    			from phrm_purchaseorder as po
    			join phrm_purchaseorderitems as poitm on poitm.purchaseorderid = po.purchaseorderid
    			join phrm_mst_item as itm on itm.itemid = poitm.itemid
    			join phrm_mst_generic as gen on itm.genericid = gen.genericid
    			where po.postatus = 'complete'
    				and (po.podate)::timestamp between coalesce(p_fromdate, current_timestamp)
    					and coalesce(p_todate, current_timestamp) + 1
    				and poitm.quantity > 0
    			group by (po.podate)::date
    				,itm.itemname
    				,gen.genericname
    				,po.postatus
    				,poitm.subtotal
    				,poitm.vatamount
    				,poitm.totalamount
    				,poitm.quantity
    				,poitm.standardrate
    				,poitm.receivedquantity
    			order by (po.podate)::date desc;
        return next ref3;
    		end if;
    	end if;
    end;
END;
$$ LANGUAGE plpgsql;