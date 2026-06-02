CREATE Procedure SP_VACC_GetAllVaccinationPatInfo
AS
/*
 FileName: [SP_VACC_GetAllVaccinationPatInfo] 
 Created: 2-Oct'21/Sud 
 Description: To Get Only the vaccination patients with VisitInformation
 Remarks: 
 Change History
 S.No.    Date/User                       Remarks
 1.       2-Oct'21/Sud                    inital draft
           
*/
BEGIN

Declare @VaccDepartmentName varchar(200) = (Select top 1 ParameterValue from CORE_CFG_Parameters where ParameterName='immunizationdeptname' 
                                             and ParameterGroupName='Common')

Declare @DeptId INT=(Select Top(1) DepartmentId from MST_Department where DepartmentName=@VaccDepartmentName)

select pat.PatientId, 
      pat.ShortName AS PatientName,
	  pat.PatientCode,
	  pat.DateOfBirth,
	  pat.Gender,
	  pat.Address,
	  pat.MotherName,
	  pat.VaccinationRegNo,
	  '' as DepartmentName,
	  vaccVisits.PatientVisitId,
	  vaccVisits.VisitDate,
	  vaccVisits.VisitTime,
	  CAST(Convert(Date, vaccVisits.VisitDate) as DATETIME) + CAST(vaccVisits.VisitTime AS DATETIME) AS VisitDateTime,
	  pat.EthnicGroup,
	  pat.FatherName,
	  vaccVisits.UserName,
	  pat.VaccinationFiscalYearId,
	  pat.CountrySubDivisionId,
	  pat.CountryId

from PAT_Patient pat
  LEFT JOIN 
  (
     --gets only visit of Immunization Department for each Patient---
    Select PatientId, PatientVisitId, VisitCode, VisitDate, VisitTime, row_num, UserName
      from 
      (
      SELECT 
         ROW_NUMBER() OVER (
			PARTITION BY patientid
			ORDER BY patientvisitid desc
         ) row_num,
         PatientId, PatientVisitId,VisitCode, VisitDate, VisitTime, emp.FullName AS UserName

      FROM 
         PAT_PatientVisits vis INNER JOIN EMP_Employee emp
		      on vis.CreatedBy = emp.EmployeeId
		 Where vis.DepartmentId=@DeptId --this value comes from parameter+department table .
      ) A
	where row_num=1 --gets only the latest visit of each patient

  ) vaccVisits
  ON pat.PatientId = vaccVisits.PatientId



  where IsVaccinationPatient=1 and vaccVisits.PatientVisitId is not null
  order by VisitDateTime desc

END