CREATE PROCEDURE [dbo].[SP_Report_Appointment_DoctorWiseStatReport] 
  @FromDate DATE = NULL,
  @ToDate DATE = NULL,
  @EmployeeId INT = NULL,
  @Gender VARCHAR(20) = NULL
AS
/*
exec SP_Report_Appointment_DoctorWiseStatReport '2023-09-19', '2023-09-19'
FileName: [SP_Report_Appointment_DoctorWiseStatReport]
CreatedBy/date: 
Description: To get doctorwise total stat (new,followup) on a given date range
Remarks:    
Change History
S.No.    UpdatedBy/Date            Remarks
1     Bibek:10Sept'23               Initial Script
2.    Bibek:19thSept'23              Edited the sp to display proper name of doctor
*/
BEGIN
    DECLARE @MinAgeInDaysForChild INT = (SELECT MinAgeInDays FROM CORE_MST_AgeClassification WHERE AgeName = 'Child')
    DECLARE @MaxAgeInDaysForChild INT = (SELECT MaxAgeInDays FROM CORE_MST_AgeClassification WHERE AgeName = 'Child')

    DECLARE @MinAgeInDaysForAdult INT = (SELECT MinAgeInDays FROM CORE_MST_AgeClassification WHERE AgeName = 'Adult')
    DECLARE @MaxAgeInDaysForAdult INT = (SELECT MaxAgeInDays FROM CORE_MST_AgeClassification WHERE AgeName = 'Adult')

    SELECT *, [NewMaleChild] + [NewFemaleChild] + [NewMaleAdult] + [NewFemaleAdult] + [OldMaleChild] + [OldFemaleChild] + [OldMaleAdult] + [OldFemaleAdult] AS Total
    FROM (
        SELECT
            FullName,
            CASE
                WHEN AgeDays >= @MinAgeInDaysForChild AND AgeDays <= @MaxAgeInDaysForChild AND Gender = 'Male' AND AppointmentType = 'New' THEN 'NewMaleChild'
                WHEN AgeDays >= @MinAgeInDaysForChild AND AgeDays <= @MaxAgeInDaysForChild AND Gender = 'Female' AND AppointmentType = 'New' THEN 'NewFemaleChild'
                WHEN AgeDays >= @MinAgeInDaysForAdult AND AgeDays <= @MaxAgeInDaysForAdult AND Gender = 'Male' AND AppointmentType = 'New' THEN 'NewMaleAdult'
                WHEN AgeDays >= @MinAgeInDaysForAdult AND AgeDays <= @MaxAgeInDaysForAdult AND Gender = 'Female' AND AppointmentType = 'New' THEN 'NewFemaleAdult'
                WHEN AgeDays >= @MinAgeInDaysForChild AND AgeDays <= @MaxAgeInDaysForChild AND Gender = 'Male' AND AppointmentType = 'Followup' THEN 'OldMaleChild'
                WHEN AgeDays >= @MinAgeInDaysForChild AND AgeDays <= @MaxAgeInDaysForChild AND Gender = 'Female' AND AppointmentType = 'Followup' THEN 'OldFemaleChild'
                WHEN AgeDays >= @MinAgeInDaysForAdult AND AgeDays <= @MaxAgeInDaysForAdult AND Gender = 'Male' AND AppointmentType = 'Followup' THEN 'OldMaleAdult'
                WHEN AgeDays >= @MinAgeInDaysForAdult AND AgeDays <= @MaxAgeInDaysForAdult AND Gender = 'Female' AND AppointmentType = 'Followup' THEN 'OldFemaleAdult'
            END AS AgeCategory
        FROM (
            SELECT
                emp.FullName,
                DATEDIFF(day, pat.DateOfBirth, vis.VisitDate) AS AgeDays,
                vis.AppointmentType,
                pat.Gender
            FROM
                PAT_Patient pat
                INNER JOIN PAT_PatientVisits vis ON pat.PatientId = vis.PatientId 
                INNER JOIN EMP_Employee emp ON vis.PerformerId = emp.EmployeeId
            WHERE
				IsAppointmentApplicable=1
				AND vis.VisitType != 'inpatient' 
                AND CONVERT(DATE, vis.VisitDate) BETWEEN @FromDate AND @ToDate 
                AND (pat.Gender = @Gender OR @Gender IS NULL OR @Gender = 'All' ) 
                AND (emp.EmployeeId = @EmployeeId OR @EmployeeId IS NULL)
				AND vis.AppointmentType IN ('New','followup') 
				AND vis.BillingStatus != 'returned'
        ) tbl
    ) src
    PIVOT (
        COUNT(AgeCategory)
        FOR AgeCategory IN (
            [NewMaleChild], [NewFemaleChild], [NewMaleAdult], [NewFemaleAdult],
            [OldMaleChild], [OldFemaleChild], [OldMaleAdult], [OldFemaleAdult]
        )
    ) piv;
END