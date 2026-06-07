CREATE OR REPLACE FUNCTION sp_update_radiologyprovider_in_billtransactionitem(
    p_requisitionid INT,
    p_prescriberid INT,
    p_prescribername VARCHAR,
    p_performerid INT,
    p_performername VARCHAR
)
RETURNS void AS $$
BEGIN
      
     update bil_txn_billingtransactionitems set prescriberid=p_prescriberid,
     performerid = p_performerid,
     performername = p_performername where billingtransactionitemid =(  
     select item.billingtransactionitemid from bil_txn_billingtransactionitems item  
     join bil_mst_servicedepartment srvdept on srvdept.servicedepartmentid=item.servicedepartmentid  
     where lower(srvdept.integrationname)='radiology' and item.requisitionid=p_requisitionid  
     );    
      
    --end : dev , 23th june'22, change sp for ppr
END;
$$ LANGUAGE plpgsql;