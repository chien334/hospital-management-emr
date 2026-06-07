CREATE OR REPLACE FUNCTION sp_report_dispatch_details(
    p_dispatchid INT DEFAULT 0,
    p_fiscalyearid INT DEFAULT 0,
    p_requisitionid INT DEFAULT 0
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
BEGIN
    /*
    change history
    s.no.    updatedby/date					remarks
    1		kushal/18 oct 2019				created script 
    2		sanjit/5 mar 2020				divided by zero bug fix using case statement
    3.      sud/3mar'20						Changed Department to Store (needs revision)
    4.		Sanjit/10Apr'20					added remarks in sp	
    5.		sanjit/17apr'20					Added few more properties to use it in Dispatch Receipt.
    6.		Sanjit/12Sep'21					stock refactoring changes
    7.		rohit/19jan'22					BarCodeNumber is added in SP to show the barcode in dispatched receipt
    8.		ROHIT/10Feb'22					issue no is not showing issue solved.
    9.		rohit/20may'22					SP Modified to get Item Level Remarks
    10.		ROHIT/17Jun'22					fetched dispatcheddate, receiveddate
    11.		rohit/19jul'22					FiscalYearId predicate is added
    12.		ROHIT/19Dec'22					get dispatcheddate instead of createdon
    13.		rohit/7may'23					Fetched Main Level Details
    14.		ROHIT/7Sept'23					fetched dispatchno (previously dispatchno is fetched as issueno)
    */
    begin
      if(p_dispatchid > 0)
    	then
    	open ref1 for select req.requisitionno
    	,ts.name as "targetstorename"
    	,ss.name as "sourcestorename"
    	,dis.dispatchno
    	,req.issueno
    	,req.requisitiondate
    	,reqemp.fullname as "requestedbyname"
    	,disemp.fullname as "dispatchedbyname"
    	,dis.createdon as "dispatcheddate"
    	,recemp.fullname as "receivedby"
    	,dis.receivedon as "receiveddate"
    	,dis.remarks
    	,req.isdirectdispatched
    from inv_txn_dispatch dis
    inner join inv_txn_requisition req on dis.requisitionid = req.requisitionid
    inner join phrm_mst_store ts on dis.targetstoreid = ts.storeid
    inner join phrm_mst_store ss on dis.sourcestoreid = ss.storeid
    inner join emp_employee reqemp on req.createdby=reqemp.employeeid
    inner join emp_employee disemp on dis.createdby =disemp.employeeid
    left join emp_employee recemp on dis.receivedby =recemp.employeeid
    where dis.dispatchid = p_dispatchid
    	and dis.requisitionid = p_requisitionid
    	and dis.fiscalyearid = p_fiscalyearid;
        return next ref1;
    
        open ref2 for select
          ri.requisitionitemid,
          d.itemid,
    	  d.specification,
          i.code,
          i.itemname,
          ri.quantity,
          ri.pendingquantity,
          ri.receivedquantity,
          d.dispatchedquantity,
          (select 
            costprice
          from inv_txn_stocktransaction
          where transactiontype in ('dispatched-item-to','dispatched-item-from') and referenceno = d.dispatchitemsid limit 1) as costprice,
          d.dispatchedquantity * (select 
            costprice
          from inv_txn_stocktransaction
          where transactiontype in ('dispatched-item-to','dispatched-item-from') and referenceno = d.dispatchitemsid limit 1 ) as amt,
          ri.requisitionitemstatus,
          d.remarks,
    	  d.itemremarks,
    	  string_agg(fas.barcodenumber,',')  as "barcodenumber",
    	  fy.fiscalyearname
        from
          inv_txn_dispatchitems d
          inner join inv_mst_item i on i.itemid = d.itemid
    	  left join inv_map_dispatchitems_fixedassetstock f on d.dispatchitemsid=f.dispatchitemsid
    	  left join inv_txn_fixedassetstock fas on f.fixedassetstockid=fas.fixedassetstockid
          inner join inv_txn_requisitionitems ri on d.requisitionitemid= ri.requisitionitemid 
          inner join inv_txn_requisition r on r.requisitionid = ri.requisitionid
    	  inner join inv_cfg_fiscalyears fy on d.fiscalyearid=fy.fiscalyearid
        where d.dispatchid = p_dispatchid and d.fiscalyearid=p_fiscalyearid and r.requisitionid=p_requisitionid
    	group by 
          ri.requisitionitemid,
          d.itemid,
    	  d.specification,
          i.code,
          i.itemname,
          ri.quantity,
          ri.pendingquantity,
          ri.receivedquantity,
          d.dispatchedquantity,
    	  ri.requisitionitemstatus,
          d.remarks,
    	  d.dispatchitemsid,
    	  d.itemremarks,
    	  fy.fiscalyearname;
        return next ref2;
      end if;
    end;
END;
$$ LANGUAGE plpgsql;