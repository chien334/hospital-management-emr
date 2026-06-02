-- =============================================
-- Author:		<Anish Bhattarai>
-- Create date: <24 March>
-- Description:	<Get the existing patient list in Vaccination Module Patient Search>
-- =============================================
CREATE PROCEDURE [dbo].[SP_Vaccination_Baby_PatientList]  
@SearchTxt varchar(200) = ''
AS

BEGIN

declare @twoYearsBack date;
set @twoYearsBack = Convert(date,DATEADD(year, -2, GETDATE())); 
	Select 
	pat.PatientId,
	pat.PatientCode,
	pat.Age,
	pat.ShortName,
	pat.DateOfBirth,
	pat.Gender,
	pat.PhoneNumber,
	pat.Address,
	pat.VaccinationRegNo,
	pat.EthnicGroup,
	pat.FatherName,
	pat.MotherName,
	pat.CountryId,
	pat.CountrySubDivisionId
from PAT_Patient pat 
where (COALESCE(pat.IsVaccinationActive, 0) = 0)  and pat.DateOfBirth IS NOT NULL and (COALESCE(pat.IsVaccinationPatient, 0) = 0) 
and (Convert(date,pat.DateOfBirth) > @twoYearsBack) and (pat.ShortName like '%' + ISNULL(@SearchTxt,'') + '%' or pat.PatientCode like '%' + ISNULL(@SearchTxt,'') + '%')
END