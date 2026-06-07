CREATE OR REPLACE FUNCTION sp_phrmreport_billingreport(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_invoicenumber INT DEFAULT NULL
)
RETURNS TABLE (
    "InvoiceDate" TIMESTAMP,
    "InvoicePrintId" INT,
    "HospitalNo" VARCHAR,
    "PatientName" VARCHAR,
    "UserName" VARCHAR,
    "SubTotal" DECIMAL,
    "DiscountAmount" INT,
    "TotalAmount" DECIMAL,
    "ReceivedAmount" DECIMAL,
    "CreditAmount" DECIMAL,
    "PaymentMode" VARCHAR,
    "StoreName" VARCHAR,
    "StoreId" INT
) AS $$
BEGIN
    /*
    filename: "sp_phrmreport_billingreport"
    createdby/date: umed/2018-02-23
    description: to get the details such as itemname, itemcode, expiry, purchaserate, purchasevalue,salesrate, salesvalue of each item against each invoice number
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1       umed/2018-02-23             created the script
                                        (to get the details such as itemname, itemcode, expiry, purchaserate, purchasevalue,salesrate, salesvalue of each item against each invoice number)
    2       rusha/2019-04-29            recreated the script
    3.      sanjit/sud/2021-08-10       removed group by from the query
    4.		sanjit/sud/pawan/2021-09-01	removed double query for invoicenumber null check, changed timestamp to date in p_fromdate, p_todate
    									removed p_todate+1 logic from where condition
    									added subtotal, storename, storeid
    5.		rohit/12sept'22				added received amount and creditamount and also ordered by invoice created date
    */
    
    
    	RETURN QUERY SELECT (inv.createon)::date AS "InvoiceDate", inv.invoiceprintid, pat.patientcode AS "HospitalNo", pat.shortname AS "PatientName", emp.fullname AS "UserName", inv.subtotal, inv.discountamount, inv.totalamount,inv.receivedamount,inv.totalamount-inv.receivedamount AS "CreditAmount", inv.paymentmode, store.name AS "StoreName", store.storeid
    	from phrm_txn_invoice as  inv
    		inner join pat_patient as pat on pat.patientid=inv.patientid
    		inner join emp_employee as emp on inv.createdby = emp.employeeid
    		inner join phrm_mst_store store on inv.storeid = store.storeid
    	where (inv.invoiceprintid = p_invoicenumber or coalesce(p_invoicenumber,0) = 0) and ( (inv.createon)::date between p_fromdate and p_todate )
    	order by inv.invoiceprintid desc;
END;
$$ LANGUAGE plpgsql;