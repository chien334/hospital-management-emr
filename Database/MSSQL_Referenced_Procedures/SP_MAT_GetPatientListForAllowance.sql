CREATE PROCEDURE [dbo].[SP_MAT_GetPatientListForAllowance] 
   @SearchTxt varchar(200) = '',
   @IsSearchAll bit=0,
   @RowCounts INT = NULL
AS

/*
 FileName: [SP_MAT_GetPatientListForAllowance] 
 Created: 17-Nov'21/Dhanashri
 Description: To Get the Patients Info For Maternity Allowance Payment + Patients matching given search conditions.
            -- Returns upto 200 patients
 Change History
 S.No.    Date/User              Change          Remarks
 1.       17-Nov'21/Dhanashri                  Created SP for get patient list for maternity allowance payment
 2.       19-Nov'21/Aniket					   Updated query with select pat.patient
 3.       21-Nov'21/Aniket					   Updated query with select pat.DateofBirth 
*/

IF(@IsSearchAll = 0) 
	BEGIN  
		SET @RowCounts=ISNULL(@RowCounts,200)--default rowscount=200
		IF(@SearchTxt='null')
		BEGIN
			SET @SearchTxt=null
		END
		Select top (@RowCounts)
		  pat.PatientId,pat.PatientCode,pat.FirstName,pat.LastName,pat.ShortName,pat.Age,pat.Gender,pat.PhoneNumber,pat.Address,adt.DischargeDate,pvs.VisitCode,pat.DateOfBirth
		  from ADT_PatientAdmission adt
		  JOIN PAT_Patient pat on adt.PatientId = pat.PatientId
		  JOIN PAT_PatientVisits pvs on adt.PatientVisitId = pvs.PatientVisitId
		  where pat.IsActive=1 and  AdmissionCase = 'Safe Mother Program' and AdmissionStatus = 'Discharged'and pat.Gender='Female' and 
			   (ISNULL(pvs.VisitCode,'') like '%' + ISNULL(@SearchTxt,'') + '%'
			   OR pat.PatientCode like '%' + ISNULL(@SearchTxt,'') + '%'
			   or pat.ShortName like '%' + ISNULL(@SearchTxt,'') + '%'  
			   OR ISNULL(pat.PhoneNumber,'') LIKE '%' + ISNULL(@SearchTxt,'') + '%')
		Order by adt.DischargeDate DESC 
	END
ELSE
	BEGIN 
	SET @RowCounts=ISNULL(@RowCounts,200)--default rowscount=200
		IF(@SearchTxt='null')
		BEGIN
			SET @SearchTxt=null
		END
		Select top (@RowCounts)
			pat.PatientId,pat.PatientCode,pat.FirstName,pat.LastName,pat.ShortName,pat.Age,pat.Gender,pat.PhoneNumber,pat.Address,adt.DischargeDate,pvs.VisitCode,pat.DateOfBirth
			from ADT_PatientAdmission adt
			JOIN PAT_Patient pat on adt.PatientId = pat.PatientId
			JOIN PAT_PatientVisits pvs on adt.PatientVisitId = pvs.PatientVisitId
			where  pat.IsActive=1 and  AdmissionStatus = 'Discharged' and
				(ISNULL(pvs.VisitCode ,'') like '%' + ISNULL(@SearchTxt,'') + '%'
				 OR pat.PatientCode like '%' + ISNULL(@SearchTxt,'') + '%'
				 or pat.ShortName like '%' + ISNULL(@SearchTxt,'') + '%'  
				 OR ISNULL(pat.PhoneNumber,'') LIKE '%' + ISNULL(@SearchTxt,'') + '%')
			Order by adt.DischargeDate DESC 
	END