CREATE OR REPLACE FUNCTION sp_nur_getopdvisitdetails(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL
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
    "VisitDate" TIMESTAMP,
    "VisitTime" TIMESTAMP,
    "VisitType" VARCHAR,
    "PatientVisitId" INT,
    "PerformerName" VARCHAR,
    "PerformerId" INT,
    "AppointmentType" VARCHAR,
    "VisitStatus" VARCHAR,
    "IsTriaged" BOOLEAN,
    "DepartmentName" VARCHAR,
    "SchemeName" VARCHAR,
    "DepartmentId" INT
) AS $$
BEGIN
    /*
    filename: "sp_nur_getopdvisitdetails"
    createdby/date: anjana/2020-06-23
    description: to get list of outpatient 
    note: renamed from: sp_getvisitlistforopd
    change history
    s.no.    updatedby/date                        remarks
    1.      anjana/2020-06-23					initial draft
    2.      anjana/2020-07-09					updated hasvitals to istriaged for opd triage
    3.		krishna/2jun'22						changed ProviderName to PerformerName, ProviderId to PerformerId 
    4.      Santosh/23April'23                  read department and schemename
    5.      krishna/sud:25apr'23                Changed IsTriaged Condition, Dropped old sp 'sp_getvisitlistforopd' and Recreated this.
    6.      Bibek: 21May'23                     add filter visitstatus = 'initiated'
    7.      santosh/10july"23                   add filter visitstatus = 'checkedin'
    */
     
    RETURN QUERY SELECT
      pat.patientid,
      pat.patientcode,
      pat.shortname,
      pat.dateofbirth,
      pat.phonenumber,
      pat.gender,
      pat.address,
      pat.age,
      vis.visitdate,
      vis.visittime,
      vis.visittype,
      vis.patientvisitid,
      vis.performername,
      vis.performerid,
      vis.appointmenttype,
      vis.visitstatus,
      vis.istriaged AS "IsTriaged",
      dept.departmentname,
      sch.schemename,
      dept.departmentid
    
    from 
     pat_patient pat 
         inner join
     pat_patientvisits vis
        on pat.patientid= vis.patientid	
      inner join 
      mst_department as dept
      on dept.departmentid = vis.departmentid
      inner join 
      bil_cfg_scheme as sch
      on sch.schemeid = vis.schemeid
    
    where  
    vis.visittype = 'outpatient'
    	 and vis.billingstatus != 'cancel'
    	 and vis.billingstatus != 'returned'
    	 and( vis.visitstatus = 'initiated'
    	 or vis.visitstatus = 'checkedin')
    and (vis.createdon)::date between p_fromdate and p_todate;
END;
$$ LANGUAGE plpgsql;