/* =============================================
-- Author:		<Dev Narayan Chaudhary>
-- Create date: <2021 Nov 24>
-- Description:	Get Edit history of patients whose Name was edited 
-- Remarks: Currently we're tracking only Name change, we can extend this to track other changes of patient as well.
     

-- =============================================
Change History:
SN      User/Date                   Remarks
1.      DevNarayan/27Dec'2021       Initial Draft
2.      Rusha/24Feb'2022			Registered name and edited name is not showing of different user login after edited patient

*/
CREATE PROCEDURE [dbo].[SP_Report_PAT_EditedPatientDetailReport]
    @FromDate Date=null,
    @ToDate Date=null,
    @UserId int = null
AS
BEGIN
select
	   data.[Hospital Number],
	   data.[Patient Old Name],
	   data.[Patient New Name],
	   data.[Registered By],
	   data.[Edited By],
	   data.[Registered Date],
	   data.[Edited Date]
        from (
          select 
		  patient.PatientCode as [Hospital Number],
		  history.PatientOldName as [Patient Old Name],
		  history.PatientNewName as [Patient New Name],
		  users.UserName as [Registered By],
		  modfier.UserName as [Edited By],
		  patient.CreatedOn as [Registered Date],
		  history.CreatedOn as [Edited Date],
		  history.CreatedBy as updater,
		  patient.CreatedBy as creater
		  from PAT_History_PatientName history
          join PAT_Patient patient on history.PatientId = patient.PatientId
		     left join RBAC_User users on patient.CreatedBy= users.EmployeeId
		     left join RBAC_User modfier on  history.CreatedBy = modfier.EmployeeId
		  ) as data
		  where 
		    ( ISNULL(@UserId,data.updater) =data.updater
		     OR   data.creater = @UserId or @UserId =0
		     OR ISNULL(@UserId,data.creater) =data.creater )
		  
		  and (CONVERT(date, data.[Registered Date]) between @FromDate 
		  and @ToDate 
		  or CONVERT(date, data.[Edited Date]) between @FromDate 
		  and @ToDate  or @FromDate is null or @ToDate is null)
order by data.[Edited Date] desc
END