CREATE OR REPLACE FUNCTION sp_rpt_rankmembershipwisedischargedpatientreport(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_membershipttypeids VARCHAR DEFAULT NULL,
    p_rank VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "HospitalNo" VARCHAR,
    "IPNumber" VARCHAR,
    "Rank" VARCHAR,
    "Membership" VARCHAR,
    "PatientName" VARCHAR,
    "Age" VARCHAR,
    "Gender" VARCHAR,
    "AgeSex" VARCHAR,
    "Address" VARCHAR,
    "PhoneNumber" TIMESTAMP,
    "AdmissionDate" TIMESTAMP,
    "DischargedDate" TIMESTAMP
) AS $$
BEGIN
    /*
    "sp_rpt_rankmembershipwisedischargedpatientreport" '2023-1-12','2023-1-12', '1,2,3','SI,CON'
    filename: "sp_rpt_rankmembershipwisedischargedpatientreport"
    createdby/date:santosh/2023-1-13
    description: .
    remarks:    a
    change history
    s.no.    updatedby/date                        remarks
    1       santosh/2023-1-13                created the script for rank-membership wise discharged patient report
    */
      
      
    RETURN QUERY SELECT   
    pat.patientcode AS "HospitalNo",  
    visit.visitcode AS "IPNumber",  
    pat.rank,  
    memtype.membershiptypename AS "Membership",  
    pat.shortname AS "PatientName",   
    pat.age,  
    pat.gender,  
    pat.age || '/' || pat.gender AS "AgeSex",  
    pat.address,  
    pat.phonenumber,  
    adm.admissiondate,  
    adm.dischargedate AS "DischargedDate"  
      
    from pat_patient as pat  
    inner join pat_patientvisits as visit on pat.patientid = visit.patientid  
    inner join pat_cfg_membershiptype as memtype on pat.membershiptypeid = memtype.membershiptypeid   
    inner join adt_patientadmission as adm on visit.patientvisitid = adm.patientvisitid  
    where adm.admissionstatus ='discharged' and pat.rank is not null  and (visit.visitdate)::date between p_fromdate and p_todate   
    and (  
          pat.rank in (  
            select value  
            from string_split(p_rank, ',')  
            )  
          or p_rank = ''  
          )  
        and (  
          memtype.membershiptypeid in (  
            select value  
            from string_split(p_membershipttypeids, ',')  
            )  
          or p_membershipttypeids = ''  
          );
END;
$$ LANGUAGE plpgsql;