CREATE PROCEDURE [dbo].[SP_MR_PatientsListWithVisitId] 
@SearchTxt varchar(200) = ''
AS
--/*
-- FileName: [SP_MR_PatientsListWithVisitId] 
-- Created: 8th Sep 2021/Prem/Bikas/Sanjit
-- Description: To Get the Patients list with Visit Id to add Death details in MR
-- Execution Example:
--  exec SP_MR_PatientsListWithVisitId 'sunita'
-- Remarks: 
-- --------------------------------------------------------------------------------------------------------
-- Change History
-- --------------------------------------------------------------------------------------------------------
-- S.No.    Date/User              Change										Remarks
-- --------------------------------------------------------------------------------------------------------
--	1.		15th-Aug-2021		Only dead patient recorded					Outpatients not taken in consideration
--								in MR_RecordSummary table(Inpatients) 
--								taken in consideration.
-- --------------------------------------------------------------------------------------------------------
--*/
BEGIN 

SELECT 
  pat.PatientId 
  ,mrs.PatientVisitId
  ,mrs.MedicalRecordId
  ,pat.PatientCode
  ,pat.ShortName
  ,pat.Age
  ,pat.Gender
  ,ISNULL(pat.PhoneNumber, '') as PhoneNumber
  ,pat.DateOfBirth
  ,ISNULL(pat.Address, '') as Address  
FROM MR_RecordSummary mrs
  INNER JOIN PAT_Patient pat on mrs.PatientId = pat.PatientId
  INNER JOIN ADT_DischargeType disType on disType.DischargeTypeId = mrs.DischargeTypeId
WHERE pat.IsActive = 1
	and LOWER(disType.DischargeTypeName) ='death'
  and (pat.ShortName like '%' + ISNULL(@SearchTxt,'') + '%' or pat.PatientCode like '%' + ISNULL(@SearchTxt,'') + '%')
END