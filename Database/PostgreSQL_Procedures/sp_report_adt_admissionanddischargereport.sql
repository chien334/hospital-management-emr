/*
-- =============================================
Change History
S.No.    UpdatedBy/Date                        Remarks
1.      Dev Narayan/2021-09-25          Initial Draft
2.      Dev Narayan/2021-09-29          Added Discharge date filter
*/
CREATE OR REPLACE FUNCTION sp_report_adt_admissionanddischargereport(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_wardid INT DEFAULT NULL,
    p_departmentid INT DEFAULT NULL,
    p_bedfeatureid INT DEFAULT NULL,
    p_admissionstatus VARCHAR DEFAULT NULL,
    p_searchtext VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "SN" VARCHAR,
    "PatientName" VARCHAR,
    "PatientCode" VARCHAR,
    "VisitCode" VARCHAR,
    "AdmissionDate" TIMESTAMP,
    "DepartmentName" VARCHAR,
    "AdmittingDoctorName" VARCHAR,
    "WardName" VARCHAR,
    "BedFeature" VARCHAR,
    "AdmissionStatus" TIMESTAMP,
    "DischargeDate" TIMESTAMP,
    "Number_of_Days" VARCHAR
) AS $$
BEGIN
    begin
    p_wardid := coalesce(p_wardid, 0);
    p_departmentid := coalesce(p_departmentid, 0);
    p_bedfeatureid := coalesce(p_bedfeatureid, 0);
    if(p_admissionstatus like '%All%')
    then
    p_admissionstatus := null;
    end if;
    RETURN QUERY SELECT 
      (
        cast(
          row_number() over (
            order by 
              newdata.rownum desc
          ) as int
        )
      ) AS "SN", 
      newdata.patientname, 
      newdata.patientcode, 
      newdata.visitcode, 
      newdata.admissiondate, 
      newdata.departmentname, 
      newdata.admittingdoctorname, 
      newdata.wardname, 
      newdata.bedfeature, 
      newdata.admissionstatus, 
      newdata.dischargedate, 
      newdata.number_of_days
    from 
      (
        select 
          row_number() over(
            partition by adm.patientadmissionid 
            order by 
              adtpat.startedon desc
          ) as rownum, 
          adm.patientadmissionid, 
          adm.admissiondate, 
          pat.patientcode, 
          visit.visitcode, 
          pat.firstname || ' ' || coalesce(pat.middlename || ' ', '') || pat.lastname AS "PatientName", 
          coalesce(emp.salutation || '. ', '') || emp.firstname || ' ' || coalesce(emp.middlename || ' ', '') || emp.lastname AS "AdmittingDoctorName", 
          bed.bedcode as "bedcode", 
          bedf.bedfeaturename AS "BedFeature", 
          bedf.bedfeatureid, 
          adtpat.startedon, 
          dept.departmentname, 
          dept.departmentid, 
          ward.wardname, 
          ward.wardid, 
          adm.admissionstatus, 
          adm.dischargedate, 
          case when adm.admissionstatus = 'admitted' then datediff(
            day, 
            adm.admissiondate, 
            current_timestamp
          ) else datediff(
            day, adm.admissiondate, adm.dischargedate
          ) end AS "Number_of_Days" 
        from 
          adt_patientadmission adm 
          join adt_txn_patientbedinfo adtpat on adm.patientid = adtpat.patientid 
          join pat_patientvisits visit on adm.patientvisitid = visit.patientvisitid 
          join pat_patient pat on pat.patientid = visit.patientid 
          join adt_mst_ward ward on ward.wardid = adtpat.wardid 
          join adt_bed bed on bed.bedid = adtpat.bedid 
          join adt_map_bedfeaturesmap bedm on bed.bedid = bedm.bedid 
          join adt_mst_bedfeature bedf on bedm.bedfeatureid = bedf.bedfeatureid 
          left join emp_employee emp on adm.admittingdoctorid = emp.employeeid 
          left join mst_department dept on dept.departmentid = adtpat.requestingdeptid
      ) newdata 
    where 
      newdata.rownum = 1 
      and ((newdata.admissiondate)::date between p_fromdate 
      and p_todate 
      or (newdata.dischargedate)::date between p_fromdate 
      and p_todate )
      and (
        newdata.wardid = (p_wardid)::varchar 
        or (p_wardid)::varchar= 0
      ) 
      and (
        newdata.departmentid = (p_departmentid)::varchar 
        or (p_departmentid)::varchar= 0
      ) 
      and (
        newdata.bedfeatureid = (p_bedfeatureid)::varchar 
        or (p_bedfeatureid)::varchar= 0
      ) 
      and (
        newdata.admissionstatus not like '%cancel%'
      )
      and (
        newdata.admissionstatus like '%' || p_admissionstatus || '%' 
        or p_admissionstatus is null 
      ) 
      and
       (newdata.patientname like '%' || coalesce(p_searchtext,'') ||'%' 
        or newdata.visitcode like '%' || coalesce(p_searchtext,'') || '%'
    	or newdata.patientcode like '%' || coalesce(p_searchtext,'') || '%')
    order by 
      newdata.admissiondate desc;
    
    end;
END;
$$ LANGUAGE plpgsql;