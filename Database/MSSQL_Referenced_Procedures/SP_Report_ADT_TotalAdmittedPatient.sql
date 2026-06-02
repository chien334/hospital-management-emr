CREATE PROCEDURE [dbo].[SP_Report_ADT_TotalAdmittedPatient] 
   @FromDate Date=null,
   @ToDate Date=null
AS
/*
FileName: [SP_Report_ADT_TotalAdmittedPatient]
CreatedBy/date: Sagar/2017-05-27
Description: to get the count of total discharged patient between Given Date
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
11.    Anish: 4 June 2020               Row Number Removed
12.    Sud:1Aug'21                      Handle AdmittingDoctor (NonMandatory) case using Left-Join instead of Inner join
13.   Sud:21Sep'21                      Return Department name also.
                                        taking PatName and EmpName from single Column of their tables
14.   Sud:11Aug'22                      Using 2 join-conditions to Find out Correct Bed Feature 
*/
BEGIN
  BEGIN
  Select * FROM
    (
      select
       (Cast(ROW_NUMBER() OVER (ORDER BY  AdmissionDate desc)  AS int)) AS SN,
        -- this groups beds of one patients and adds rownumber to it, need to get latest bed (rowNum=1)-- (based on: latest bedInfo.StartedOn)
        ROW_NUMBER() OVER(PARTITION BY bedInfo.PatientId ORDER BY bedInfo.StartedOn DESC) AS RowNum,
        AD.AdmissionDate,
        P.PatientCode,
        V.VisitCode,
        P.ShortName AS 'PatientName',
        P.Age as [Age/Sex],
        E.FullName 'AdmittingDoctorName',
        ISNULL(dept.DepartmentName,'Not Assigned') AS DepartmentName,
        bed.BedCode as 'BedCode',
        bedf.BedFeatureName as BedFeature
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
        CONVERT(date,bedInfo.StartedOn) between @FromDate and @ToDate and
        CONVERT(date,ad.AdmissionDate) between @FromDate and @ToDate
    ) A
    --where A.RowNum=1 ---take only latest bed..
    ORDER by SN 
  END  
END