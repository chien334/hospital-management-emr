CREATE PROCEDURE [dbo].[SP_Report_Appointment_DepartmentWiseStatReport] 
  @FromDate DATE = NULL,
  @ToDate DATE = NULL,
  @DepartmentId INT = NULL,
  @Gender VARCHAR(20) = NULL
AS
/*
FileName: [SP_Report_Appointment_DepartmentWiseStatReport]
CreatedBy/date: 
Description: To get departmentwise total stat (new,followup) on a given date range
Remarks:    
Change History
S.No.    UpdatedBy/Date            Remarks
1     Santosh:21June'23               Complete rewrite as per new requirement to show sum in the given date range
*/
BEGIN
    DECLARE @MinAgeInDaysForChild INT = (SELECT MinAgeInDays FROM CORE_MST_AgeClassification WHERE AgeName = 'Child')
    DECLARE @MaxAgeInDaysForChild INT = (SELECT MaxAgeInDays FROM CORE_MST_AgeClassification WHERE AgeName = 'Child')

    DECLARE @MinAgeInDaysForAdult INT = (SELECT MinAgeInDays FROM CORE_MST_AgeClassification WHERE AgeName = 'Adult')
    DECLARE @MaxAgeInDaysForAdult INT = (SELECT MaxAgeInDays FROM CORE_MST_AgeClassification WHERE AgeName = 'Adult')

    SELECT *, [NewMaleChild] + [NewFemaleChild] + [NewMaleAdult] + [NewFemaleAdult] + [FollowupMaleChild] + [FollowupFemaleChild] + [FollowupMaleAdult] + [FollowupFemaleAdult] AS Total
    FROM (
        SELECT
            DepartmentName,
            CASE
                WHEN AgeDays >= @MinAgeInDaysForChild AND AgeDays <= @MaxAgeInDaysForChild AND Gender = 'Male' AND AppointmentType = 'New' THEN 'NewMaleChild'
                WHEN AgeDays >= @MinAgeInDaysForChild AND AgeDays <= @MaxAgeInDaysForChild AND Gender = 'Female' AND AppointmentType = 'New' THEN 'NewFemaleChild'
                WHEN AgeDays >= @MinAgeInDaysForAdult AND AgeDays <= @MaxAgeInDaysForAdult AND Gender = 'Male' AND AppointmentType = 'New' THEN 'NewMaleAdult'
                WHEN AgeDays >= @MinAgeInDaysForAdult AND AgeDays <= @MaxAgeInDaysForAdult AND Gender = 'Female' AND AppointmentType = 'New' THEN 'NewFemaleAdult'
                WHEN AgeDays >= @MinAgeInDaysForChild AND AgeDays <= @MaxAgeInDaysForChild AND Gender = 'Male' AND AppointmentType = 'Followup' THEN 'FollowupMaleChild'
                WHEN AgeDays >= @MinAgeInDaysForChild AND AgeDays <= @MaxAgeInDaysForChild AND Gender = 'Female' AND AppointmentType = 'Followup' THEN 'FollowupFemaleChild'
                WHEN AgeDays >= @MinAgeInDaysForAdult AND AgeDays <= @MaxAgeInDaysForAdult AND Gender = 'Male' AND AppointmentType = 'Followup' THEN 'FollowupMaleAdult'
                WHEN AgeDays >= @MinAgeInDaysForAdult AND AgeDays <= @MaxAgeInDaysForAdult AND Gender = 'Female' AND AppointmentType = 'Followup' THEN 'FollowupFemaleAdult'
            END AS AgeCategory
        FROM (
            SELECT
                dept.DepartmentName,
                DATEDIFF(day, pat.DateOfBirth, GETDATE()) AS AgeDays,
                vis.AppointmentType,
                pat.Gender
            FROM
                PAT_Patient pat
                INNER JOIN PAT_PatientVisits vis ON pat.PatientId = vis.PatientId 
                INNER JOIN MST_Department dept ON vis.DepartmentId = dept.DepartmentId
            WHERE
                dept.IsAppointmentApplicable = 1 
                AND vis.VisitType != 'inpatient' 
                AND CONVERT(DATE, vis.VisitDate) BETWEEN @FromDate AND @ToDate 
                AND (pat.Gender = @Gender OR @Gender IS NULL OR @Gender = 'All' ) 
                AND (dept.DepartmentId = @DepartmentId OR @DepartmentId IS NULL)
				AND vis.AppointmentType IN ('New','followup') 
				AND vis.BillingStatus != 'returned'
        ) tbl
    ) src
    PIVOT (
        COUNT(AgeCategory)
        FOR AgeCategory IN (
            [NewMaleChild], [NewFemaleChild], [NewMaleAdult], [NewFemaleAdult],
            [FollowupMaleChild], [FollowupFemaleChild], [FollowupMaleAdult], [FollowupFemaleAdult]
        )
    ) piv;
END