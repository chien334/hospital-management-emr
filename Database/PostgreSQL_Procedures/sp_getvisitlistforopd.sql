CREATE OR REPLACE FUNCTION sp_getvisitlistforopd(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_searchtext VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "PatientId" INT,
    "PatientCode" VARCHAR,
    "ShortName" VARCHAR,
    "DateOfBirth" TIMESTAMP,
    "PhoneNumber" TIMESTAMP,
    "Gender" VARCHAR,
    "Address" VARCHAR,
    "Age" VARCHAR,
    "AdmittedDate" TIMESTAMP,
    "VisitDate" TIMESTAMP,
    "VisitTime" TIMESTAMP,
    "VisitType" VARCHAR,
    "PatientVisitId" INT,
    "PerformerName" VARCHAR,
    "PerformerId" INT,
    "DepartmentName" VARCHAR,
    "AppointmentType" VARCHAR,
    "IsTriaged" BOOLEAN
) AS $$
BEGIN
    /*
    filename: "sp_getvisitlistforopd"
    createdby/date: anjana/2020-06-23
    description: to get list of outpatient 
    
    change history
    s.no.    updatedby/date                        remarks
    1.      anjana/2020-06-23					initial draft
    2.      anjana/2020-07-09					updated hasvitals to istriaged for opd triage
    3.		krishna/2jun'22						changed ProviderName to PerformerName, ProviderId to PerformerId 
    4.      Santosh/1st Aug'23                  admissiondate and departmentname is added for investigation results
    */
    begin
    RETURN QUERY SELECT
      pat.patientid,
      pat.patientcode,
      pat.shortname,
      pat.dateofbirth,
      pat.phonenumber,
      pat.gender,
      pat.address,
      pat.age,
      adm.admissiondate AS "AdmittedDate",
      vis.visitdate,
      vis.visittime,
      vis.visittype,
      vis.patientvisitid,
      vis.performername,
      vis.performerid,
      dept.departmentname,
      vis.appointmenttype,
    
     case when vit.patientvisitid is not null then 1 else 0 end AS "IsTriaged"
    from 
     pat_patient pat 
         inner join
     pat_patientvisits vis
        on pat.patientid= vis.patientid
    	inner join mst_department dept on vis.departmentid = dept.departmentid
    left join
      (select distinct patientvisitid 
       from 
        cln_kv_patientclinical_info )
       vit
      on vis.patientvisitid = vit.patientvisitid
      	left join adt_patientadmission adm on  pat.patientid = adm.patientid and vit.patientvisitid = adm.patientvisitid
    
     
    where  
    vis.visittype = 'outpatient'
    and vis.billingstatus != 'cancel'
    and vis.billingstatus != 'returned'
    
    and (vis.createdon)::date between coalesce(p_fromdate,(current_timestamp)::date) and coalesce(p_todate, (current_timestamp)::date);
    end;
END;
$$ LANGUAGE plpgsql;