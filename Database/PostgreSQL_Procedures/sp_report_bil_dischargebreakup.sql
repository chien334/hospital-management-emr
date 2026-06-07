CREATE OR REPLACE FUNCTION sp_report_bil_dischargebreakup(
    p_patientvisitid INT DEFAULT NULL,
    p_patientid INT DEFAULT NULL
)
RETURNS TABLE (
    "departmentName" VARCHAR,
    "billDate" TIMESTAMP,
    "description" TIMESTAMP,
    "qty" INT,
    "amount" DECIMAL,
    "discount" INT,
    "subTotal" DECIMAL,
    "vat" VARCHAR,
    "total" DECIMAL
) AS $$
DECLARE
    v_fromdate TIMESTAMP;
    v_todate TIMESTAMP;
BEGIN
    /*
    filename: "sp_report_bil_dischargebreakup"
    createdby/date: nagesh/2018-07-21
    description: get billing details for discharge bill breakup for patient by visit id or patientid
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1       nagesh/2018-07-21          created need finalize for some improvements later
    2		nagesh/2018/08/20			updated as per dinesh sir guidance and hams requirement
    3		salakha/2019/09/09			updated to exclude cancelled billig items
    */
    
    begin
    begin 
    if(p_patientid is not null)
    then
    
    select admissiondate, dischargedate into v_fromdate, v_todate from adt_patientadmission
    where patientvisitid=p_patientvisitid;
    
    RETURN QUERY WITH bildischargecte as
      (
     select bti.billingtransactionitemid,dept.departmentname, 
    bti.servicedepartmentname,
    bti.paiddate AS "billDate", 
    bti.itemname AS "description",
    bti.quantity AS "qty",
    bti.subtotal AS "amount",
    bti.discountamount AS "discount",
    bti.taxableamount AS "subTotal",
    bti.tax AS "vat"
    ,bti.totalamount AS "total"
     from bil_txn_billingtransactionitems bti
     join bil_mst_servicedepartment sdept
     on sdept.servicedepartmentid=bti.servicedepartmentid
     join mst_department dept
     on dept.departmentid=sdept.departmentid
    --if user misses to select requestedbydr. in billing page, then patiengvisitid comes as null,
    --in that case we've to take from CreatedOn Field.---
     where PatientId=p_patientid and  ( bti.PatientVisitId=p_patientvisitid OR  bti.CreatedOn Between v_fromdate and v_todate ) and bti.BillStatus !='cancel' and bti.BillStatus !='adtcancel'     
    ) select 
    Case 
    WHEN "DepartmentName"='administration' and ServiceDepartmentName !='consumeables' THEN 'administrative'
    when ServiceDepartmentName='consumeables' then 'consumeables'
    WHEN "DepartmentName"='ot' and "DepartmentName"!='' THEN 'ot'
    when "Description"='bed charges' then 'bed'
    when "Description"='indoor-doctor''s visit fee (per day)' then 'doctor and nursing care'
    when "DepartmentName"='medicine' then 'medicine'
    WHEN "DepartmentName"='surgery' then 'surgery'
    else departmentname
    end
    AS "departmentName",
    billdate,"description",qty,amount,discount,subtotal,vat,total 
    from bildischargecte; 
    end if;
    end;  
    end;
END;
$$ LANGUAGE plpgsql;