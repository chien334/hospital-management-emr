CREATE OR REPLACE FUNCTION sp_dashboard_phrm_membershipwisemedicinesale(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL
)
RETURNS TABLE (
    "MembershipTypeName" VARCHAR,
    "TotalSales" DECIMAL,
    "QuantitySold" INT
) AS $$
BEGIN
    /*
     sp_dashboard_phrm_membershipwisemedicinesale '2022-10-3','2022-10-31'
    filename: "sp_dashboard_phrm_membershipwisemedicinesale"
    createdby/date: rohit/2022-12-30
    description: to get information of membership wise sales.
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1       rohit/2022-12-30                 created the script
    */
    
    
    RETURN QUERY SELECT  mem.membershiptypename
    	,sum(invoice.totalamount) AS "TotalSales"
    	,sum(invoice.quantity) AS "QuantitySold"
    from pat_patient pat
    inner join pat_cfg_membershiptype mem on pat.membershiptypeid = mem.membershiptypeid
    inner join (
    		select inv.patientid,
    			sum(inv.subtotal) as "totalamount",
    			sum(invitm.quantity) as "quantity"
    		from phrm_txn_invoice inv
    		inner join phrm_txn_invoiceitems invitm on inv.invoiceid = invitm.invoiceid
    		where (inv.createon)::date between p_fromdate and p_todate
    		group by inv.patientid
    	) invoice on invoice.patientid = pat.patientid
    group by mem.membershiptypename
    order by sum(invoice.totalamount) desc limit 10;
END;
$$ LANGUAGE plpgsql;