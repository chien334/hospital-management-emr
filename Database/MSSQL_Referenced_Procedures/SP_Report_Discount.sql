CREATE PROCEDURE [dbo].[SP_Report_Discount] -- [dbo].[SP_Report_Discount] '2022-04-01','2022-04-19',null,null
		@FromDate Datetime=null ,
		@ToDate DateTime=null,
		@CounterId int=null,
		@CreatedBy int=null
AS
/*
FileName: [[SP_Report_Discount]]
CreatedBy/date: Dinesh/2018-07-05
Description: to get the Discount Report for the hospital
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Dinesh/2018-07-05					Created the Script
2		Krishna/2022-07-21					Modified the SP with new Query
3		Krishna/2022-04-08					Modified the SP in created by and counter id
4		Sanjeev/2023-08-28					Add SchemeName in select query
5		Krishna/24thSept'23					Read TransactionType as VisitType
6		Krishna/10thOct'23					Read PhoneNumber and Address
7		Krishna/16thOct'23					Read DischargeDate for inpatient invoices
8		Krishna/7thNov'23					Read Age and Gender
*/
BEGIN
IF @CounterId = 0
			BEGIN
			SET @CounterId = null;
		END
	IF (@FromDate IS NOT NULL) OR (@ToDate IS NOT NULL) 
		BEGIN
					
			select 
				txn.CreatedOn 'Date',
				'N/A' AS 'ReferenceReceipt',
				CONCAT(txn.InvoiceCode,CONVERT(VARCHAR(20),InvoiceNo)) 'ReceiptNo',
				pat.PatientCode 'HospitalNumber',
				pat.ShortName 'PatientName',
				SubTotal 'SubTotal',
				DiscountAmount 'DiscountAmount',
				TotalAmount 'TotalAmount',
				emp.FullName 'User',
				txn.Remarks 'Remarks',
				cntr.CounterName 'CounterName',
				scheme.SchemeName 'SchemeName',
				txn.TransactionType AS 'VisitType',
				pat.PhoneNumber AS 'Contact',
				ISNULL(pat.Address,'') + ISNULL(', '+ mun.MunicipalityName,'') + ISNULL(', '+ country.CountrySubDivisionName,'') as 'Address',
				IIF(ISNULL(CONVERT (VARCHAR(20), CONVERT(DATE,adm.DischargeDate)),'') = '','',CONVERT (VARCHAR(20),CONVERT(DATE,adm.DischargeDate)))  AS 'DischargeDate',
				CONCAT(CONVERT(VARCHAR(10), DATEDIFF(YEAR, pat.DateOfBirth, GETDATE())), 'Y') AS 'Age',
				pat.Gender AS 'Gender'
			from BIL_TXN_BillingTransaction txn
				LEFT JOIN ADT_PatientAdmission adm ON txn.PatientVisitId = adm.PatientVisitId
				INNER JOIN PAT_Patient pat on pat.PatientId = txn.PatientId
				LEFT JOIN MST_Municipality mun ON pat.MunicipalityId = mun.MunicipalityId
				INNER JOIN MST_CountrySubDivision country ON pat.CountrySubDivisionId = country.CountrySubDivisionId
				INNER JOIN EMP_Employee emp on emp.EmployeeId = txn.CreatedBy
				INNER JOIN BIL_CFG_Counter cntr on cntr.CounterId = txn.CounterId
				INNER JOIN BIL_CFG_Scheme scheme on txn.SchemeId = scheme.SchemeId
			WHERE ISNULL(DiscountAmount,0) > 0
				AND CONVERT(DATE, txn.CreatedOn) Between CONVERT(DATE,@FromDate) AND CONVERT(DATE,@ToDate) 
				AND txn.CounterId = ISNULL(@CounterId, txn.CounterId) AND txn.CreatedBy = ISNULL(@CreatedBy, txn.CreatedBy)

			UNION
			(
				select 
				ret.CreatedOn 'Date',
				'BL-'+CONVERT(VARCHAR(20),ret.RefInvoiceNum) 'ReferenceReceipt',
				'CR-'+CONVERT(VARCHAR(20),ret.CreditNoteNumber) 'ReceiptNo',
				pat.PatientCode 'HospitalNumber',
				pat.ShortName 'PatientName',
				tbl.SubTotal,
				tbl.DiscountAmount,
				tbl.TotalAmount,
				emp.FullName 'User',
				ret.Remarks 'Remarks',
				cntr.CounterName 'CounterName',
				tbl.SchemeName,
				tbl.BillingType AS 'VisitType',
				pat.PhoneNumber AS 'Contact',
				ISNULL(pat.Address,'') + ISNULL(', '+ mun.MunicipalityName,'') + ISNULL(', '+ country.CountrySubDivisionName,'') as 'Address',
				'' AS 'DischargeDate',
				CONCAT(CONVERT(VARCHAR(10), DATEDIFF(YEAR, pat.DateOfBirth, GETDATE())), 'Y') AS 'Age',
				pat.Gender AS 'Gender'
			from BIL_TXN_InvoiceReturn ret
			INNER JOIN (
					select 
							SUM(ISNULL(retItems.RetSubTotal,0)) 'SubTotal',
							SUM(ISNULL(retItems.RetDiscountAmount,0))'DiscountAmount',
							SUM(ISNULL(retItems.RetTotalAmount,0)) 'TotalAmount',
							retItems.BillReturnId,
							retItems.BillingType,
							scheme.SchemeName
					from BIL_TXN_InvoiceReturnItems retItems
					inner join BIL_CFG_Scheme scheme on retItems.DiscountSchemeId = scheme.SchemeId
					where CONVERT(DATE, retItems.CreatedOn) Between CONVERT(DATE,@FromDate) AND CONVERT(DATE,@ToDate) 
			AND retItems.RetCounterId = ISNULL(@CounterId, retItems.RetCounterId) AND retItems.CreatedBy = ISNULL(@CreatedBy, retItems.CreatedBy)
				group by retItems.BillingTransactionId, retItems.BillReturnId, scheme.SchemeName, retItems.BillingType)tbl
				on tbl.BillReturnId = ret.BillReturnId
				inner join PAT_Patient pat
				LEFT join MST_Municipality mun ON pat.MunicipalityId = mun.MunicipalityId
				inner join MST_CountrySubDivision country ON pat.CountrySubDivisionId = country.CountrySubDivisionId
				on pat.PatientId = ret.PatientId
				inner join EMP_Employee emp
				on emp.EmployeeId = ret.CreatedBy
				inner join BIL_CFG_Counter cntr
				on cntr.CounterId = ret.CounterId
			where ISNULL(tbl.DiscountAmount,0) > 0
				AND CONVERT(DATE, ret.CreatedOn) Between CONVERT(DATE,@FromDate) AND CONVERT(DATE,@ToDate) 
				AND ret.CounterId = ISNULL(@CounterId, ret.CounterId) AND ret.CreatedBy = ISNULL(@CreatedBy, ret.CreatedBy)
			)
		END
END