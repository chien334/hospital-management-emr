CREATE OR REPLACE FUNCTION sp_report_bil_pat_packagesalesdetail(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL
)
RETURNS TABLE (
    "BillingTransactionId" INT,
    "InvoiceNo" VARCHAR,
    "IssuedDate" TIMESTAMP,
    "PatientId" INT,
    "PatientVisitId" INT,
    "HospitalNo" VARCHAR,
    "PatientName" VARCHAR,
    "AgeSex" VARCHAR,
    "PackageName" VARCHAR,
    "Price" DECIMAL,
    "RequestedBy" VARCHAR
) AS $$
BEGIN
    /*  
    filename: "sp_report_bil_pat_packagesalesdetail" '2017-10-09','2019-11-29'   
    createdby/date: sanjit 12-2-2019  
    description: to get the details of package sale from billing  
    remarks:      
    change history  
    s.no.    updatedby/date                        remarks  
    1.  
    2.		krishna/9thjun'22					changed RequestedBy to PrescriberId
    3.		Krishna/15thDec'22					date filter issue fixed, removed +1 from todate
    */  
      
    begin  
      if ((p_fromdate is not null) and (p_todate is not null))  
      then  
       RETURN QUERY SELECT distinct btx.billingtransactionid AS "BillingTransactionId", concat(btx.invoicecode,btx.invoiceno) AS "InvoiceNo", (btx.createdon)::date AS "IssuedDate",btx.patientid,btx.patientvisitid, pat.patientcode AS "HospitalNo",   
       concat_ws(' ',pat.firstname, pat.middlename,pat.lastname) AS "PatientName",  
       pat.age|| '/' || substring(pat.gender, 1, 1) AS "AgeSex",btx.packagename,btx.totalamount AS "Price"  
       ,coalesce(emp.fullname,'SELF') AS "RequestedBy"  
       from bil_txn_billingtransaction as btx  
       join bil_txn_billingtransactionitems as btxitm on btx.billingtransactionid = btxitm.billingtransactionid  
       join pat_patient as pat on pat.patientid = btx.patientid  
       left join emp_employee as emp on emp.employeeid = btxitm.prescriberid  
       where btx.packageid>0 
       and (btx.createdon)::date between coalesce((p_fromdate)::date,(current_timestamp)::date)  
       and coalesce((p_todate)::date,(current_timestamp)::date)
       order by billingtransactionid desc;  
      end if;   
    end;
END;
$$ LANGUAGE plpgsql;