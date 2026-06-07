/*
[RPT_SP_ADT_RankMembershipwiseAdmittedPatientReport] '2023-1-12','2023-1-12', '1,2,3','SI,CON'
FileName: [RPT_SP_ADT_RankMembershipwiseAdmittedPatientReport]
CreatedBy/Date: Sanjeev/2023-1-13
Description: .
Remarks:    A
-- =============================================
Change History
S.No.    UpdatedBy/Date                        Remarks
1.      Sanjeev/2023-01-11          Initial Draft
2.      Sanjeev/2023-01-12          Added Rank-Membershipwise date filter
*/
CREATE OR REPLACE FUNCTION rpt_sp_adt_rankmembershipwiseadmittedpatientreport(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_memberships VARCHAR DEFAULT NULL,
    p_ranks VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "AdmissionDate" TIMESTAMP,
    "PatientCode" VARCHAR,
    "VisitCode" VARCHAR,
    "Rank" VARCHAR,
    "MembershipName" VARCHAR,
    "MembershipId" INT,
    "PatientName" VARCHAR,
    "BedCode" VARCHAR,
    "BedFeature" VARCHAR,
    "BedFeatureId" INT,
    "DepartmentName" VARCHAR,
    "DepartmentId" INT,
    "Address" VARCHAR,
    "PhoneNumber" TIMESTAMP,
    "Sex" VARCHAR
) AS $$
BEGIN
    
    	RETURN QUERY SELECT adm.admissiondate,
    		pat.patientcode,
    		visit.visitcode,
    		pat.rank,
    		meb.membershiptypename AS "MembershipName",
    		meb.membershiptypeid AS "MembershipId",
    		pat.shortname AS "PatientName",
    		bed.bedcode AS "BedCode",
    		bedf.bedfeaturename AS "BedFeature",
    		bedf.bedfeatureid,
    		dept.departmentname,
    		dept.departmentid,
    		pat.address,
    		pat.phonenumber,
    		pat.age || '/' || (pat.gender)::varchar as "age/sex"
    	from adt_patientadmission adm
    	inner join adt_txn_patientbedinfo adtpat
    		on adm.patientid = adtpat.patientid
    	inner join pat_patientvisits visit
    		on adm.patientvisitid = visit.patientvisitid
    	inner join pat_patient pat
    		on pat.patientid = visit.patientid
    	inner join adt_mst_ward ward
    		on ward.wardid = adtpat.wardid
    	inner join adt_bed bed
    		on bed.bedid = adtpat.bedid
    	inner join adt_map_bedfeaturesmap bedm
    		on bed.bedid = bedm.bedid
    	inner join adt_mst_bedfeature bedf
    		on bedm.bedfeatureid = bedf.bedfeatureid
    	inner join pat_cfg_membershiptype meb
    		on pat.membershiptypeid = meb.membershiptypeid
    	inner join mst_department dept
    		on dept.departmentid = adtpat.requestingdeptid
    	where ((adm.admissiondate)::date between p_fromdate and p_todate)
    		and (adm.admissionstatus = 'admitted')
    		and (pat.rank is not null)
    		and (
    			meb.membershiptypeid in (
    				select value
    				from string_split(p_memberships, ',')
    				)
    			or p_memberships = ''
    			)
    		and (
    			pat.rank in (
    				select value
    				from string_split(p_ranks, ',')
    				)
    			or p_ranks = ''
    			)
    	order by adm.admissiondate desc;
END;
$$ LANGUAGE plpgsql;