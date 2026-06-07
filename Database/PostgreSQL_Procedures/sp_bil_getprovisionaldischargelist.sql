CREATE OR REPLACE FUNCTION sp_bil_getprovisionaldischargelist(

)
RETURNS TABLE (
    "IpNumber" VARCHAR,
    "HospitalNumber" VARCHAR,
    "PatientName" VARCHAR,
    "Gender" VARCHAR,
    "DateOfBirth" TIMESTAMP,
    "Contacts" TIMESTAMP,
    "WardBed" VARCHAR,
    "DepositAmount" DECIMAL,
    "AdmittedOn" TIMESTAMP,
    "ProvisionalDischargedOn" TIMESTAMP,
    "ProvisionalDischargedBy" TIMESTAMP,
    "Remarks" VARCHAR,
    "PatientId" INT,
    "SchemeId" INT,
    "PatientVisitId" INT,
    "PriceCategoryId" INT
) AS $$
BEGIN
    /*
    filename: sp_bil_getprovisionaldischargelist
    author/date: krishna, 5thsept'23
    eg: exec SP_BIL_GetProvisionalDischargeList
    Description: This SP will give the list of in-patients who are discharged provisionally but their discharge 
    			 invoice is not generated.
    
    Change History:
    S.N.	UpdatedBy/Date                        Remarks  
    1.	    Krishna,5thSept'23					  initial script
    */
    
    RETURN QUERY SELECT 
    	visit.visitcode AS "IpNumber",
    	pat.patientcode AS "HospitalNumber",
    	pat.shortname AS "PatientName",
    	pat.gender AS "Gender",
    	pat.dateofbirth AS "DateOfBirth",
    	iif(coalesce(adm.careofpersonphoneno, '') <> '', concat(pat.phonenumber, '/', adm.careofpersonphoneno), pat.phonenumber) AS "Contacts",
    	concat(wardbedinfo.wardname, '/', wardbedinfo.bedcode) AS "WardBed",
    	dep.depositbalance AS "DepositAmount",
    	adm.admissiondate AS "AdmittedOn",
    	adm.dischargedate AS "ProvisionalDischargedOn",
    	emp.fullname AS "ProvisionalDischargedBy",
    	adm.dischargeremarks AS "Remarks",
    	pat.patientid,
    	adm.discountschemeid AS "SchemeId",
    	adm.patientvisitid,
    	visit.pricecategoryid
    
    from (select admissiondate, dischargedate, careofpersonphoneno, 
    			 dischargeremarks, patientid, patientvisitid, dischargedby, discountschemeid from adt_patientadmission 
    	  where isprovisionaldischarge = 1 
    			and isprovisionaldischargecleared = 0
    			and admissionstatus = 'discharged') adm
    inner join pat_patientvisits visit on adm.patientvisitid = visit.patientvisitid
    inner join pat_patient pat on adm.patientid = pat.patientid
    left join (select patientid,(sum(coalesce(inamount,0)) - sum(coalesce(outamount,0))) as "depositbalance" from bil_txn_deposit 
    				group by patientid) dep on adm.patientid = dep.patientid
    inner join emp_employee emp on adm.dischargedby = emp.employeeid
    left join lateral (select ward.wardname,bed.bedcode from 
    			 (select  bedid, wardid from adt_txn_patientbedinfo 
    			 where patientvisitid = adm.patientvisitid order by patientbedinfoid desc limit 1) bedinfo
    			 inner join adt_bed bed on bedinfo.bedid = bed.bedid
    			 inner join adt_mst_ward ward on bedinfo.wardid = ward.wardid) wardbedinfo on true
    order by adm.dischargedate desc;
END;
$$ LANGUAGE plpgsql;