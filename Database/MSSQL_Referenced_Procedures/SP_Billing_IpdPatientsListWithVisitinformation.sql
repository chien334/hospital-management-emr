CREATE PROCEDURE [dbo].[SP_Billing_IpdPatientsListWithVisitinformation]
   @SearchTxt varchar(200) = ''
AS

/*
 FileName:  [SP_Billing_IpdPatientsListWithVisitinformation] ''
 Created: 20Feb'21/Sud
 Description: To Search for IPD Patients with PatientName or VisitCode.
 Remarks: We need to reuse this stored procedure also for other pages.. right now used only for billing.
 Change History
 S.No.    Date/User              Change          Remarks
 1.	     20Feb'21/Sud		                   inital draft
 2.		 27April'21/Anjana					IPD Search using patientcode 
											of discharged cancelled patient
 3.		 5 May,'21/Anjana					Fixed issue of showing all patient in search
 4.		20July21, Sanjit/Sud				Show outdoor patient in billing as well since it is seen in ADT Search Patient --SNCH 20July21
 5.     Sud:9Sep'21                         Handle Search by PatientCode (Hospital Number as well)
                                           needed since IPD-Patient many times give the cards with hospital number only, 
										   so its necessary to search by HospNumber as well.
 6.		Krishna/24thNov'22				   Add Phone Number Search for IPD Search
 7.		Krishna/22ndMay'23				   Add SchemeId and PriceCategoryId in Select Query
 8.     Bibek/18thJune'23                  Add Visit Type in select query 
 9.	    Krishna/19thJune'23				   Read SchemeName for Patient Information
*/
BEGIN	   

Select 
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
	pat.Address,
	pat.IsOutdoorPat,
	pat.CreatedOn,
	pat.CountryId,
	pat.CountrySubDivisionId,
	sub.CountrySubDivisionName,
	ISNULL(pat.MembershipTypeId,4) as MembershipTypeId,
	ISNULL(scheme.SchemeName, 'General') as MembershipTypeName, -- fix it later
	ISNULL(scheme.DiscountPercent,0) 'MembershipDiscountPercent',
	pat.PANNumber,
	pat.BloodGroup,
	pat.DialysisCode,
	adm.VisitType,
	case when adm.PatientId is not null then 1
		 else 0 END as IsAdmitted,
    adm.WardName, adm.BedCode, adm.BedNumber,adm.VisitCode,adm.PatientVisitId,
	case when ins.PatientId is not null then ins.CurrentBalance
			else 0 END as Insurance,
	adm.SchemeId,
	adm.PriceCategoryId,
	scheme.SchemeName

from 
    (
		 select adm.PatientId, adm.PatientVisitId,visit.VisitCode,visit.VisitType,
		   ward.WardName, bed.BedCode, bed.BedNumber, bedInfo.StartedOn, visit.SchemeId, visit.PriceCategoryId
		 from ADT_PatientAdmission adm
		 inner join (select * from PAT_PatientVisits) visit
			on  adm.PatientVisitId= visit.PatientVisitId
		 inner join (Select * from ADT_TXN_PatientBedInfo 
					where IsActive=1 and OutAction is null) bedInfo
		   ON adm.PatientVisitId=bedInfo.PatientVisitId
		     INNER JOIN ADT_MST_Ward ward on bedInfo.WardId=ward.WardID
		   inner join ADT_Bed bed on bedInfo.BedId = bed.BedID
		      Where adm.AdmissionStatus='admitted'
	)adm

	INNER JOIN 

  PAT_Patient pat   on pat.PatientId=adm.PatientId
 INNER JOIN  MST_Country cntry on pat.CountryId=cntry.CountryId
 inner join MST_CountrySubDivision sub
    on pat.CountrySubDivisionId=sub.CountrySubDivisionId

  left join BIL_CFG_Scheme scheme on adm.SchemeId=scheme.SchemeId

  Left join (
    Select patIns.PatientId, patins.CurrentBalance
	 from PAT_PatientInsuranceInfo patIns INNER JOIN INS_CFG_InsuranceProviders insProv
	on patIns.InsuranceProviderId = insProv.InsuranceProviderId
	Where insProv.InsuranceProviderName='Government Insurance'

   ) ins on pat.PatientId = ins.PatientId

 WHERE --ISNULL(pat.IsOutdoorPat,0) = 0 and    --Sanjit/Sud Show outdoor patient in billing as well since it is seen in ADT Search Patient --SNCH 20July21
 pat.IsActive=1 and 
 (pat.ShortName like '%' + ISNULL(@SearchTxt,'') +'%' 
    or adm.VisitCode like '%' + ISNULL(@SearchTxt,'') + '%'
	or pat.PatientCode like '%' + ISNULL(@SearchTxt,'') + '%'
	or pat.PhoneNumber = @SearchTxt)
 
END