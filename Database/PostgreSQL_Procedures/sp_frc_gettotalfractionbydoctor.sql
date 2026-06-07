CREATE OR REPLACE FUNCTION sp_frc_gettotalfractionbydoctor(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL
)
RETURNS TABLE (
    "DoctorName" VARCHAR,
    "EmployeeId" INT,
    "ItemName" VARCHAR,
    "Price" DECIMAL,
    "FractionAmount" TIMESTAMP,
    "CreatedOn" TIMESTAMP
) AS $$
BEGIN
    begin
    if(p_fromdate is not null or p_todate is not null)
    then
     RETURN QUERY SELECT   coalesce(emp.salutation||' ','')|| emp.firstname||coalesce(' '||emp.middlename,'')||' '|| emp.lastname AS "DoctorName",
     emp.employeeid,
     billingitems.itemname,
     billingitems.totalamount AS "Price",
     frac.finalamount AS "FractionAmount",
     frac.createdon from frc_fractioncalculation frac
    join bil_txn_billingtransactionitems billingitems on frac.billtxnitemid= billingitems.billingtransactionitemid
    join emp_employee emp on emp.employeeid= frac.doctorid
    where (frac.createdon)::date between p_fromdate and p_todate
    order by frac.createdon;
    end if;
    end;
END;
$$ LANGUAGE plpgsql;