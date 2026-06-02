--END--Search Patient SP altered--

--START: Insurance Search Patient SP altered---

CREATE PROCEDURE [dbo].[SP_INS_SearchInsurancePatients] 
   @SearchTxt varchar(200) = '',
   @RowCounts INT = NULL
AS

/*
 FileName: [SP_INS_SearchInsurancePatients] 
 Created: 10-Oct'21/Sud
 Description: To Get the Patients Info + IsAdmitted for patient matching given search conditions.
            -- Returns upto 200 patients
			--Match fields: NSHI Number, ShortName, PatientCode (HospitalNo), PhoneNumber
 Remarks:  Searches only for Insurance patients, other informations can be removed if not required. 
 Change History
 S.No.    Date/User              Change          Remarks
 1.       10-Oct'21/Sud                          inital draft 
 2.       28-Oct'21/Sud                          Sending InsuranceProviderId of Gov-Insurance in return data.
                                                 it was causing issue in InsuranceBalanceUpdate because of null value. 
*/
BEGIN  
SET @RowCounts=ISNULL(@RowCounts,200)--default rowscount=200

IF(@SearchTxt='null')
BEGIN
  SET @SearchTxt=null
END

--Need to send back insurance providerid of GovernmentInsuarnce--
Declare @InsProviderId INT
Set @InsProviderId=( Select InsuranceProviderId from INS_CFG_InsuranceProviders
					 where InsuranceProviderName='Government Insurance')

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED ;

Select top (@RowCounts)
  pat.PatientId,
  pat.PatientCode,
  pat.ShortName,
  pat.FirstName,
  pat.LastName,
  pat.MiddleName,
  pat.PatientNameLocal,
  pat.Age,
  pat.Gender,
  pat.PhoneNumber,
  pat.DateOfBirth,
  pat.Address,
  pat.IsOutdoorPat,  pat.CreatedOn,
  pat.CountryId, cntry.CountryName,  pat.CountrySubDivisionId,  sub.CountrySubDivisionName,
  pat.MunicipalityId,munc.MunicipalityName,  
  pat.MembershipTypeId,  memb.MembershipTypeName,
  memb.DiscountPercent 'MembershipDiscountPercent',
  pat.PANNumber,  pat.BloodGroup, 
  pat.Ins_HasInsurance,
  pat.Ins_NshiNumber,
  pat.Ins_InsuranceBalance,
  pat.Ins_LatestClaimCode AS LatestClaimCode,
  case when adm.PatientId is not null then 1
     else 0 END as IsAdmitted,
  @InsProviderId as InsuranceProviderId

from PAT_Patient pat
 INNER JOIN  MST_Country cntry on pat.CountryId=cntry.CountryId
 inner join MST_CountrySubDivision sub
    on pat.CountrySubDivisionId=sub.CountrySubDivisionId
  inner join PAT_CFG_MembershipType memb on pat.MembershipTypeId=memb.MembershipTypeId
  LEFT JOIN 
  (
   Select distinct PatientId from ADT_PatientAdmission
   Where AdmissionStatus='admitted'
  ) adm
  on pat.PatientId=adm.PatientId

Left join MST_Municipality munc
   ON pat.MunicipalityId=munc.MunicipalityId

where pat.IsActive=1 
 and pat.Ins_HasInsurance=1 --take only insurance patients. 
and (
       ISNULL(pat.Ins_NshiNumber,'') like '%' + ISNULL(@SearchTxt,'') + '%'
       OR pat.PatientCode like '%' + ISNULL(@SearchTxt,'') + '%'
       or pat.ShortName like '%' + ISNULL(@SearchTxt,'') + '%'  
	   OR ISNULL(pat.PhoneNumber,'') LIKE '%' + ISNULL(@SearchTxt,'') + '%'
	 )
Order by PatientId DESC 

END