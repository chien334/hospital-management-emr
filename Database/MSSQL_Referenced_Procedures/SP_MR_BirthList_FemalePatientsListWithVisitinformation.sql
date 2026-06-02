/*
 FileName: [SP_MR_BirthList_FemalePatientsListWithVisitinformation] 
 Created: 6th May 2021/Bikash
 Description: To Get the Female Patients list with Visit information
 Remarks: 
 Change History
 S.No.    Date/User  						Remarks
 1.	     6thMay2021/Bikash					inital draft
 2.		 12th-May-2021/Bikash				show female patient from age group 12-49
 3.		 8th-Sept-2021/Bikash				Only admitted patient taken in considration for search
*/

CREATE PROCEDURE [dbo].[SP_MR_BirthList_FemalePatientsListWithVisitinformation]
@SearchTxt varchar(200) = ''
AS
BEGIN	   
	SELECT distinct
		pat.PatientId,
		pat.PatientCode,
		pat.ShortName,
		pat.Age,
		pat.Gender,
		pat.PhoneNumber,
		pat.DateOfBirth,
		pat.Address
	FROM PAT_Patient pat
		inner join PAT_PatientVisits visit on visit.PatientId = pat.PatientId
		inner join ADT_PatientAdmission adm on adm.PatientId = pat.PatientId
	WHERE adm.AdmissionStatus in ('admitted','discharged') 
		and ISNULL(pat.IsOutdoorPat,0) = 0 
		and pat.IsActive=1
		and (FLOOR(DATEDIFF(DAY, pat.DateOfBirth, GETDATE()) / 365.25)>=12 
		and FLOOR(DATEDIFF(DAY, pat.DateOfBirth, GETDATE()) / 365.25)<=49) 
		and pat.Gender = 'Female' 
		and ((pat.ShortName like '%' + ISNULL(@SearchTxt,'') + '%' or pat.PatientCode like '%' + ISNULL(@SearchTxt,'') + '%'))
	
END