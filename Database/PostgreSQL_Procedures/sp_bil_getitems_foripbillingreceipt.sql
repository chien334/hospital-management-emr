CREATE OR REPLACE FUNCTION sp_bil_getitems_foripbillingreceipt(
    p_patientid INT,
    p_billtxnid INT DEFAULT NULL,
    p_billstatus VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "BillDate" TIMESTAMP,
    "ServiceDepartmentId" INT,
    "ServiceDepartmentName" VARCHAR,
    "ServiceItemId" INT,
    "ItemName" VARCHAR,
    "DoctorId" INT,
    "DoctorName" VARCHAR,
    "Price" DECIMAL,
    "Quantity" INT,
    "SubTotal" DECIMAL,
    "DiscountAmount" INT,
    "Tax" VARCHAR,
    "TotalAmount" DECIMAL,
    "ItemCode" VARCHAR,
    "ServiceCategoryId" INT,
    "ServiceCategoryCode" VARCHAR,
    "ServiceCategoryName" VARCHAR,
    "IntegrationItemId" INT,
    "IntegrationName" TIMESTAMP
) AS $$
BEGIN
    /*
    filename: "sp_bil_getitems_foripbillingreceipt"
    createdby/date: sud/14sept'18
    Description: 
    Remarks:  Need to handle provisional etc carefully, else number of items could be more.. 
    Change History
    S.No.    UpdatedBy/Date                        Remarks
    1       sud/14Sept'18            initial draft
    2       sud/13mar'19             Adding Salutation in DoctorName
    3		Nagesh/04 June 2019  	 Getting correct bed quantity for estimated bill of adt patient
    4		Nagesh/15 Aug 2019		Get quantity if manually added any bed charges item
    5		Krishna,2Jun'22			changed providerid to performerid
    6.		rohit/24apr'22			ItemCode and Service Department Name is fetched
    7.		Krishna/4thJuly'23		complete rewrite of stored procedure, removing the grouping logic from here, will do from client side itself
    */
    
    RETURN QUERY SELECT * from(
    	select 
    	(itm.createdon)::date AS "BillDate"
    	,itm.servicedepartmentid,
    	itm.servicedepartmentname
    	,itm.serviceitemid
    	,itm.itemname
    	,emp.employeeid AS "DoctorId"
    	,emp.fullname AS "DoctorName"
    	,itm.price
    	,coalesce(itm.quantity,0) - coalesce(retitms.retqty,0) AS "Quantity"
    	,coalesce(itm.subtotal,0) - coalesce(retitms.retsubtotal,0) AS "SubTotal"
    	,coalesce(itm.discountamount,0) - coalesce(retitms.retdiscountamount,0) AS "DiscountAmount"
    	,itm.tax
    	,coalesce(itm.totalamount,0) - coalesce(retitms.rettotalamount,0) AS "TotalAmount"
    	,servitm.itemcode
    	,servitm.servicecategoryid
    	,servcat.servicecategorycode
    	,servcat.servicecategoryname
    	,itm.integrationitemid
    	,servdep.integrationname
    from bil_txn_billingtransactionitems itm
    left join (select billingtransactionitemid,sum(coalesce(retsubtotal,0)) as "retsubtotal", 
    			sum(coalesce(rettotalamount,0)) as "rettotalamount", sum(coalesce(retdiscountamount,0)) as "retdiscountamount",
    			sum(coalesce(retquantity,0)) as "retqty"
    			from bil_txn_invoicereturnitems group by billingtransactionitemid) retitms 
    			on itm.billingtransactionitemid = retitms.billingtransactionitemid
    inner join bil_mst_serviceitem servitm on itm.serviceitemid = servitm.serviceitemid
    inner join bil_mst_servicedepartment servdep on itm.servicedepartmentid = servdep.servicedepartmentid
    left join bil_mst_servicecategory servcat on servitm.servicecategoryid = servcat.servicecategoryid
    left join emp_employee emp on itm.performerid = emp.employeeid
    where patientid = p_patientid
    and coalesce(itm.billingtransactionid, 0) = coalesce(p_billtxnid, coalesce(itm.billingtransactionid, 0))
    and itm.billstatus = coalesce(p_billstatus, itm.billstatus)
    )tbl where tbl.quantity > 0;
END;
$$ LANGUAGE plpgsql;