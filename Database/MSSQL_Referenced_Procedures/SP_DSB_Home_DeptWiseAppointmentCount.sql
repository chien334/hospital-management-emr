--END: Appointement Search Patient---

--START: Main DashBoard DeptWise Appointment Count SP Changed after Performance Tuning---

CREATE PROCEDURE [dbo].[SP_DSB_Home_DeptWiseAppointmentCount]
    @TodaysDate Datetime=NULL
AS
--[SP_DSB_Home_DeptWiseAppointmentCount]  '2018-12-12'
/*
FileName: [SP_DSB_Home_DeptWiseAppointmentCount]
CreatedBy/date: sudarshan/2017-07-09
Description: to get all the appointment counts till date acc to departments.
Remarks:  CHECK DATA CORRECTNESS ONCE AGAIN..
         --ADD DEPARTMENTID in visit/appointment table for Dept wise assignment later on.
Change History
S.No.    UpdatedBy/Date                        Remarks
1        sudarshan/2017-07-09	               created
2        Umed/2018-04-18                    Modified SP
                                        Corrected SP Data should be Per Day DepartmentWise Appointment Count
3        Dinesh (13th Dec_2018)			As per the hams Requirement
4        Sud/Pawan (22 Dec 2021)        SQL Performance tuning. Count is taken from Pat_vist table
                                         previuosly was taking from Bil_txn_items table.
                                         
*/
BEGIN

    IF (@TodaysDate IS NOT NULL)
		BEGIN
		
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED ;
		
        SELECT ms.DepartmentName, Count(*) 'AppointmentCount'
        FROM PAT_PatientVisits vis
            JOIN MST_Department ms ON ms.DepartmentId = vis.DepartmentId
        WHERE vis.BillingStatus != 'returned'
            AND CONVERT(date,vis.VisitDate)=@TodaysDate AND vis.VisitType != 'inpatient'
        GROUP BY ms.DepartmentName
    END
END