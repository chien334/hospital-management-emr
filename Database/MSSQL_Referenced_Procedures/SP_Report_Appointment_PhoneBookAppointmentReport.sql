CREATE PROCEDURE [dbo].[SP_Report_Appointment_PhoneBookAppointmentReport] 
	@FromDate DATETIME = NULL
	,@ToDate DATETIME = NULL
	,@Doctor_Name VARCHAR(100) = NULL
	,@AppointmentStatus VARCHAR(50) = NULL
AS
/*  
FileName: [SP_Report_Appointment_PhoneBookAppointmentReport]  
CreatedBy/date: Rusha/10-24-2019  
Description: To get details from phone book such as Patient Name , Appointment type, Appointment Status,   
    along with doctor name between the Given Dates  
Example: exec SP_Report_Appointment_PhoneBookAppointmentReport '2023-02-01', '2023-02-09', null, null
Remarks:      
Change History  
S.No.    UpdatedBy/Date                        Remarks  
 1.		 Krishna,3rdJun'22			changed ProviderId to PerformerId, ProviderName to PerformerName
 2.		 Krishna, 8thFeb'23		    SP refactored to get correct data
*/
BEGIN
	SELECT CONVERT(DATETIME, CONVERT(DATE, apt.AppointmentDate)) + CONVERT(DATETIME, apt.AppointmentTime) AS 'Date'
		,pat.PatientId
		,pat.PatientCode
		,CONCAT_WS(' ', apt.FirstName, apt.MiddleName, apt.LastName) AS PatientName
		,pat.Age
		,pat.Address
		,apt.Gender
		,apt.ContactNumber
		,apt.PerformerId
		,apt.AppointmentStatus
		,apt.PerformerName
		,apt.AppointmentDate
	FROM PAT_Appointment apt
	LEFT JOIN PAT_Patient pat ON apt.PatientId = pat.PatientId
	LEFT JOIN PAT_PatientVisits visit ON apt.AppointmentId = visit.AppointmentId
	WHERE CONVERT(DATE, apt.AppointmentDate) BETWEEN CONVERT(DATE, @FromDate)
			AND CONVERT(DATE, @ToDate)
		AND ISNULL(apt.PerformerName, '') LIKE '%' + ISNULL(@Doctor_Name, '') + '%'
		AND ISNULL(apt.AppointmentStatus, '') LIKE '%' + ISNULL(@AppointmentStatus, '') + '%'
	ORDER BY CONVERT(DATETIME, CONVERT(DATE, apt.AppointmentDate)) + CONVERT(DATETIME, apt.AppointmentTime) DESC
END