CREATE PROCEDURE SP_PAT_ECHSPatientsListWithVisitinformation
				 @SearchTxt varchar(200) = ''

AS

/*
 FileName: [SP_PAT_ECHSPatientsListWithVisitinformation] 
 Created:  Krishna/26thSept'23
 Description: Search ECHS Patient Only for ECHS Claim Form
 Change History
 S.No.    Date/User							Change					Remarks
 1.       26thSept'23/Krishna				create					inital draft
*/
BEGIN  


SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED ;

 SELECT TOP(200)
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
	   AND scheme.ApiIntegrationName = 'ECHS' 
	   AND (pat.ShortName LIKE '%' + ISNULL(@SearchTxt,'') + '%' 
       OR pat.PatientCode LIKE '%' + ISNULL(@SearchTxt,'') + '%'
	   OR pat.PhoneNumber LIKE '%' + ISNULL(@SearchTxt,'')+'%'
	)
END