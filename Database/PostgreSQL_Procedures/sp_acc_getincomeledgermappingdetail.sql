CREATE OR REPLACE FUNCTION sp_acc_getincomeledgermappingdetail(

)
RETURNS TABLE (
    "LedgerId" INT,
    "LedgerGroupId" INT,
    "LedgerName" VARCHAR,
    "IsActive" BOOLEAN,
    "Name" VARCHAR,
    "LedgerType" VARCHAR,
    "LedgerCode" VARCHAR,
    "SubLedgerId" INT,
    "SubLedgerName" VARCHAR,
    "BillLedgerMappingId" INT,
    "IsMapped" BOOLEAN,
    "itemDetail.*" VARCHAR,
    "BillingType" VARCHAR
) AS $$
BEGIN
    /*
     exec sp_acc_getincomeledgermappingdetail
    
     change history
    sn.                auther/timestamp                   description
    1.                 devn/11th june 23                initial draft of sp to get incomeledger mapping detail.
    */
    begin
    	RETURN QUERY SELECT 
    		coalesce(ledger.ledgerid,0) AS "LedgerId"
    		,coalesce(ledger.ledgergroupid,0) AS "LedgerGroupId"
    		,coalesce(ledger.ledgername, '') AS "LedgerName"
    		,coalesce(map.isactive,0) AS "IsActive"
    		,coalesce(ledger.name,'') AS "Name"
    		,'billingincomeledger' AS "LedgerType"
    		,ledger.code AS "LedgerCode"
    		,coalesce(subledger.subledgerid,0 ) AS "SubLedgerId"
    		,coalesce(subledger.subledgername,'') AS "SubLedgerName"
    		,coalesce(map.billledgermappingid,0) AS "BillLedgerMappingId"
    		,case 
    			when ledger.ledgerid > 0
    				then 1
    			else 0
    			end AS "IsMapped"
    		,itemdetail.*
    		,billingtype.value AS "BillingType"
    	from (
    		select servdept.servicedepartmentid
    			,servdept.servicedepartmentname
    			,item.serviceitemid as itemid
    			,item.itemname
    			,item.itemcode
    		from bil_mst_servicedepartment servdept
    		left join bil_mst_serviceitem item on servdept.servicedepartmentid = item.servicedepartmentid
    		where item.serviceitemid > 0 and item.isactive = 1
    		) as itemdetail
    	cross join (
    		select value
    		from string_split('outpatient,inpatient', ',')
    		) AS "BillingType"
    	left join acc_bill_ledgermapping map on itemdetail.servicedepartmentid = map.servicedepartmentid and itemdetail.itemid = map.itemid and billingtype.value = map.billingtype
    	left join acc_ledger ledger on map.ledgerid = ledger.ledgerid
    	left join acc_mst_subledger subledger on map.subledgerid = subledger.subledgerid
    	order by itemdetail.itemname;
    end;
END;
$$ LANGUAGE plpgsql;