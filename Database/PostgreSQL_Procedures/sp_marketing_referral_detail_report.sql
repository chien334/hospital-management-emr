CREATE OR REPLACE FUNCTION sp_marketing_referral_detail_report(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_referringpartyid INT DEFAULT NULL
)
RETURNS TABLE (
    "InvoiceNoFormatted" VARCHAR,
    "InvoiceDate" TIMESTAMP,
    "PatientName" VARCHAR,
    "HospitalNo" VARCHAR,
    "ReferringPartyName" VARCHAR,
    "GroupName" VARCHAR,
    "ReferringOrganizationName" TIMESTAMP,
    "VehicleNumber" VARCHAR,
    "ReferralSchemeName" VARCHAR,
    "InvoiceNetAmount" DECIMAL,
    "Percentage" VARCHAR,
    "ReferralAmount" DECIMAL,
    "Remarks" VARCHAR,
    "EnteredBy" VARCHAR,
    "EnteredOn" TIMESTAMP
) AS $$
BEGIN
    /* 
    exec "sp_marketing_referral_detail_report" '2015-01-01', '2023-08-13'
    change history
    s.no.    updatedby/date                        remarks
    1        bibek/2023-08-13                   created initial script 
    */
    
     RETURN QUERY SELECT   
    	rc.invoicenoformatted,
        rc.invoicedate AS "InvoiceDate",
        pat.shortname AS "PatientName",
        pat.patientcode AS "HospitalNo",
        rp.referringpartyname,
        rpg.groupname,
        ro.referringorganizationname,
        coalesce(rp.vehiclenumber, '') AS "VehicleNumber",
        rs.referralschemename,
        rc.invoicenetamount AS "InvoiceNetAmount",
        rc.percentage,	
        rc.referralamount,
        rc.remarks,
        emp.fullname AS "EnteredBy",
        rc.createdon AS "EnteredOn"
    from (select patientid,invoicenoformatted,invoicedate,invoicenetamount,
    				percentage,referralamount,remarks,createdby,createdon,referringpartyid,
    				referralschemeid,fiscalyearid from mkt_txn_referralcommission
    				where invoicedate between p_fromdate and p_todate and isactive = 1 
    					and coalesce(p_referringpartyid, referringpartyid) = referringpartyid) rc 
    inner join pat_patient pat on rc.patientid = pat.patientid
    inner join mkt_cfg_referringparty rp on rc.referringpartyid = rp.referringpartyid
    inner join mkt_mst_referringorganization ro on rp.referringorgid = ro.referringorganizationid
    inner join mkt_mst_referringpartygroup rpg on rp.referringpartygroupid = rpg.referringpartygroupid
    inner join mkt_mst_referralscheme rs on rc.referralschemeid = rs.referralschemeid
    inner join bil_cfg_fiscalyears fy on rc.fiscalyearid = fy.fiscalyearid
    inner join emp_employee emp on rc.createdby = emp.employeeid
    
    order by rc.invoicedate desc;
END;
$$ LANGUAGE plpgsql;