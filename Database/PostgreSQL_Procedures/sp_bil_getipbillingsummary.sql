CREATE OR REPLACE FUNCTION sp_bil_getipbillingsummary(
    p_patientid INT DEFAULT NULL,
    p_patientvisitid INT DEFAULT NULL,
    p_billstatus VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "GroupName" VARCHAR,
    "SubTotal" DECIMAL,
    "DiscountAmount" INT,
    "TotalAmount" DECIMAL
) AS $$
BEGIN
    /*
    filename: "sp_bil_getipbillingsummary"
    createdby/date: krishna/10thaug'23
    Description: To get the summary of IpBilling 
    			 
    Remarks:    
    Change History
    S.No.    UpdatedBy/Date                        Remarks
    1       Krishna/10thAug'23                     created the script
    */
    
    
    	RETURN QUERY SELECT
    	grp.groupname,
    	grp.subtotal,
    	grp.discountamount,
    	grp.totalamount
    from (
    select 
    	itms.servicedepartmentname AS "GroupName", 
    	(sum(coalesce(itms.subtotal, 0)))::decimal(16,4) AS "SubTotal",
    	(sum(coalesce(itms.discountamount, 0)))::decimal(16,4) AS "DiscountAmount", 
    	(sum(coalesce(itms.totalamount, 0)))::decimal(16,4) AS "TotalAmount" 
    from 
    		(select servicedepartmentid, servicedepartmentname,billingtransactionitemid,
    			  subtotal, discountamount, totalamount from bil_txn_billingtransactionitems 
    		 where patientid = p_patientid and patientvisitid = p_patientvisitid and billstatus = p_billstatus) itms
    		 inner join bil_mst_servicedepartment servdep on itms.servicedepartmentid = servdep.servicedepartmentid
    		 group by itms.servicedepartmentid, itms.servicedepartmentname
    )grp;
END;
$$ LANGUAGE plpgsql;