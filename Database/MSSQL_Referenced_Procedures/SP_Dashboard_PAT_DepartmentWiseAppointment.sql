CREATE PROCEDURE SP_Dashboard_PAT_DepartmentWiseAppointment @FromDate DATE = NULL
	,@ToDate DATE = NULL
AS
/*
 SP_Dashboard_PAT_DepartmentWiseAppointment '2022-1-05'
FileName: [SP_Dashboard_PAT_DepartmentWiseAppointment]
CreatedBy/date:Nirmala/2022-1-05
Description: .
Remarks:    A
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Nirmala/2022-1-05                created the script
*/
BEGIN
	SELECT dep.DepartmentName
		,count(app.AppointmentId) 'AppointmentCount'
	FROM PAT_PatientVisits visit
	JOIN Pat_patient pat ON pat.PatientId = visit.PatientId
	INNER JOIN MST_Department dep ON dep.DepartmentId = visit.DepartmentId
	LEFT JOIN PAT_Appointment app ON app.AppointmentId = app.AppointmentId
	WHERE CONVERT(DATE, app.AppointmentDate) BETWEEN CONVERT(DATE, @FromDate)
			AND CONVERT(DATE, @ToDate)
	GROUP BY dep.DepartmentName
END