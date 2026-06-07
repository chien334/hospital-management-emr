CREATE OR REPLACE FUNCTION phrm_rpt_stocktransfers(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_itemid INT DEFAULT NULL,
    p_sourcestoreid INT DEFAULT NULL,
    p_targetstoreid INT DEFAULT NULL,
    p_notreceivedstocks BOOLEAN DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
BEGIN
    /*
    filename: phrm_rpt_stocktransfers
    createdby/date: sanjit/ 1st july, 2021
    description:
    remarks:  
    execute query:
        execute phrm_rpt_stocktransfers '2022-06-19','2022-07-21',null,null,null,0
    change history
    s.no.    updatedby/date                        remarks
    1.      sanjit/ 7th sep, 2021           changed the date format to all the dates in yyyy-mm-dd hh:mm
    2.      rusha/21thjuly22				added generic name in column
    3.		rohit/16dec'22					Added Convert Date in CreatedOn for Predicate
    4.      Rohit/13Feb'23						mrp-> saleprice
    */
    
    	-- body of the stored procedure
    	open ref1 for select g.genericname
    		,i.itemname
    		,d.batchno
    		,d.costprice
    		,d.saleprice
    		,
    		-- to get date in the format of yyyy-mm-dd hh:mm
    		to_char(d.createdon, 'YYYY-MM-DD HH24:MI:SS') as "transferredon"
    		,d.dispatchedquantity as "transferquantity"
    		,de.fullname as "transferredby"
    		,ss.name as "transferredfrom"
    		,ts.name as "transferredto"
    		,re.fullname as "receivedby"
    		,to_char(d.receivedon, 'YYYY-MM-DD HH24:MI:SS') as "receivedon"
    		,ae.fullname as "approvedby"
    		,to_char(r.approvedon, 'YYYY-MM-DD HH24:MI:SS') as "approvedon"
    		,coalesce((d.costprice * d.dispatchedquantity), 0) as "purchasevalue"
    		,coalesce((d.saleprice * d.dispatchedquantity), 0) as "salesvalue"
    	from phrm_storedispatchitems as d
    	inner join phrm_mst_item as i on d.itemid = i.itemid
    	join phrm_mst_generic as g on i.genericid = g.genericid
    	inner join phrm_mst_store as ss on d.sourcestoreid = ss.storeid
    	inner join phrm_mst_store as ts on d.targetstoreid = ts.storeid
    	left outer join phrm_storerequisition as r on d.requisitionid = r.requisitionid
    	inner join emp_employee as de on d.createdby = de.employeeid
    	left outer join emp_employee as ae on r.approvedby = ae.employeeid
    	left outer join emp_employee as re on d.receivedbyid = re.employeeid
    	where (d.createdon)::date between p_fromdate
    			and p_todate
    		and (
    			d.itemid = p_itemid
    			or p_itemid is null
    			)
    		and (
    			d.sourcestoreid = p_sourcestoreid
    			or p_sourcestoreid is null
    			)
    		and (
    			d.targetstoreid = p_targetstoreid
    			or p_targetstoreid is null
    			)
    		and (
    			d.receivedbyid is null
    			or p_notreceivedstocks is null
    			or p_notreceivedstocks = false
    			)
    	order by d.dispatchitemsid desc;
        return next ref1;
END;
$$ LANGUAGE plpgsql;