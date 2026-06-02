CREATE PROCEDURE [dbo].[SP_BIL_GetItems_ForIPBillingDischargeSummaryReceipt] 
	 @PatientId INT = NULL
	,@PatientVisitId INT = NULL
	,@DischargeStatementId INT = NULL
	,@BillStatus VARCHAR(20) = NULL
AS
/*
FileName: [SP_BIL_GetItems_ForIPBillingDischargeSummaryReceipt] 
CreatedBy/date: Rohit/1Mar'23
Description: To get the discharge summary details 
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Rohit/28Feb'23                        created the script
2		Rohit/24Apr'23						  Query mistake resolved (mistake: DiscountAmount fetched in SubTotal)
3		Krishna/27thApril'23				  Change DepositType to TransactionType and Segregate Amount to InAmount and OutAmount
4.      Bibek/27thJuly'23                     Added wardNumber and MunicipalityName columns in PatientInfo
*/
BEGIN
	SELECT pat.PatientId
		,pat.ShortName 'ShortName'
		,pat.PatientCode 'PatientCode'
		,pat.DateOfBirth
		,pat.Gender, pat.WardNumber
		,Address
		,PhoneNumber
		,patv.VisitCode
		,subdiv.CountrySubDivisionName,
		country.CountryName,
		mun.MunicipalityName
		,pat.PANNumber
		,pat.Ins_NshiNumber
		,patv.ClaimCode
		,patv.VisitCode 'InpatientNo'
	FROM PAT_Patient pat
	INNER JOIN PAT_PatientVisits patv ON pat.PatientId = patv.PatientId AND patv.PatientVisitId=@PatientVisitId
	INNER JOIN ADT_PatientAdmission adm ON patv.PatientVisitId = adm.PatientVisitId
		INNER JOIN MST_Country country ON pat.CountryId = country.CountryId
	INNER JOIN MST_CountrySubDivision subdiv ON pat.CountrySubDivisionId = subdiv.CountrySubDivisionId
	LEFT JOIN MST_Municipality mun ON subdiv.CountrySubDivisionId = mun.CountrySubDivisionId



	WHERE pat.PatientId = @PatientId
		AND patv.PatientVisitId = @PatientVisitId

	--Table:2--Bill Item Summary------------
	IF @DischargeStatementId !=0
	BEGIN
		SELECT ServiceDepartmentName
			,SubTotal
			,DiscountAmount
			,TotalAmount
		FROM (
			SELECT a.ServiceDepartmentName
				,SUM(SubTotal) 'SubTotal'
				,SUM(DiscountAmount) 'DiscountAmount'
				,SUM(TotalAmount) 'TotalAmount'
			FROM (
				SELECT ServiceDepartmentName
					,SubTotal
					,DiscountAmount 'DiscountAmount'
					,TotalAmount
				FROM BIL_TXN_BillingTransactionItems
				WHERE (
						(
							BillStatus = @BillStatus
							AND PatientId = @PatientId
							AND PatientVisitId = @PatientVisitId
							)
						OR (
							DischargeStatementId = @DischargeStatementId
							AND PatientId = @PatientId
							AND PatientVisitId = @PatientVisitId
							)
						)
				) a
			GROUP BY a.ServiceDepartmentName
			
			UNION
			
			SELECT ServiceDepartmentName
				,SUM(SubTotal) 'SubTotal'
				,SUM(DiscountAmount) 'DiscountAmount'
				,SUM(TotalAmount)
			FROM (
				SELECT 'PharmacyCharges' AS ServiceDepartmentName
					,SubTotal
					,TotalDisAmt 'DiscountAmount'
					,TotalAmount
				FROM PHRM_TXN_InvoiceItems
				WHERE DischargeStatementId = @DischargeStatementId
					AND PatientId = @PatientId
				) b
			GROUP BY ServiceDepartmentName
			) b
	END
	ELSE
	BEGIN
		SELECT ServiceDepartmentName
			,SubTotal
			,DiscountAmount
			,TotalAmount
		FROM (
			SELECT a.ServiceDepartmentName
				,SUM(SubTotal) 'SubTotal'
				,SUM(DiscountAmount) 'DiscountAmount'
				,SUM(TotalAmount) 'TotalAmount'
			FROM (
				SELECT ServiceDepartmentName
					,SubTotal
					,DiscountAmount 'DiscountAmount'
					,TotalAmount
				FROM BIL_TXN_BillingTransactionItems
				WHERE (
						(
							BillStatus = @BillStatus
							AND PatientId = @PatientId
							AND PatientVisitId = @PatientVisitId
							)
						OR (
							DischargeStatementId = @DischargeStatementId
							AND PatientId = @PatientId
							AND PatientVisitId = @PatientVisitId
							)
						)
				) a
			GROUP BY a.ServiceDepartmentName
			
			UNION
			
			SELECT ServiceDepartmentName
				,SUM(SubTotal) 'SubTotal'
				,SUM(DiscountAmount) 'DiscountAmount'
				,SUM(TotalAmount)
			FROM (
				SELECT 'PharmacyCharges' AS ServiceDepartmentName
					,SubTotal
					,TotalDisAmt 'DiscountAmount'
					,TotalAmount
				FROM PHRM_TXN_InvoiceItems
				WHERE BilItemStatus = @BillStatus AND PatientId = @PatientId
				) b
			GROUP BY ServiceDepartmentName
			) b
	END

	--Table:3 --Admission Info----
	SELECT adm.AdmissionDate
		,adm.DischargeDate
		,DepartmentName 'Department'
		,ward.WardName 'RoomType'
		,patv.PerformerName 'AdmittingDoctor'
		,adm.ProcedureType
		,DATEDIFF(day, adm.AdmissionDate, ISNULL(adm.DischargeDate, GETDate())) AS LengthOfStay
	FROM PAT_PatientVisits patv
	INNER JOIN ADT_PatientAdmission adm ON patv.PatientVisitId = adm.PatientVisitId
	INNER JOIN MST_Department mstdep ON patv.DepartmentId = mstdep.DepartmentId
	INNER JOIN ADT_TXN_PatientBedInfo admBedInfo ON adm.PatientVisitId = admBedInfo.PatientVisitId
	INNER JOIN ADT_MST_Ward ward ON admBedInfo.WardId = ward.WardID
	WHERE patv.PatientId = @PatientId
		AND patv.PatientVisitId = @PatientVisitId

	--Table:4 --Deposit Info----
	SELECT dep.DepositId
		,dep.IsActive
		,ReceiptNo
		,dep.CreatedOn 'Date'
		,dep.InAmount
		,dep.OutAmount
		,dep.DepositBalance 'Balance'
		,TransactionType
		,CASE 
			WHEN dep.SettlementId IS NOT NULL
				THEN 'SR' + dep.ReceiptNo
			ELSE NULL
			END AS ReferenceInvoice
	FROM BIL_TXN_Deposit dep
	LEFT JOIN BIL_TXN_Settlements sett ON dep.SettlementId = sett.SettlementId
	WHERE dep.PatientId = @PatientId
		AND dep.PatientVisitId = @PatientVisitId
	ORDER BY dep.CreatedOn

	--Table:5--DischargeStatement Details---
	SELECT DischargeStatementId
		,StatementDate
		,StatementNo
		,StatementTime
	FROM BIL_TXN_DischargeStatement
	WHERE DischargeStatementId = @DischargeStatementId
END