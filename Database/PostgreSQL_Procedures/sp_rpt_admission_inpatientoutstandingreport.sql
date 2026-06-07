CREATE OR REPLACE FUNCTION sp_rpt_admission_inpatientoutstandingreport(
    p_operator VARCHAR DEFAULT NULL,
    p_amount DECIMAL DEFAULT NULL
)
RETURNS TABLE (
    "SchemeName" VARCHAR,
    "PriceCategoryName" DECIMAL,
    "PatientName" VARCHAR,
    "IPNo" VARCHAR,
    "PolicyNo" VARCHAR,
    "HospitalNo" VARCHAR,
    "ContactNo" TIMESTAMP,
    "Address" VARCHAR,
    "DateOfBirth" TIMESTAMP,
    "AgeSex" VARCHAR,
    "WardBed" VARCHAR,
    "AdmittedOn" TIMESTAMP,
    "TotalDays" DECIMAL,
    "ProvisionalServiceAmount" TIMESTAMP,
    "CreditServiceAmount" DECIMAL,
    "PharmacyCreditAmount" DECIMAL,
    "PharmacyProvisionalAmount" TIMESTAMP,
    "DepositBalance" DECIMAL,
    "TotalAmount" DECIMAL,
    "TotalDueAmount" DECIMAL,
    "CarePersonName" TIMESTAMP,
    "CarePersonContact" TIMESTAMP
) AS $$
BEGIN
    /*  
     filename: "sp_rpt_admission_inpatientoutstandingreport"   
     created: 11-sept'23/Nirmala  
     Description: To Get the InPatients Info with outstanding Billing Status.  
     Change History  
     S.No.    Date/User              Change          Remarks  
     1.      11-Sept'23/nirmala                      inital draft   
    */
    
    RETURN QUERY SELECT * from(
    select 
    	ipvisit.schemename AS "SchemeName",
    	ipvisit.pricecategoryname AS "PriceCategoryName",
    	pat.shortname AS "PatientName",
    	ipvisit.visitcode AS "IPNo",
    	ipvisit.policyno,
    	pat.patientcode AS "HospitalNo",
    	pat.phonenumber AS "ContactNo",
    	pat.address AS "Address",
    	pat.dateofbirth AS "DateOfBirth",
    	concat(datediff(year, pat.dateofbirth, ipvisit.visitdate), 'Y', '/', substring(pat.gender, 0, 2)) AS "AgeSex",
    	ipvisit.wardbed AS "WardBed",
    	ipvisit.admissiondate AS "AdmittedOn",
    	datediff(day,ipvisit.admissiondate, current_timestamp) AS "TotalDays",
    	coalesce(itms.provisionalservicetotal,0) AS "ProvisionalServiceAmount",
    	coalesce(billdetails.creditservicetotal,0) AS "CreditServiceAmount",
    	coalesce(invoicedetails.pharmacycredittotal,0) AS "PharmacyCreditAmount",
    	coalesce(provisionaldetails.pharmacyprovisionaltotal,0) AS "PharmacyProvisionalAmount",
    	coalesce(dep.totaldeposit,0) AS "DepositBalance",
    	coalesce(itms.provisionalservicetotal, 0) + (coalesce(billdetails.creditservicetotal,0)) +
    	(coalesce(invoicedetails.pharmacycredittotal,0)) +
    	coalesce(provisionaldetails.pharmacyprovisionaltotal,0) AS "TotalAmount",
    	(coalesce(itms.provisionalservicetotal, 0) + (coalesce(billdetails.creditservicetotal,0)) +
    	(coalesce(invoicedetails.pharmacycredittotal,0)) +
    	coalesce(provisionaldetails.pharmacyprovisionaltotal,0)) - coalesce(dep.totaldeposit,0) AS "TotalDueAmount",
    	ipvisit.careofpersonname AS "CarePersonName",
    	ipvisit.careofpersonphoneno AS "CarePersonContact"
    from pat_patient pat
    inner join (select 
    			adm.patientid, adm.patientvisitid, adm.admissiondate, visit.visitdate, adm.careofpersonname,adm.careofpersonphoneno,visit.visitcode,
    			scheme.schemename, pricecat.pricecategoryname,patscheme.policyno,
    			concat(wardbedinfo.wardname, '/', wardbedinfo.bedcode) AS "WardBed"
    			from (select visitcode, visitdate, patientvisitid, patientid, schemeid, pricecategoryid
    					from pat_patientvisits where visittype = 'inpatient') visit 
    			inner join (select patientid,patientvisitid, admissiondate, careofpersonname, careofpersonphoneno 
    						from adt_patientadmission 
    						where dischargedate is null) adm on visit.patientvisitid = adm.patientvisitid 
    			inner join bil_cfg_scheme scheme on scheme.schemeid = visit.schemeid
    			inner join pat_map_patientschemes patscheme on patscheme.schemeid = scheme.schemeid and patscheme.latestpatientvisitid = visit.patientvisitid
    			inner join bil_cfg_pricecategory pricecat on pricecat.pricecategoryid = visit.pricecategoryid
    			left join lateral (select ward.wardname,bed.bedcode from 
    					(select  bedid, wardid from adt_txn_patientbedinfo 
    					where patientvisitid = adm.patientvisitid order by patientbedinfoid desc limit 1) bedinfo
    					inner join adt_bed bed on bedinfo.bedid = bed.bedid
    					inner join adt_mst_ward ward on bedinfo.wardid = ward.wardid) wardbedinfo on true
    			) ipvisit on ipvisit.patientid = pat.patientid
    inner join (select patientvisitid, patientid, sum(totalamount) as "provisionalservicetotal"
    				from bil_txn_billingtransactionitems where billstatus = 'provisional'
    			group by patientvisitid, patientid) itms 
    		on ipvisit.patientvisitid = itms.patientvisitid
    left join (
    		select bilitems.patientid, bilitems.patientvisitid,
    		sum(bilitems.totalamount - coalesce(bilretitems.returnedtotalamount,0)) as "creditservicetotal" 
    		from bil_txn_billingtransactionitems  bilitems
    		left join (select billingtransactionitemid,sum(rettotalamount) as "returnedtotalamount" 
    					from bil_txn_invoicereturnitems 
    					group by billingtransactionitemid) bilretitems 
    					on bilitems.billingtransactionitemid = bilretitems.billingtransactionitemid
    		where bilitems.billstatus='unpaid'
    		group by bilitems.patientid, bilitems.patientvisitid) billdetails 
    		on ipvisit.patientvisitid = billdetails.patientvisitid
    left join (select patientvisitid, (sum(inamount) - sum(outamount)) as "totaldeposit" 
    			from bil_txn_deposit group by patientvisitid) dep on dep.patientvisitid = ipvisit.patientvisitid
    left join (
    		select invitems.patientid, invitems.patientvisitid,
    		sum(invitems.totalamount - coalesce(invretitems.returnedtotalamount,0)) as "pharmacycredittotal" 
    		from phrm_txn_invoiceitems  invitems
    			left join (select invoiceitemid,sum(totalamount) as "returnedtotalamount"
    				from phrm_txn_invoicereturnitems  
    				group by invoiceitemid) invretitems on invitems.invoiceitemid = invretitems.invoiceitemid
    		where invitems.bilitemstatus='unpaid'
    		group by invitems.patientid, invitems.patientvisitid) invoicedetails 
    		on ipvisit.patientvisitid = invoicedetails.patientvisitid
    left join (
    		  select invitems.patientid, invitems.patientvisitid,
    		  sum(invitems.totalamount) as "pharmacyprovisionaltotal" 
    		  from phrm_txn_invoiceitems  invitems
    		  where invitems.bilitemstatus='provisional' 
    		  group by invitems.patientid, invitems.patientvisitid) provisionaldetails 
    		  on ipvisit.patientvisitid = provisionaldetails.patientvisitid
    )result
    where ((p_operator = 'LessThanOrEqualsTo' and result.totaldueamount <= p_amount) 
    		or (p_operator = 'GreaterThanOrEqualsTo' and result.totaldueamount >= p_amount)
    	    or  p_operator is null
    	    or p_amount is null);
END;
$$ LANGUAGE plpgsql;