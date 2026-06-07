CREATE OR REPLACE FUNCTION sp_bil_getbilltxnitemsbetndaterange_fordepartment(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_searchtext VARCHAR DEFAULT NULL,
    p_srvdptintegrationname VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "Date" TIMESTAMP,
    "ServiceDepartmentId" INT,
    "ServiceDepartmentName" VARCHAR,
    "ItemId" INT,
    "ItemName" VARCHAR,
    "PerformerId" INT,
    "PerformerName" VARCHAR,
    "BillingTransactionItemId" INT,
    "BillStatus" VARCHAR,
    "PrescriberId" INT,
    "BillingTransactionId" INT,
    "RequisitionId" INT,
    "ReceiptNo" VARCHAR,
    "PatientId" INT,
    "PatientName" VARCHAR,
    "DateOfBirth" TIMESTAMP,
    "Gender" VARCHAR,
    "PhoneNumber" TIMESTAMP,
    "PatientCode" VARCHAR,
    "DoctorMandatory" VARCHAR,
    "PrescriberName" VARCHAR
) AS $$
BEGIN
    /*
    filename: "sp_bil_getbilltxnitemsbetndaterange_fordepartment"
    createdby/date: anjana/sud/2020-05-26
    description: to get billing txn item details for selected integration name(service department)
    remarks:  
       -- returned items are excluded.
       -- cancelled+adtcancelled items are excluded.
       -- if search text is empty then returning all.
       -- if date is empty the returning today's tranisaction.
       -- if integrationname is empty then returing all.
    
    
    Change History
    S.No.    UpdatedBy/Date                        Remarks
    1.      Anjana/sud/2020-05-26              Initial Draft
    2.		Krishna/2Jun'22					   changed providerid to performerid, providername to performername, requestedby to prescriberid
    */
    
     
     
    RETURN QUERY SELECT 
    	txnitem.createdon AS "Date"
    	, txnitem.servicedepartmentid,
    	txnitem.servicedepartmentname,
    	txnitem.itemid,
    	txnitem.itemname,
    	txnitem.performerid,
    	txnitem.performername,
    	txnitem.billingtransactionitemid,
    	txnitem.billstatus,
    	txnitem.prescriberid AS "PrescriberId",
    	txnitem.billingtransactionid,
    	txnitem.requisitionid,
    	biltxn.invoicecode || (biltxn.invoiceno)::varchar AS "ReceiptNo",
    	pat.patientid,
    	pat.shortname AS "PatientName",
    	pat.dateofbirth,
    	pat.gender,
    	pat.phonenumber,
    	pat.patientcode,
    	cfg.isdoctormandatory AS "DoctorMandatory",
    	emp.fullname AS "PrescriberName"
    
    from bil_txn_billingtransactionitems txnitem inner join
         bil_mst_servicedepartment srv  
    	    on srv.servicedepartmentid = txnitem.servicedepartmentid 
    	inner join pat_patient pat
    	  on txnitem.patientid = pat.patientid
    	inner join bil_cfg_billitemprice cfg
    	 
    	     on txnitem.servicedepartmentid = cfg.servicedepartmentid and txnitem.itemid=cfg.itemid
    	left join bil_txn_billingtransaction biltxn on txnitem.billingtransactionid = biltxn.billingtransactionid
    	left join emp_employee emp on txnitem.prescriberid = emp.employeeid
    
    where 
    coalesce(srv.integrationname, '') like '%' || coalesce(p_srvdptintegrationname,'') || '%'
    and txnitem.billstatus != 'cancel'
    and txnitem.billstatus != 'adtCancel'
    and coalesce(txnitem.returnstatus,0) != 1   -- null handling..  null or 0 => take this, 1 =>   don't Take this. 
    --REturn Today's data if null.. 
    and (txnitem.createdon)::date between coalesce(p_fromdate,(current_timestamp)::date) and coalesce(p_todate, (current_timestamp)::date)  
    
    and (pat.shortname || pat.patientcode || coalesce(pat.phonenumber, '') || srv.servicedepartmentname || txnitem.itemname) like  '%'||coalesce(p_searchtext,'')||'%'
    
    
    order by txnitem.billingtransactionitemid desc;
END;
$$ LANGUAGE plpgsql;