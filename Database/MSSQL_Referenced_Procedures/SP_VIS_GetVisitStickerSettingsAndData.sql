CREATE PROCEDURE [dbo].[SP_VIS_GetVisitStickerSettingsAndData]         
     @PatientVisitId INT=null  
AS  
/*  
FileName: SP_VIS_GetVisitStickerSettingsAndData  
CreatedBy/date: Sud:26Mar'23
Description: All fields values required for Sticker Print of OP/ER/IPD from CurrentVisit. 
           : Returns 2 tables.   1> StickerSettings for CurrentVisit/Scheme , 2> StickerData for CurrentVisit
Logic Used:
     --To get Sticker Settings----
       > Get SchemeId and VisitType from Visit Table
	   > Get StickerGroupCode from SchemeTable
	   > Get StickerName and SettingsData from StickerSettings table
	   > Remarks: Use Default if StickerGroupCode not found in Scheme Table
    --To Get StickerData--
	  > Join Visit, Patient, AdmissionBedInfo, Scheme, Department etc tables to get necessary data
	  > Remarks: For inpatient, get the 1st Bed where patient was admitted

USAGE: EXEC SP_VIS_GetVisitStickerSettingsAndData 79818

Change History  
S.No.    UpdatedBy/Date                        Remarks  
1.      Sud:26Mar'23                        InitialDraft - Rewrite after NewStructure in Visit/Billing
2.		Krishna, 6thApril'23				Format PatientAddress
3.		Devendra, 11thJuly'23				Adding queueNo setting
4.		Krishna, 15thJuly'23				Format PatientAddress to show Municipaliy and wardNumber
*/  
BEGIN  
 
 
Declare @CurrentSchemeId INT, @VisitType Varchar(20), @StickerGroupCode varchar(20),  @StickerName varchar(20)

Select @CurrentSchemeId=vis.SchemeId, @VisitType=VisitType, @StickerGroupCode=sch.RegStickerGroupCode
from PAT_PatientVisits vis INNER JOIN BIL_CFG_Scheme sch on vis.SchemeId=sch.SchemeId
where PatientVisitId=@PatientVisitId

IF(@StickerGroupCode IS NOT NULL)
BEGIN
    SET @StickerName = (Select TOp(1) StickerName from CFG_RegistrationStickerSettings 
                       Where ISNULL(VisitType,'outpatient')= @VisitType
					          AND StickerGroupCode=@StickerGroupCode)
END
ELSE
BEGIN
 SET @StickerName = (Select TOp(1) StickerName from CFG_RegistrationStickerSettings 
                       Where ISNULL(VisitType,'outpatient') = @VisitType
					          AND IsDefaultForCurrentVisitType=1)
END



--Return Table-1: StickerSettings----
Select 
     RegistrationStickerSettingsId,StickerName,StickerGroupCode,VisitType,IsDefaultForCurrentVisitType
	,VisitDateLabel,ShowSchemeCode,ShowMemberNo,MemberNoLabel,ShowClaimCode,ShowIpdNumber,ShowWardBedNo
	,ShowRegistrationCharge,ShowPatContactNo,ShowPatientDesignation,PatientDesignationLabel,ShowQueueNo,QueueNoLabel
from CFG_RegistrationStickerSettings
Where StickerName=@StickerName


--Return Table-2: StickerData----
Select 
	vis.PatientId,
	vis.PatientVisitId,
	pat.PatientCode 'HospitalNumber',
	pat.ShortName 'PatientName',
	pat.Gender,
	pat.DateOfBirth,
	ISNULL(dist.CountrySubDivisionName,'') + ISNULL(', '+mun.MunicipalityName,'') + ISNULL('-'+ CONVERT(VARCHAR(10),pat.WardNumber),'') AS 'PatientAddress',
	pat.PhoneNumber 'PatientPhoneNumber',
	pat.Rank 'PatientDesignation',

	vis.VisitCode,
	Convert(DateTime,Convert(Date,vis.VisitDate)) + Convert(DateTime,vis.VisitTime) AS 'VisitDateTime',
	Case WHEN vis.VisitType='outpatient' THEN 'OPD'
		 WHEN vis.VisitType='inpatient' THEN 'IPD'
		 WHEN vis.VisitType='emergency' THEN 'ER'
		 ELSE '' END AS 'VisitTypeFormatted',
	vis.AppointmentType,
	dep.DepartmentName,
	vis.PerformerName AS 'PerformerName',
	vis.TicketCharge,
	wardBed.WardName,
	wardBed.BedNumber,
	usr.UserName,
	vis.ClaimCode,
	sch.SchemeCode,
	patSch.PolicyNo 'MemberNo',
	Vis.QueueNo
from PAT_PatientVisits vis
INNER JOIN PAT_Patient pat on vis.PatientId=pat.PatientId
INNER JOIN MST_Department dep on vis.DepartmentId=dep.DepartmentId
INNER JOIN BIL_CFG_Scheme sch on vis.SchemeId=sch.SchemeId
INNER JOIN RBAC_User usr on vis.CreatedBy=usr.EmployeeId 
LEFT JOIN MST_CountrySubDivision dist ON pat.CountrySubDivisionId = dist.CountrySubDivisionId
LEFT JOIN MST_Municipality mun ON pat.MunicipalityId = mun.MunicipalityId
LEFT JOIN ( Select * from
			(
				Select bedInfo.PatientVisitId, w.WardName, b.BedNumber,
				ROW_NUMBER() OVER (Partition BY PatientVisitId order by bedInfo.PatientBedInfoId) AS RowNum
				from ADT_TXN_PatientBedInfo bedInfo
				INNER JOIN ADT_MST_Ward w on bedInfo.WardId=w.WardID
				inner join ADT_Bed b on bedInfo.BedId=b.BedID
			)bedInfo1 Where RowNum=1) wardBed ON vis.PatientVisitId=wardBed.PatientVisitId

LEFT JOIN PAT_MAP_PatientSchemes patSch on vis.SchemeId=patSch.SchemeId and vis.PatientId=patSch.PatientId

Where vis.PatientVisitId=@PatientVisitId

END