CREATE PROCEDURE [dbo].[SP_Report_Appointment_GeographicalStatReport]
	 @FromDate DATE = NULL
	,@ToDate DATE = NULL
	,@CountrySubDivisionName VARCHAR(200) = NULL
	,@MunicipalityName VARCHAR(200) = NULL
	,@GeoStatType VARCHAR(200) = NULL
AS

/*
FileName:  exec [SP_Report_Appointment_GeographicalStatReport]
CreatedBy/date: 
Description: To get District/Municipality wise total appointments(new,followup) on a given date range
Remarks:    
Change History
S.No.    UpdatedBy/Date            Remarks
1      Bibek:27Sep'23               Initial script
2.	   Bibek:10thJuly'23					count the number of visit according to each municipality
*/
BEGIN
    IF @GeoStatType = 'District'
    BEGIN
        SELECT CountrySubDivisionId AS 'DistrictId',
            CountrySubDivisionName AS 'DistrictName',
            ISNULL([New], 0) AS 'NewAppointment',
            ISNULL([followup], 0) AS 'Followup',
            ISNULL([Referral], 0) AS 'Referral',
            ISNULL([New], 0) + ISNULL([followup], 0) AS 'TotalAppointments'
        FROM (
            SELECT dist.CountrySubDivisionId,
                dist.CountrySubDivisionName,
                vis.AppointmentType,
                COUNT(*) AS 'AppointmentCount'
            FROM PAT_PatientVisits VIS
            INNER JOIN PAT_Patient pat ON vis.PatientId = pat.PatientId
            INNER JOIN MST_CountrySubDivision dist ON pat.CountrySubDivisionId = dist.CountrySubDivisionId
            WHERE CONVERT(DATE, VIS.VisitDate) BETWEEN @FromDate AND @ToDate
                AND CountrySubDivisionName LIKE '%' + ISNULL(@CountrySubDivisionName, '') + '%'
                AND vis.BillingStatus NOT IN ('returned', 'cancel')
                AND vis.VisitType != 'inpatient'
            GROUP BY dist.CountrySubDivisionId,
                dist.CountrySubDivisionName,
                vis.AppointmentType
            ) tbl
        PIVOT (SUM(AppointmentCount) FOR AppointmentType IN ([New], [followup], [Referral])) AS pvtData
        ORDER BY CountrySubDivisionName
    END

    IF @GeoStatType = 'Municipality'
    BEGIN
        SELECT MunicipalityName,
            ISNULL([New], 0) AS 'NewAppointment',
            ISNULL([followup], 0) AS 'Followup',
            ISNULL([New], 0) + ISNULL([followup], 0) AS 'TotalAppointments'
        FROM (
            SELECT mun.MunicipalityName,
                vis.AppointmentType,
                COUNT(*) AS 'AppointmentCount'
            FROM PAT_PatientVisits VIS
            INNER JOIN PAT_Patient pat ON vis.PatientId = pat.PatientId
            INNER JOIN MST_Municipality mun ON pat.MunicipalityId = mun.MunicipalityId
            INNER JOIN MST_CountrySubDivision dist ON mun.CountrySubDivisionId = dist.CountrySubDivisionId
            WHERE CONVERT(DATE, VIS.VisitDate) BETWEEN @FromDate AND @ToDate
                AND CountrySubDivisionName LIKE '%' + ISNULL(@CountrySubDivisionName, '') + '%'
				AND MunicipalityName LIKE '%' + ISNULL(@MunicipalityName, '') + '%'
                AND vis.BillingStatus NOT IN ('returned', 'cancel')
                AND vis.VisitType != 'inpatient'
            GROUP BY mun.MunicipalityName,
                vis.AppointmentType
            ) AS tbl
        PIVOT (SUM(AppointmentCount) FOR AppointmentType IN ([New], [followup])) AS pvtData
        ORDER BY MunicipalityName
    END
END