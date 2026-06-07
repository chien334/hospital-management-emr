CREATE OR REPLACE FUNCTION sp_phrmreport_ledgercredit_indooroutdoorpatient(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_isinoutpat BOOLEAN DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
BEGIN
    /*
    filename: "sp_phrmreport_ledgercredit_indooroutdoorpatient"
    createdby/date: umed/2018-02-21
    description: to get patient sale credit details based on patient type
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1       umed/2018-02-21	                 created the script
                                            i.e. to get patient sale credit details based on patient type
    2		rusha/2019-05-03				recreated the script to get patient sale credit details based on patient type
    3       shankar/2020-06-01				added organization name and remark
    */
    begin
    	if (p_fromdate is not null and p_todate is not null and p_isinoutpat = true)
    			then
    				open ref1 for select (inv.createon)::date as "date",inv.invoiceprintid as invoicenum,pat.patientcode, coalesce(cr.organizationname,'N/A') as "organizationname", inv.remark,
    				concat_ws(' ',pat.firstname,pat.middlename,pat.lastname) as patientname,pat.address,inv.paidamount,inv.visittype 
    				from phrm_txn_invoice as inv
    				left join phrm_mst_credit_organization as cr on inv.organizationid = cr.organizationid
    				join pat_patient as pat on pat.patientid = inv.patientid
    				where inv.visittype='outpatient' and  inv.paymentmode='credit' and (inv.createon)::date between coalesce(p_fromdate,current_timestamp)  and coalesce(p_todate,current_timestamp)+1
    				group by (inv.createon)::date,pat.firstname,pat.middlename,pat.lastname,pat.patientcode,inv.paidamount,inv.visittype, inv.invoiceprintid,pat.address, organizationname, inv.remark;
        return next ref1;
    			
    			elsif (p_isinoutpat = false)
    			then
    				open ref2 for select (inv.createon)::date as "date",inv.invoiceprintid as invoicenum,pat.patientcode, coalesce(cr.organizationname,'N/A') as "organizationname", inv.remark,
    				concat_ws(' ',pat.firstname,pat.middlename,pat.lastname) as patientname,pat.address,inv.paidamount,inv.visittype 
    				from phrm_txn_invoice as inv
    				left join phrm_mst_credit_organization as cr on inv.organizationid = cr.organizationid
    				join pat_patient as pat on pat.patientid = inv.patientid
    				where inv.visittype='inpatient' and  inv.paymentmode='credit'and (inv.createon)::date between coalesce(p_fromdate,current_timestamp)  and coalesce(p_todate,current_timestamp)+1
    				group by (inv.createon)::date,pat.firstname,pat.middlename,pat.lastname,pat.patientcode,inv.paidamount,inv.visittype, inv.invoiceprintid,pat.address, organizationname, inv.remark;
        return next ref2;
    			end if;
    end;
END;
$$ LANGUAGE plpgsql;