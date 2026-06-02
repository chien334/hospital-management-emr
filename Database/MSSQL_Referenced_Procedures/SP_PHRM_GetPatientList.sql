--START: ----- Search Patient SP Altered for Dispensary Module--  
CREATE PROCEDURE [dbo].[SP_PHRM_GetPatientList]  
   @SearchTxt varchar(200) NULL,  
   @IsInsurance Bit= NULL  
AS  
/*  
 FileName: [SP_PHRM_GetPatientList] '018658684'  
 Created: 09Oct'21/Sud/Sanjit  
 Description: To get Patient along with Insurance Information + latest visit's doctor information.   
     --when @IsInsurance= false or null then get all patient.  
  --When @SearchTxt is null or empty then get all patients.  
  --@SearchTxt compares these columns: PatientCode, ShortName, InsuranceNSHI Code, PhoneNumber..  (add more fields if required later).  
   
 Remarks: Need to add more fields later as required..   
 Change History  
 S.No.    Date/User                     Change          Remarks  
 1.       09Oct'21/Sud/Sanjit           Created          Initial Draft. 
 2.		  2Jun'22/Krishna				alter			 Changed ProviderId to PerformerId
*/  
BEGIN   
  
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED ;  
  
Select TOP(200) pat.PatientId,  
 pat.PatientCode,  
 pat.FirstName,  
 pat.MiddleName,  
 pat.LastName,  
 pat.ShortName,  
 pat.Age,  
 pat.Gender,  
 pat.PhoneNumber,  
 pat.DateOfBirth,  
 pat.Address,  
 pat.IsOutdoorPat,  
 pat.CountryId,  
 pat.CountrySubDivisionId,  
 district.CountrySubDivisionName,  
 pat.PANNumber,  
 pat.Ins_NshiNumber,  
 pat.Ins_LatestClaimCode AS ClaimCode,  
 pat.Ins_HasInsurance,  
 pat.Ins_InsuranceBalance,  
 latestVisit.PatientVisitId,  
 Convert(varchar(20),Convert(Date,latestVisit.VisitDate)) AS VisitDate,  
 latestVisit.PerformerId  
  
from PAT_Patient pat  
 inner join MST_CountrySubDivision district on pat.CountrySubDivisionId=district.CountrySubDivisionId  
 left Join(  
      
    Select PatientId, PatientVisitId, VisitCode, PerformerId, VisitDate  
      from   
      (  
      SELECT   
         ROW_NUMBER() OVER (  
          PARTITION BY PatientId  
          ORDER BY PatientVisitId desc  
         ) row_num,  
         PatientId, PatientVisitId,VisitCode, PerformerId, VisitDate  
  
      FROM   
         PAT_PatientVisits  
      ) A  
      where row_num=1  
   ) latestVisit on pat.PatientId = latestVisit.PatientId  
  
Where (pat.PatientCode+ pat.ShortName + ISNULL(pat.PhoneNumber,'') + ISNULL(pat.Ins_NshiNumber,'')) like '%'+ISNULL(@SearchTxt,'')+'%'  
   AND (ISNULL(@IsInsurance,0)=0 OR pat.Ins_HasInsurance = @IsInsurance)  
  
END