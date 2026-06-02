CREATE PROCEDURE [dbo].[SP_PAT_RegisteredPatientList]
@SearchTxt varchar(200) = '', 
@RowCounts INT = NULL 
AS 
/*
FileName: [SP_PAT_RegisteredPatientList] null
Created: 17-Dec'21/Krishna
Description: To Get the Patients List
				-- Returns upto 200 patients
				--Match fields: ShortName, PatientCode (HospitalNo), PhoneNumber
Remarks:   
Change History
S.No.    Date/User              Change          Remarks
1.       17-Dec'21/Krishna                          inital draft 
2.       17-June'22/Devendra     Concatenate patient address field
3.		 10-October'23/Sanjeev	 Add WardNumber on select query.
*/

BEGIN 
	IF(@SearchTxt = 'null') 
BEGIN 
	SET @SearchTxt = null 
END 
	SET @RowCounts = ISNULL(@RowCounts, 200) --default rowscount=200

 SELECT TOP (@RowCounts) 
	  pat.PatientId, 
	  pat.PatientCode, 
	  pat.ShortName, 
	  pat.FirstName, 
	  pat.LastName, 
	  pat.MiddleName, 
	  pat.Age, 
	  pat.Gender, 
	  pat.PhoneNumber, 
	  pat.DateOfBirth, 
	  ISNULL(pat.[Address],'') + ' ' + ISNULL(mun.MunicipalityName,'') +   ' ' + ISNULL(district.CountrySubDivisionName,'')  as [Address], 
	  pat.IsOutdoorPat, 
	  pat.CreatedOn,
	  pat.WardNumber

 FROM 
	  PAT_Patient pat 
	  LEFT Join MST_CountrySubDivision district on pat.CountrySubDivisionId = district.CountrySubDivisionId
	  LEFT JOIN MST_Municipality mun on pat.MunicipalityId = mun.MunicipalityId
 WHERE 
	  pat.IsActive = 1 
	  AND (
		pat.PatientCode LIKE '%' + ISNULL(@SearchTxt, '') + '%' 
		OR pat.ShortName LIKE '%' + ISNULL(@SearchTxt, '') + '%' 
		OR ISNULL(pat.PhoneNumber, '') LIKE '%' + ISNULL(@SearchTxt, '') + '%'
	  ) 
	ORDER BY 
	  PatientId DESC --Show recent patient at top.. 
  END