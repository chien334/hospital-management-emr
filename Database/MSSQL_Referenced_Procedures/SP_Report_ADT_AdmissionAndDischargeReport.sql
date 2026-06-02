/*
-- =============================================
Change History
S.No.    UpdatedBy/Date                        Remarks
1.      Dev Narayan/2021-09-25          Initial Draft
2.      Dev Narayan/2021-09-29          Added Discharge date filter
*/
-- =============================================
CREATE PROCEDURE [dbo].[SP_Report_ADT_AdmissionAndDischargeReport]
   @FromDate Date=null,
   @ToDate Date=null,
   @WardId int = null,
   @DepartmentId int = null,
   @BedFeatureId int = null,
   @AdmissionStatus varchar(40)= null,
   @SearchText varchar(40) = null
AS
BEGIN
SET 
  @WardId = ISNULL(@WardId, 0);
SET 
  @DepartmentId = ISNULL(@DepartmentId, 0);
SET 
  @BedFeatureId = ISNULL(@BedFeatureId, 0);
IF(@AdmissionStatus LIKE '%All%')
BEGIN
SET @AdmissionStatus = null;
END
Select 
  (
    Cast(
      ROW_NUMBER() OVER (
        ORDER BY 
          newData.RowNum desc
      ) AS int
    )
  ) AS SN, 
  newData.PatientName, 
  newData.PatientCode, 
  newData.VisitCode, 
  newData.AdmissionDate, 
  newData.DepartmentName, 
  newData.AdmittingDoctorName, 
  newData.WardName, 
  newData.BedFeature, 
  newData.AdmissionStatus, 
  newData.DischargeDate, 
  newData.Number_of_Days
FROM 
  (
    select 
      ROW_NUMBER() OVER(
        PARTITION BY adm.PatientAdmissionId 
        ORDER BY 
          adtPat.StartedOn DESC
      ) AS RowNum, 
      adm.PatientAdmissionId, 
      adm.AdmissionDate, 
      pat.PatientCode, 
      visit.VisitCode, 
      pat.FirstName + ' ' + ISNULL(pat.MiddleName + ' ', '') + pat.LastName AS 'PatientName', 
      ISNULL(emp.Salutation + '. ', '') + emp.FirstName + ' ' + ISNULL(emp.MiddleName + ' ', '') + emp.LastName 'AdmittingDoctorName', 
      bed.BedCode as 'BedCode', 
      bedf.BedFeatureName as BedFeature, 
      bedf.BedFeatureId, 
      adtPat.StartedOn, 
      dept.DepartmentName, 
      dept.DepartmentId, 
      ward.WardName, 
      ward.WardID, 
      adm.AdmissionStatus, 
      adm.DischargeDate, 
      case when adm.AdmissionStatus = 'admitted' then DATEDIFF(
        DAY, 
        adm.AdmissionDate, 
        GETDATE()
      ) else DATEDIFF(
        DAY, adm.AdmissionDate, adm.DischargeDate
      ) end AS 'Number_of_Days' 
    from 
      ADT_PatientAdmission adm 
      join ADT_TXN_PatientBedInfo adtPat on adm.PatientId = adtPat.PatientId 
      join PAT_PatientVisits visit on adm.PatientVisitId = visit.PatientVisitId 
      JOIN PAT_Patient pat ON pat.PatientId = visit.PatientId 
      join ADT_MST_Ward ward on ward.WardID = adtPat.WardId 
      JOIN ADT_Bed bed on bed.BedID = adtPat.BedId 
      JOIN ADT_MAP_BedFeaturesMap bedm on bed.BedID = bedm.BedId 
      JOIN ADT_MST_BedFeature bedf on bedm.BedFeatureId = bedf.BedFeatureId 
      left join EMP_EMPLOYEE emp ON adm.AdmittingDoctorId = emp.EmployeeId 
      left join MST_Department dept on dept.DepartmentId = adtPat.RequestingDeptId
  ) newData 
where 
  newData.RowNum = 1 
  and (CONVERT(date, newData.AdmissionDate) between @FromDate 
  and @ToDate 
  or CONVERT(date, newData.DischargeDate) between @FromDate 
  and @ToDate )
  and (
    newData.WardID = Convert(
      VARCHAR(40), 
      @WardId
    ) 
    or Convert(
      VARCHAR(40), 
      @WardId
    )= 0
  ) 
  and (
    newData.DepartmentId = Convert(
      VARCHAR(40), 
      @DepartmentId
    ) 
    or Convert(
      VARCHAR(40), 
      @DepartmentId
    )= 0
  ) 
  and (
    newData.BedFeatureId = Convert(
      VARCHAR(40), 
      @BedFeatureId
    ) 
    or Convert(
      VARCHAR(40), 
      @BedFeatureId
    )= 0
  ) 
  and (
    newData.AdmissionStatus NOT LIKE '%cancel%'
  )
  and (
    newData.AdmissionStatus LIKE '%' + @AdmissionStatus + '%' 
    OR @AdmissionStatus is Null 
  ) 
  and
   (newData.PatientName like '%' + ISNULL(@SearchText,'') +'%' 
    or newData.VisitCode like '%' + ISNULL(@SearchText,'') + '%'
	or newData.PatientCode like '%' + ISNULL(@SearchText,'') + '%')
order by 
  newData.AdmissionDate desc

END