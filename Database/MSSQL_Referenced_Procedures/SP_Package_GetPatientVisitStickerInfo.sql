CREATE PROCEDURE [dbo].[SP_Package_GetPatientVisitStickerInfo] 		--- SP_Package_GetPatientVisitStickerInfo 45680
      @BillingTransactionId INT = null AS 		
/*
FileName: SP_Package_GetPatientVisitStickerInfo
CreatedBy/date: Sanjit / 2019-12-2
Description: Get patient's package billing details. 
Change History
S.No.    UpdatedBy/Date                     Change History
1.		Krishna/09thJun'22					Change to performer, prescriber 
2.		Rusha/05thSept'2022					Added Municipalityname	
*/
      BEGIN
         SELECT DISTINCT
            visit.AppointmentType 'AppointmentType',
            visit.VisitType 'VisitType',
            visit.VisitCode 'VisitCode',
            visit.PerformerName 'ProviderName',
            CONVERT(VARCHAR(10), bilTxn.CreatedOn, 101) 'SaleDate',
            CONVERT(VARCHAR(9), bilTxn.CreatedOn, 108) 'SaleTime',
            CONCAT_WS(' ', pat.FirstName, pat.MiddleName, pat.LastName) 'PatientName',
            pat.PatientCode 'PatientCode',
            pat.DateOfBirth 'DateOfBirth',
            pat.Gender 'Gender',
            pat.Address 'Address',
            mun.MunicipalityName 'MunicipalityName',
            pat.PhoneNumber 'PhoneNumber',
            con.CountryName 'CountryName',
            subCounty.CountrySubDivisionName 'District',
            doc.FullName 'DoctorName',
            dep.DepartmentName 'Department',
            doc.RoomNo 'RoomNo',
            usr.UserName 'User',
            bilTxn.PackageName 'PackageName',
            bilTxn.CreatedOn 'BillingDate' 
         FROM
            BIL_TXN_BillingTransaction bilTxn 
            JOIN
               PAT_Patient pat 
               ON pat.PatientId = bilTxn.PatientId 
            JOIN
               MST_CountrySubDivision subCounty 
               ON subCounty.CountrySubDivisionId = pat.CountrySubDivisionId 
            JOIN
               MST_Country con 
               ON con.CountryId = pat.CountryId 
            LEFT JOIN
               MST_Municipality mun 
               ON mun.MunicipalityId = pat.MunicipalityId 
            JOIN
               BIL_TXN_BillingTransactionItems bilTxnItms 
               ON bilTxn.BillingTransactionId = bilTxnItms.BillingTransactionId 
            JOIN
               RBAC_User usr 
               ON usr.EmployeeId = bilTxn.CreatedBy 
            LEFT JOIN
               PAT_PatientVisits visit 
               ON bilTxn.PatientVisitId = visit.PatientVisitId 
            LEFT JOIN
               MST_Department dep 
               ON dep.DepartmentId = visit.DepartmentId 
            LEFT JOIN
               EMP_Employee doc 
               ON doc.EmployeeId = bilTxnItms.PrescriberId 
         WHERE
            bilTxn.BillingTransactionId = @BillingTransactionId 
         ORDER BY
            bilTxn.CreatedOn DESC 
      END
-- end of SP