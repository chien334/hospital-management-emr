CREATE OR REPLACE FUNCTION sp_wardreport_requisitionreport(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_storeid INT DEFAULT NULL
)
RETURNS TABLE (
    "RequisitionId" INT,
    "DispatchId" INT,
    "RequestedDate" TIMESTAMP,
    "DispatchDate" TIMESTAMP,
    "ItemName" VARCHAR,
    "RequestedQty" INT,
    "DispatchQty" INT,
    "MRP" VARCHAR,
    "TotalAmt" DECIMAL,
    "RequestedByUser" VARCHAR,
    "DispatchedByUser" VARCHAR,
    "ReceivedBy" VARCHAR
) AS $$
BEGIN
    /*
    filename: "sp_wardreport_requisitionreport" '1/7/2020','1/7/2020'
    createdby/date: rusha/03-26-2019
    description: to get the requsition and dispatch details of stock such as wardname, itemname, batchno, requestedqty, mrp of each item selected by user 
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1.		rusha/03-26-2019					   get stock details of requisition and dispatch of item from different ward
    2.		sanjit/01-09-2020					   added requested by user and dispatched by user and receivedby user.
    3.		sanjit/03-20-2020					   substore integration
    */
    
    begin
      if ((p_fromdate is not null) and (p_todate is not null))
    		then
    			RETURN QUERY SELECT req.requisitionid,disp.dispatchid,(req.createdon)::date AS "RequestedDate",
    			(dispitm.createdon)::date AS "DispatchDate", itm.itemname,sum(reqitm.quantity) AS "RequestedQty",
    			sum(dispitm.quantity) AS "DispatchQty",dispitm.mrp, round(sum(dispitm.quantity)*dispitm.mrp, 2, 0) AS "TotalAmt",
    			(select fullname from emp_employee as emp1 where emp1.employeeid = req.createdby) AS "RequestedByUser",
    			(select fullname from emp_employee as emp2 where emp2.employeeid = dispitm.createdby) AS "DispatchedByUser",
    			disp.receivedby AS "ReceivedBy"
    			from ward_requisition as req
    			join ward_requisitionitems as reqitm on req.requisitionid= reqitm.requisitionid
    			join phrm_mst_item as itm on reqitm.itemid= itm.itemid
    			left join ward_dispatch as disp on req.requisitionid = disp.requisitionid and req.storeid = disp.storeid
    			left join ward_dispatchitems as dispitm on reqitm.requisitionitemid=dispitm.requisitionitemid and disp.dispatchid = dispitm.dispatchid
    			where req.storeid = p_storeid and (req.createdon)::date between coalesce(p_fromdate,current_timestamp)  and coalesce(p_todate,current_timestamp)+1
    			group by (req.createdon)::date,(dispitm.createdon)::date,reqitm.quantity,itm.itemname, dispitm.mrp, 
    			dispitm.quantity,req.createdby,dispitm.createdby,req.requisitionid,disp.dispatchid,disp.receivedby,dispitm.dispatchitemid;
    		end if;		
    end;
END;
$$ LANGUAGE plpgsql;