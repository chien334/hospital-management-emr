CREATE OR REPLACE FUNCTION sp_phrm_salereturnreport(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL
)
RETURNS TABLE (
    "Date" TIMESTAMP,
    "InvDate" TIMESTAMP,
    "InvoicePrintId" INT,
    "UserName" VARCHAR,
    "PatientName" VARCHAR,
    "TotalAmount" DECIMAL,
    "Discount" INT,
    "Quantity" INT
) AS $$
BEGIN
    /*
    filename:"sp_phrm_salereturnreport"
    createdby/date: vikas/2018-08-06
    description: .
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1      vikas/2018-08-06                       created the script
    2.     vikas/2019-01-02               report doesnt shown correctly so changes in script. 
    3.     rusha/2019-04-09             report doesnot show quantity so add return quantity
    4.     rusha/2019-07-03             report doesnot showing correct amount so updated script
    5.     abhishek/2019-07-03             report doesnot showing correct amount so updated script
    */
     begin
      if ((p_fromdate is not null) and (p_todate is not null)) 
        then
              RETURN QUERY SELECT (invr.createdon)::date as"date",(inv.createon)::date AS "InvDate", 
               inv.invoiceprintid,usr.username,
                pat.firstname||' '|| coalesce( pat.middlename,'')||' '||pat.lastname  AS "PatientName",
              sum(invr.totalamount) AS "TotalAmount", sum(inv.discountamount) AS "Discount", sum(invr.returnedqty) AS "Quantity"
                from "phrm_txn_invoice"inv
               join "phrm_txn_invoicereturnitems"invr
                  on inv.invoiceid=invr.invoiceid
              join rbac_user usr
                  on usr.employeeid=invr.createdby 
              join pat_patient pat
                  on pat.patientid=inv.patientid
                    where  (invr.createdon)::date   between coalesce(p_fromdate,current_timestamp)  and coalesce(p_todate,current_timestamp)
                    
              group by (inv.createon)::date, (invr.createdon)::date,usr.username, 
              pat.firstname,pat.middlename,pat.lastname, inv.invoiceprintid
              order by (invr.createdon)::date desc;
    
      end if;
    end;
END;
$$ LANGUAGE plpgsql;