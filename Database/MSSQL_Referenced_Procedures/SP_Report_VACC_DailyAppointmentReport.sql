CREATE PROCEDURE [dbo].[SP_Report_VACC_DailyAppointmentReport] 
	@FromDate Date=null,
	@ToDate Date=null,
	@AppointmentType varchar(100) = null
AS
/*
FileName: [SP_Report_VACC_DailyAppointmentReport]
CreatedBy/date: Sud/2021-10-02
Description: to get Appointemnt details of Vaccination patients. 
Remarks: We're considering only patients who has VaccinationRegNumber (i.e: Patients registered from Vaccination module)  
Change History
S.No.    UpdatedBy/Date                        Remarks
5		Sud/2021-10-02					      Initial Draft
*/
BEGIN

--DepartmentName for Immunization should be taken from Parameter table (since it could be different for diff hospitals).
  Declare @VaccDepartmentName varchar(200) = (Select top 1 ParameterValue from CORE_CFG_Parameters where ParameterName='immunizationdeptname' 
                                             and ParameterGroupName='Common')
  Declare @DeptId INT=(Select Top(1) DepartmentId from MST_Department where DepartmentName=@VaccDepartmentName)

  Declare @apptType Varchar(20)
  SET @apptType = @AppointmentType
  if(ISNULL(@AppointmentType,'all')='all')
  BEGIN
    SET @apptType= ''  --change to empty input is 'NULL' or 'all' --- for string comparison..
  END

  SELECT
	   CAST(Convert(Date, vis.VisitDate) as DATETIME) + CAST(vis.VisitTime AS DATETIME) AS VisitDateTime,
	    pat.VaccinationRegNo,
		pat.ShortName AS PatientName,
		pat.PatientCode,
        pat.PhoneNumber, 
		pat.Age, 
		pat.Gender,
		pat.DateOfBirth,
		pat.MotherName,
		pat.EthnicGroup,
		dist.CountrySubDivisionName 'DistrictName',
		pat.Address,
		vis.AppointmentType,
		emp.FullName AS UserName

    FROM PAT_Patient pat  INNER JOIN PAT_PatientVisits AS vis ON vis.PatientId = pat.PatientId
   
	INNER JOIN MST_CountrySubDivision dist on pat.CountrySubDivisionId=dist.CountrySubDivisionId
	INNER join MST_Department dept on vis.DepartmentId=dept.DepartmentId
	INNER join EMP_Employee emp on emp.EmployeeId = vis.CreatedBy
	WHERE 
		vis.DepartmentId = @DeptId --taking only appointments of Immunzation Department
		and pat.IsVaccinationPatient = 1 -- take only vaccination patients
		and CONVERT(date, vis.VisitDate) BETWEEN @FromDate  AND  @ToDate 
		and vis.VisitType !='inpatient' --excluding inpatient visits (those can be seen from admission reports)
		AND  vis.AppointmentType LIKE '%' + ISNULL(@apptType, '') + '%'
		AND vis.BillingStatus NOT  IN('cancel','returned')--exclude cancelled and returned visits.
	ORDER BY CAST(Convert(Date, vis.VisitDate) as DATETIME) + CAST(vis.VisitTime AS DATETIME) DESC
  
END