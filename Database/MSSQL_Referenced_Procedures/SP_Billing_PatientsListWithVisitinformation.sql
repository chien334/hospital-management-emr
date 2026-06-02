CREATE PROCEDURE [dbo].[SP_Billing_PatientsListWithVisitinformation] 
@SearchTxt varchar(200) = '',
@ShowInpatient BIT = 0

AS

/*
 FileName: [SP_Billing_PatientsListWithVisitinformation] 
 Created:  Nirmala/18Nov'22
 Description: Patient can be searched through phone number
 Change History
 S.No.    Date/User              Change          Remarks
 1.       29Jan2021/pratik                    inital draft
 2.      26Jul'21/Ramesh                      IsOutdoorPat is also shown in Billing/ADT
 3.      8Aug'21/Anish                        Getting Latest VisitId and Code for OP-Billing 
 4.      22Dec'21/Sud                         Added top(200) 
 5.		 18th,Jul'22/Krishna				  Address selection with Municipality and CountrySubDivision
 6.      18th,Nov'22/Nirmala                  Patient can be searched through phone number
 7.		 8th,Jan'23/Krishna					  Added MedicareMemberNo in Select Statement.
 8.	     23rdMarch'23/Krishna				  remove Join With PAT_CFG_MembershipType and Make a join With BIL_CFG_Scheme
 9.		 31stMarch'23/Sanjeev				  Add JOIN with PAT_MAP_PatientSchemes, Add MedicareEmployeeName, MedicareDegination, 
											  PolicyNumber and Relation in Select Statement
 10.     5th April'23/DevN                    Added New Parameter @ShowInpatient. If not supplied default value is false
											  if supplied manaually it will show inpatient detail irrespective of the paramerter
											  ShowIPInSearchPatient.
11.		 16thApril'23/Bibek 				  Added Visit type to display in the change visit scheme		
12.		 15thMay'23/Krishna					  Handle Null check for Address field
13.		 5thJune'23/Krishna					  Add PriceCategory in the select Query
14.		 23rdJune'23/Krishna				  Read VisitDate to verify Followup days in client side
*/
BEGIN  

declare @showHideIpParam varchar(10);
declare @showHideIPIndicator bit;
set @showHideIpParam = (select ParameterValue from CORE_CFG_Parameters where ParameterName='ShowIPInSearchPatient');
set @showHideIPIndicator = (SELECT CASE WHEN LOWER(@showHideIpParam)='true' OR @showHideIpParam='1' THEN 1 ELSE 0 END);
if(@ShowInpatient = 1)
BEGIN
	SET @showHideIPIndicator = 1
END

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED ;

 Select Top(200)
 pat.PatientId,
 pat.PatientCode,
 pat.ShortName,
 pat.FirstName,
 pat.LastName,
 pat.MiddleName,
 pat.Age,
 cntry.CountryName,
 pat.Gender,
 pat.PhoneNumber,
 pat.DateOfBirth,
 ISNULL(pat.Address,'') + ISNULL(', '+ mun.MunicipalityName,'') + ISNULL(', '+ country.CountrySubDivisionName,'') as 'Address',
 pat.IsOutdoorPat,
 pat.CreatedOn,
 pat.CountryId,
 pat.CountrySubDivisionId,
 sub.CountrySubDivisionName,
 pat.MembershipTypeId,
 scheme.SchemeName,
 scheme.SchemeId,
 --scheme.DiscountPercent 'MembershipDiscountPercent',
 pat.PANNumber,
 pat.BloodGroup,
 pat.DialysisCode,
 CASE WHEN adm.PatientId IS NOT NULL THEN 1
      ELSE 0 END AS IsAdmitted,
 adm.WardName, 
 adm.BedCode, 
 adm.BedNumber,
 ISNULL(adm.VisitCode,latestVisit.VisitCode) AS VisitCode,
 ISNULL(adm.PatientVisitId,latestVisit.PatientVisitId) AS  PatientVisitId,  
 CASE WHEN ins.PatientId IS NOT NULL THEN ins.CurrentBalance
     ELSE 0 END AS Insurance,
 medicareMem.MemberNo AS 'MedicareMemberNo',
 patMapScheme.PolicyNo,
 medicareMem.NameOfMedicareEmployee 'MedicareEmployeeName',
 medicareMem.Designation,
 medicareMem.Relation,
 adm.VisitType,
 latestVisit.PriceCategoryId,
 latestVisit.VisitDate
		FROM PAT_Patient pat
		INNER JOIN  MST_Country cntry on pat.CountryId=cntry.CountryId
		INNER JOIN MST_CountrySubDivision sub on pat.CountrySubDivisionId=sub.CountrySubDivisionId
		LEFT JOIN (
		    SELECT adm.PatientId, adm.PatientVisitId,visit.VisitCode, visit.VisitType,
		      ward.WardName, bed.BedCode, bed.BedNumber, bedInfo.StartedOn 
		    FROM ADT_PatientAdmission adm
		    INNER JOIN  PAT_PatientVisits visit
		     ON  adm.PatientVisitId= visit.PatientVisitId
		    INNER JOIN (SELECT * FROM ADT_TXN_PatientBedInfo 
		         WHERE IsActive=1 AND OutAction IS NULL) bedInfo
		      ON adm.PatientVisitId=bedInfo.PatientVisitId
		        INNER JOIN ADT_MST_Ward ward on bedInfo.WardId=ward.WardID
		      INNER JOIN ADT_Bed bed on bedInfo.BedId = bed.BedID
		         Where adm.AdmissionStatus='admitted'
		 )adm on pat.PatientId=adm.PatientId
		 LEFT JOIN (
		   SELECT patIns.PatientId, patins.CurrentBalance
				  FROM PAT_PatientInsuranceInfo patIns INNER JOIN INS_CFG_InsuranceProviders insProv
				  ON patIns.InsuranceProviderId = insProv.InsuranceProviderId
		 WHERE insProv.InsuranceProviderName='Government Insurance'
		  ) ins ON pat.PatientId = ins.PatientId
		  LEFT JOIN(
		   SELECT PatientId, PatientVisitId, VisitCode, SchemeId, PriceCategoryId, VisitDate
		     FROM 
		     (
		     SELECT ROW_NUMBER() OVER (PARTITION BY patientid ORDER BY patientvisitid DESC) row_num,
					PatientId, 
					PatientVisitId,
					VisitCode, 
					SchemeId,
					PriceCategoryId,
					VisitDate
		     FROM 
		        PAT_PatientVisits
		     ) A
		     WHERE row_num=1
		  ) latestVisit ON pat.PatientId=latestVisit.PatientId
		  --Krishna, 23rdMarch'23 Bwloe Join Should not be a left join here,
		  --When there would be Visit compulsory we need to make both Visit and Scheme as Inner Joins..
		  LEFT JOIN BIL_CFG_Scheme scheme ON scheme.SchemeId = latestVisit.SchemeId 
		  LEFT JOIN MST_Municipality mun ON mun.MunicipalityId = pat.MunicipalityId
		  LEFT JOIN MST_CountrySubDivision country ON country.CountrySubDivisionId = pat.CountrySubDivisionId
		  LEFT JOIN (
			SELECT MemberNo, '' AS 'Relation', '' AS 'NameOfMedicareEmployee',EmployeeRoleName AS 'Designation',memb.PatientId FROM INS_MedicareMember memb
			JOIN  EMP_EmployeeRole role ON memb.DesignationId = role.EmployeeRoleId WHERE IsDependent = 0
			UNION ALL
			SELECT dependent.MemberNo, dependent.Relation, member.FullName AS 'NameOfMedicareEmployee', EmployeeRoleName AS 'Designation',dependent.PatientId FROM INS_MedicareMember member
			JOIN INS_MedicareMember dependent on member.MedicareMemberId = dependent.ParentMedicareMemberId
			JOIN  EMP_EmployeeRole role ON dependent.DesignationId = role.EmployeeRoleId
			WHERE dependent.IsDependent = 1
		  ) AS medicareMem ON medicareMem.PatientId = pat.PatientId
 
		  LEFT JOIN PAT_MAP_PatientSchemes patMapScheme ON patMapScheme.SchemeId = scheme.SchemeId AND patMapScheme.LatestPatientVisitId = latestVisit.PatientVisitId
WHERE pat.IsActive=1 
AND 
((adm.PatientId IS NULL) OR (@showHideIPIndicator=1)) 
 AND (pat.ShortName LIKE '%' + ISNULL(@SearchTxt,'') + '%' 
       or pat.PatientCode LIKE '%' + ISNULL(@SearchTxt,'') + '%'
	   or pat.PhoneNumber LIKE '%' + ISNULL(@SearchTxt,'')+'%'
	   )
END