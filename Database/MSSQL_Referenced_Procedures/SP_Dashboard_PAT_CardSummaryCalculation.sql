CREATE PROCEDURE SP_Dashboard_PAT_CardSummaryCalculation @FromDate DATE = NULL
	,@ToDate DATE = NULL
AS
/*
 SP_Dashboard_PAT_CardSummaryCalculation '2022-1-05'
FileName: [SP_Dashboard_PAT_CardSummaryCalculation]
CreatedBy/date: Nirmala/Rohit/2022-1-05
Description: .
Remarks:    A
Change History
S.No.    UpdatedBy/Date                        Remarks
1      Nirmala/Rohit/2022-1-05                created the script
*/
BEGIN
	DECLARE @FromDayMinusOneDay DATE = DATEADD(DAY, - 1, @FromDate)
	DECLARE @FromDayMinusTwoDay DATE = DATEADD(DAY, - 2, @FromDate)
	DECLARE @NoOfDaysInGivenRange INT = DATEDIFF(DAY, @FromDate, @ToDate) + 1

	SELECT 'TotalRegisteredPatient' 'Label'
		,COUNT(ParentVisitId) 'Total'
	FROM PAT_PatientVisits
	WHERE CONVERT(DATE, VisitDate) BETWEEN @FromDate
			AND @ToDate
	
	UNION ALL
	
	SELECT 'TodayRegisteredPatient' 'Label'
		,COUNT(ParentVisitId) 'Total'
	FROM PAT_PatientVisits
	WHERE CONVERT(DATE, VisitDate) = CONVERT(DATE, @FromDate)
	
	UNION ALL
	
	SELECT 'YesterdayRegisteredPatient' 'Label'
		,COUNT(ParentVisitId) 'Total'
	FROM PAT_PatientVisits
	WHERE CONVERT(DATE, VisitDate) BETWEEN CONVERT(DATE, @FromDayMinusOneDay)
			AND CONVERT(DATE, @FromDayMinusTwoDay)
	
	UNION ALL
	
	SELECT 'AverageRegisteredPatient' 'Label'
		,COUNT(ParentVisitId) / @NoOfDaysInGivenRange 'Total'
	FROM PAT_PatientVisits
	WHERE CONVERT(DATE, VisitDate) BETWEEN @FromDate
			AND @ToDate

	SELECT 'TotalDoctor' 'Label'
		,count(EmployeeId) 'Total'
	FROM EMP_Employee
	WHERE Salutation = 'Dr'
	
	UNION ALL
	
	SELECT 'TotalConsultant' 'Label'
		,count(EmployeeId) 'Total'
	FROM EMP_Employee
	WHERE Salutation = 'Dr'
		AND ISNULL(IsAppointmentApplicable, 0) = 1
	
	UNION ALL
	
	SELECT 'Anaesthetists' 'Label'
		,count(emp.EmployeeId) 'Total'
	FROM EMP_Employee emp
	INNER JOIN MST_Department dep ON emp.DepartmentId = dep.DepartmentId
	WHERE Salutation = 'Dr'
		AND DepartmentName = 'Anesthesia'
	
	UNION ALL
	
	SELECT 'Medical Officer' 'Label'
		,count(emp.EmployeeId) 'Total'
	FROM EMP_Employee emp
	INNER JOIN MST_Department dep ON emp.DepartmentId = dep.DepartmentId
	WHERE Salutation = 'Dr'
		AND DepartmentName = 'Medical Officer'

	SELECT 'TotalAppointments' 'Label'
		,COUNT(AppointmentId) 'Total'
	FROM PAT_Appointment
	WHERE CONVERT(DATE, AppointmentDate) BETWEEN @FromDate
			AND @ToDate
	
	UNION ALL
	
	SELECT 'TodayAppointments' 'Label'
		,COUNT(AppointmentId) 'Total'
	FROM PAT_Appointment
	WHERE CONVERT(DATE, AppointmentDate) BETWEEN CONVERT(DATE, @FromDayMinusOneDay)
			AND CONVERT(DATE, @FromDayMinusTwoDay)
	
	UNION ALL
	
	SELECT 'AverageAppointment' 'Label'
		,COUNT(AppointmentId) / @NoOfDaysInGivenRange 'Total'
	FROM PAT_Appointment
	WHERE CONVERT(DATE, AppointmentDate) BETWEEN @FromDate
			AND @ToDate
	
	UNION ALL
	
	SELECT 'Medical Officer' 'Label'
		,count(app.AppointmentId) 'Total'
	FROM PAT_Appointment app
	INNER JOIN MST_Department dep ON app.DepartmentId = dep.DepartmentId
	WHERE DepartmentName = 'Medical Officer'

	SELECT 'TotalReAdmission' 'Label'
		,count(PatientAdmissionId) 'Total'
	FROM ADT_PatientAdmission
	WHERE AdmissionStatus = 'admitted'
		AND CONVERT(DATE, AdmissionDate) BETWEEN @FromDate
			AND @ToDate
	HAVING count(PatientId) > 1
	
	UNION ALL
	
	SELECT 'TodayAdmission' 'Label'
		,count(PatientAdmissionId) 'Total'
	FROM ADT_PatientAdmission
	WHERE AdmissionStatus = 'admitted'
		AND CONVERT(DATE, AdmissionDate) = @FromDate
	
	UNION ALL
	
	SELECT 'YesterdayAdmission' 'Label'
		,count(PatientAdmissionId) 'Total'
	FROM ADT_PatientAdmission
	WHERE AdmissionStatus = 'admitted'
		AND (
			CONVERT(DATE, AdmissionDate) BETWEEN CONVERT(DATE, @FromDayMinusOneDay)
				AND CONVERT(DATE, @FromDayMinusTwoDay)
			)
	
	UNION ALL
	
	SELECT 'AverageAdmission' 'Label'
		,count(PatientAdmissionId) / @NoOfDaysInGivenRange 'Total'
	FROM ADT_PatientAdmission
	WHERE AdmissionStatus = 'admitted'
		AND (
			CONVERT(DATE, AdmissionDate) BETWEEN CONVERT(DATE, @FromDate)
				AND CONVERT(DATE, @ToDate)
			)
END