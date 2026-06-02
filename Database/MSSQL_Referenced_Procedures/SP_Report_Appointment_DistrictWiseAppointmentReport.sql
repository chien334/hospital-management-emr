CREATE PROCEDURE [dbo].[SP_Report_Appointment_DistrictWiseAppointmentReport]
@FromDate DATE = NULL,
@ToDate DATE = NULL,
@CountrySubDivisionName varchar(200) = NULL,
@Gender varchar(20)=null
AS
/*
FileName: [SP_Report_Appointment_DistrictWiseAppointmentReport]
CreatedBy/date: 
Description: To get District wise total appointments(new,followup,referral) on a given date range
Remarks:    
Change History
S.No.    UpdatedBy/Date            Remarks
1      Sud:21Sep'21               Complete rewrite as per new requirement to show sum in the given date range
*/
BEGIN
	Select CountrySubDivisionId 'DistrictId', CountrySubDivisionName 'DistrictName', 
	ISNULL([New],0) 'NewAppointment',
	ISNULL([followup],0) 'Followup',
	ISNULL([Referral],0) 'Referral',
	ISNULL([New],0) + ISNULL([followup],0) + ISNULL([Referral],0)  'TotalAppointments'

	from 
	(
	Select dist.CountrySubDivisionId, dist.CountrySubDivisionName,
	vis.AppointmentType, Count(*) 'AppointmentCount'
	FROM PAT_PatientVisits VIS
	INNER JOIN PAT_Patient pat
		on vis.PatientId = pat.PatientId
	INNER JOIN MST_CountrySubDivision dist ON pat.CountrySubDivisionId = dist.CountrySubDivisionId

	WHERE Convert(Date,VIS.VisitDate) BETWEEN @FromDate AND @ToDate AND 
		 CountrySubDivisionName LIKE  '%'+ISNULL(@CountrySubDivisionName,'')+'%'

	and vis.BillingStatus NOT IN('returned','cancel')
	--exclude inpatient visits..
	and vis.VisitType !='inpatient'

	and ISNULL(NULLIF(@Gender,'all'),pat.Gender)=pat.Gender
	
	GROUP by dist.CountrySubDivisionId, dist.CountrySubDivisionName, vis.AppointmentType

	) tbl
	pivot (SUM(AppointmentCount) for AppointmentType IN ([New],[followup],[Referral])) as pvtData

	order by CountrySubDivisionName
END