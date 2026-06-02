CREATE Procedure SP_GetPatientStickerDetails
@PatientId int = null
As
/*
FileName: [SP_GetPatientStickerDetails]
CreatedBy/date: Aniket/26-10-2021
Recreated By: Krishna, 19thApril'23
Description: To get the Details of Patient Sticker
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1.    Aniket/26-10-2021                    created the script
2.	  Krishna/19thApril'23				   Recreate the script as it was dropped earlier
*/
Begin
      If @PatientId Is not null
          Begin
          select p.PatientCode as 'HospitalNo', 
		         p.ShortName as 'PatientName', 
				 p.Age as 'Age',
				 p.PhoneNumber as 'Contact', 
				 p.Address as 'Address',
				 p.Gender as 'Gender',
				 p.DateOfBirth as 'DateOfBirth',
				 m.MunicipalityName as 'MunicipalityName',
				 c.CountryName as 'CountryName',
				 cs.CountrySubDivisionName as 'District'
          from PAT_Patient p
		  LEFT JOIN MST_Municipality as m on p.MunicipalityId = m.MunicipalityId
		  LEFT JOIN MST_Country as c on p.CountryId = c.CountryId
		  LEFT JOIN MST_CountrySubDivision as cs on p.CountrySubDivisionId = cs.CountrySubDivisionId
		  where PatientId = @PatientId
          End
End