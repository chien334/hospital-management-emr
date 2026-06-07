CREATE OR REPLACE FUNCTION sp_report_adt_totaladmittedpatient(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL
)
RETURNS TABLE (
    "SN" VARCHAR,
    "RowNum" VARCHAR,
    "AdmissionDate" TIMESTAMP,
    "PatientCode" VARCHAR,
    "VisitCode" VARCHAR,
    "PatientName" VARCHAR,
    "Sex" VARCHAR,
    "AdmittingDoctorName" VARCHAR,
    "DepartmentName" VARCHAR,
    "BedCode" VARCHAR,
    "BedFeature" VARCHAR
) AS $$
BEGIN
    /*
    filename: "sp_report_adt_totaladmittedpatient"
    createdby/date: sagar/2017-05-27
    description: to get the count of total discharged patient between given date
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    11.    anish: 4 june 2020               row number removed
    12.    sud:1aug'21                      Handle AdmittingDoctor (NonMandatory) case using Left-Join instead of Inner join
    13.   Sud:21Sep'21                      return department name also.
                                            taking patname and empname from single column of their tables
    14.   sud:11aug'22                      Using 2 join-conditions to Find out Correct Bed Feature 
    */
    
      BEGIN
      RETURN QUERY SELECT * FROM
        (
          select
           (Cast(ROW_NUMBER() OVER (ORDER BY  AdmissionDate desc)  AS int)) AS "SN",
            -- this groups beds of one patients and adds rownumber to it, need to get latest bed (rowNum=1)-- (based on: latest bedInfo.StartedOn)
            ROW_NUMBER() OVER(PARTITION BY bedInfo.PatientId ORDER BY bedInfo.StartedOn DESC) AS "RowNum",
            AD.AdmissionDate,
            P.PatientCode,
            V.VisitCode,
            P.ShortName AS "PatientName",
            P.Age as "Age/Sex",
            E.FullName AS "AdmittingDoctorName",
            COALESCE(dept.DepartmentName,'not assigned') AS "DepartmentName",
            bed.BedCode AS "BedCode",
            bedf.BedFeatureName AS "BedFeature"
            from ADT_PatientAdmission AD
            join PAT_PatientVisits V on AD.PatientVisitId=V.PatientVisitId
            JOIN PAT_Patient P ON P.PatientId=V.PatientId 
            left JOIN EMP_EMPLOYEE E ON AD.AdmittingDoctorId= E.EmployeeId 
            left join MST_Department dept on V.DepartmentId=dept.DepartmentId
            JOIN ADT_TXN_PatientBedInfo bedInfo ON AD.PatientVisitId=bedInfo.PatientVisitId 
            JOIN ADT_Bed bed on bed.BedID=bedInfo.BedId
            JOIN ADT_MAP_BedFeaturesMap bedm on bed.BedID=bedm.BedId
            --Need 2 join conditions on below. since 1 bed can be mapped to multiple bed features
            JOIN ADT_MST_BedFeature bedf 
                  on bedm.BedFeatureId=bedf.BedFeatureId
                      AND bedInfo.BedFeatureId=bedf.BedFeatureId 
            where
            bedInfo.Action='admission'  and
            (bedinfo.startedon)::date between p_fromdate and p_todate and
            (ad.admissiondate)::date between p_fromdate and p_todate
        ) a
        --where a.rownum=1 ---take only latest bed..
        order by sn; 
      end;
END;
$$ LANGUAGE plpgsql;