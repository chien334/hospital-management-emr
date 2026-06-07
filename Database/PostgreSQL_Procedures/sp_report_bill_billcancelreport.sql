CREATE OR REPLACE FUNCTION sp_report_bill_billcancelreport(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL
)
RETURNS TABLE (
    "HospitalNo" VARCHAR,
    "PatientName" VARCHAR,
    "ServiceDepartmentName" VARCHAR,
    "ItemName" VARCHAR,
    "Quantity" INT,
    "TotalAmount" DECIMAL,
    "CreatedOn" TIMESTAMP,
    "CreatedBy" VARCHAR,
    "CancelledOn" TIMESTAMP,
    "CancelledBy" VARCHAR,
    "CancelRemarks" VARCHAR
) AS $$
BEGIN
    /*
    filename: "[sp_report_bill_billcancelreport"]
    createdby/date: umed/20-07-2017
    description: to get sum of total amount of cancel bill of each patient between given dates 
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1       umed/20-07-2017	                   created the script
    2       umed/31-07-2017                    alter the script added cancel remarks and user
    3       pratik/2020-07-30                  added itemname,servicedepartmentname etc col
    */
    
        
    RETURN QUERY SELECT  pat.patientcode AS "HospitalNo",
    		 pat.shortname AS "PatientName",
    		 bltxnitm.servicedepartmentname AS "ServiceDepartmentName",
    		 bltxnitm.itemname AS "ItemName",
    		 bltxnitm.quantity AS "Quantity",
    		 coalesce(bltxnitm.totalamount,0) AS "TotalAmount",
    		 bltxnitm.createdon AS "CreatedOn" ,
    		 emp.fullname AS "CreatedBy",
    		 bltxnitm.cancelledon AS "CancelledOn",
    		 empcancel.fullname AS "CancelledBy",
    		 bltxnitm.cancelremarks AS "CancelRemarks"
    
    from bil_txn_billingtransactionitems bltxnitm
    inner join pat_patient pat on pat.patientid = bltxnitm.patientid
    inner join emp_employee emp on emp.employeeid = bltxnitm.createdby
    inner join emp_employee empcancel on empcancel.employeeid = bltxnitm.cancelledby
    where  
     (bltxnitm.cancelledon)::date between coalesce(p_fromdate,current_timestamp) and coalesce(p_todate,current_timestamp)
    	  and bltxnitm.billstatus='cancel'
    	  and bltxnitm.cancelledon is not null
    order by bltxnitm.cancelledon desc;
END;
$$ LANGUAGE plpgsql;