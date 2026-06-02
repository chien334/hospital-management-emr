/* =============================================
-- Author:		Anish Bhattarai
-- Create date: June 4, 2020
S.No.   Date/Author           Remarks
1.     14June'10/Sud         Excluded Action='cancel' from patientbedinfo. this is when admission is cancelled.
-- ============================================= */
CREATE PROCEDURE [dbo].[SP_Report_ADT_PatientInOutReport] 
	@FromDate Date=null ,
	@ToDate Date=null
AS
BEGIN
	If(@FromDate IS NOT NULL OR @ToDate IS NOT NULL)
	BEGIN

	
	--Table1 for all wardName
	select distinct(ward.WardName) from ADT_TXN_PatientBedInfo bedInf Join ADT_MST_Ward ward on bedInf.WardId=ward.WardID

	--Table2 for all Admisssion and TransIn
	select flatData.WardName, flatData.Action, Count(*) as TotalCount
	from (select bedInfo.*,ward.WardName from ADT_TXN_PatientBedInfo bedInfo
	Join ADT_MST_Ward ward on bedInfo.WardId=ward.WardID
	where bedInfo.IsActive=1 
	and bedInfo.Action !='cancel'
	and CONVERT(date,bedInfo.StartedOn) between @FromDate and @ToDate) as flatData Group By flatData.WardName, flatData.Action 

	--Table3 for all Discharged and TransOut
	select flatData.WardName, flatData.OutAction, Count(*) as TotalCount
	from (select bedInfo.*,ward.WardName from ADT_TXN_PatientBedInfo bedInfo
	Join ADT_MST_Ward ward on bedInfo.WardId=ward.WardID
	where bedInfo.IsActive=1 
	and bedInfo.Action !='cancel'
	and CONVERT(date,bedInfo.EndedOn) between @FromDate and @ToDate) as flatData Group By flatData.WardName, flatData.OutAction


	--Table4 for Total InBed Count
	select flatData.WardName, Count(*) as TotalCount
	from (select bedInfo.*,ward.WardName from ADT_TXN_PatientBedInfo bedInfo
	Join ADT_MST_Ward ward on bedInfo.WardId=ward.WardID
	where bedInfo.IsActive=1 
	and bedInfo.Action !='cancel'
	AND CONVERT(date,bedInfo.StartedOn) < @FromDate 
	AND   @FromDate <= CONVERT(date,ISNULL(bedInfo.EndedOn,Getdate())))
	as flatData Group By flatData.WardName

	--select flatData.WardName, Count(*) as TotalCount
	--from (select bedInfo.*,ward.WardName from ADT_TXN_PatientBedInfo bedInfo
	--Join ADT_MST_Ward ward on bedInfo.WardId=ward.WardID
	--where bedInfo.IsActive=1 and bedInfo.EndedOn Is Null 
	--and bedInfo.OutAction Is Null and CONVERT(date,bedInfo.StartedOn) < @FromDate
	--and ((bedInfo.Action='admission') or (bedInfo.Action='transfer'))) as flatData Group By flatData.WardName, flatData.OutAction

	END

END