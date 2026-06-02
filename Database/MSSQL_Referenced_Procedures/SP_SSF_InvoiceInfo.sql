CREATE PROCEDURE [dbo].[SP_SSF_InvoiceInfo] 
	@FromDate DATETIME = NULL
	,@ToDate DATETIME = NULL
	,@PatientType VARCHAR(20)

AS
/*
exec SP_SSF_InvoiceInfo '2023-07-09','2023-07-09','outpatient'
FileName: SP_SSF_InvoiceInfo
--Description: This SP returns 7 tables
   --1. Patient Information
   --2. Billing-Invoice Information
   --3. Billing-InvoiceItems information
   --4. Pharmacy-Invoice Information
   --5. Pharmacy-InvoiceItems Information
   --6. Lab-Reports
   --7. Radiology-Reports 
   --8. Billing Invoice Returns
   --9. Pharmacy Invoice Returns
S.No.    UpdatedBy/Date                        Remarks
1        Dev Narayan / 21 Sept'22              Initial Draft
2        Krishna/17thNov'22                    Rename PatientVisitId to LatestPatientVisitId
3.       Krishna/18thNov'22                    Group Details according to PatientId and ClaimCode
4.       Krishna/24thNov'22                    Handle Returned Invoices and Items in SSF Invoices to claim
5.       Krishna/15thDec'22                    Fetch Invoice Items of specific priceCategory 
											   from BIL_MAP_BillCFGItemVsPriceCategory table
6.       Krishna/16thDec'22                    Handle Pharmacy return items
7.		 Krishna/27thFeb'23					   Handle Emergency Visits 
8.		 Sanjeev/5thJune'23					   Change joins from PriceCategory to Scheme, Change BalanceAmount 
											   to NetReceivableAmount
                                               (Integration of SSF in Claim Management)
9.	    Krishna/2ndOct'23						Make it compatible with multiple Schemes of SSF
10.		Krishna/8thOct'23				        Filter Non Claimed Invoices only to display in claim Page
11.     Krishna/6thNov'23						Rename InvoiceNo to InvoiceNumber for Pharmacy Invoice
12.	    Krishna/6thNov'23						Read Billing and Pharmacy Invoice Returns
*/
BEGIN
Declare @SSFSchemeIdsCSV  VARCHAR(200) = (select STRING_AGG(CAST(SchemeId AS VARCHAR(200)), ',') 
							from BIL_CFG_Scheme where ApiIntegrationName = 'SSF')

    DECLARE @BillTxnIdsCSV NVARCHAR(MAX)

    SET @BillTxnIdsCSV = (
            SELECT STRING_AGG(CAST(BillingTransactionId AS NVARCHAR(MAX)), ',')
            FROM BIL_TXN_BillingTransaction
            WHERE BillingTransactionId IN (
                    SELECT DISTINCT txn.BillingTransactionId
                    FROM BIL_TXN_BillingTransaction txn
                    JOIN BIL_TXN_CreditBillStatus creditStatus ON txn.BillingTransactionId = creditStatus.BillingTransactionId
                    JOIN BIL_TXN_BillingTransactionItems txnItem ON txn.BillingTransactionId = txnItem.BillingTransactionId
                    LEFT JOIN PAT_SSFClaimResponseDetails response ON txn.ClaimCode = response.ClaimCode
					INNER JOIN (SELECT value AS 'SchemeId' FROM string_split(@SSFSchemeIdsCSV,',')) schemeIds 
								ON txn.SchemeId = schemeIds.SchemeId
                    WHERE  convert(DATE, txn.CreatedOn) BETWEEN @FromDate
                            AND @ToDate
					AND ISNULL(response.ResponseStatus, 0) = 0
                    ) AND TransactionType = @PatientType
            )
    DECLARE @InvIdsCSV VARCHAR(MAX)

    SET @InvIdsCSV = (
            SELECT STRING_AGG(CAST(InvoiceId AS VARCHAR(MAX)), ',')
            FROM (
                SELECT InvoiceId
                FROM PHRM_TXN_Invoice
                WHERE ClaimCode NOT IN (
                        SELECT ClaimCode
                        FROM PAT_SSFClaimResponseDetails
                        WHERE ResponseStatus = 1
                        ) AND convert(DATE, CreateOn) BETWEEN @FromDate
                        AND @ToDate AND VisitType = @PatientType
                ) tbl
            )

    --DECLARE @SSFPriceCategoryId INT = (
    --        SELECT PriceCategoryId
    --        FROM BIL_CFG_PriceCategory
    --        WHERE PriceCategoryName = 'SSF'
    --        )

    SELECT visit.ClaimCode
        ,pat.PatientId
        ,pat.PatientCode
        ,visit.PatientVisitId
        ,ShortName
        ,Gender
        ,DateOfBirth
        ,Age
        ,pat.CountryId
        ,cont.CountryName
        ,pat.CountrySubDivisionId
		,ISNULL(pat.WardNumber, 0) 'WardNumber'
        ,dist.CountrySubDivisionName
        ,CONCAT (
            dist.CountrySubDivisionName
            ,pat.Address
            ,munc.MunicipalityName
            ) AS Address
        ,munc.MunicipalityName
		,dept.DepartmentName
        ,pat.PhoneNumber
        ,visit.SchemeId
		,visit.DepartmentId
        ,scheme.SchemeName
        ,PANNumber
        ,PatientNameLocal
        ,Ins_NshiNumber
        ,map.PolicyNo
        ,map.PolicyHolderEmployerId
        ,CASE 
            WHEN map.RegistrationCase = 'Accident'
                THEN 1
            ELSE 2
            END AS 'SchemeType'
        ,disSummary.Diagnosis
        ,CASE 
            WHEN (admission.AdmissionStatus = 'admitted' OR admission.AdmissionStatus = 'discharged')
                THEN '1'
            ELSE '0'
            END AS 'Admitted'
        ,CONVERT(DATE, admission.AdmissionDate) AS 'AdmissionDate'
        ,CONVERT(DATE, admission.DischargeDate) AS 'DischargeDate'
        ,map.PolicyHolderUID
        ,disSummary.CaseSummary
        ,dtype.DischargeTypeName
        ,CASE 
            WHEN disSummary.DeathTypeId IS NULL
                THEN 0
            ELSE 1
            END AS 'IsDead'
        ,visit.CreatedOn 'VisitCreationDate'
        ,CASE WHEN visit.VisitType = 'inpatient' THEN 'inpatient' ELSE 'outpatient' END AS 'VisitType'
    FROM PAT_Patient pat WITH (NOLOCK)
    INNER JOIN MST_CountrySubDivision dist ON pat.CountrySubDivisionId = dist.CountrySubDivisionId
    INNER JOIN MST_Country cont ON dist.CountryId = cont.CountryId
    
    INNER JOIN (
        SELECT *
        FROM (
            SELECT ROW_NUMBER() OVER (
                    PARTITION BY InnerData.ClaimCode ORDER BY InnerData.PatientVisitId DESC
                    ) AS RowNum
                ,InnerData.PatientId
                ,InnerData.PatientVisitId
                ,InnerData.VisitType
                ,InnerData.CreatedOn
                ,InnerData.ClaimCode
                ,InnerData.SchemeId,
				InnerData.DepartmentId
            FROM PAT_PatientVisits InnerData
            WHERE CASE 
                    WHEN InnerData.VisitType = 'inpatient'
                        THEN 'inpatient'
                    ELSE 'outpatient'
                    END = @PatientType AND CONVERT(DATE, InnerData.CreatedOn) BETWEEN @FromDate
                    AND @ToDate
            ) tbl
        WHERE tbl.RowNum = 1
        ) visit ON pat.PatientId = visit.PatientId
    INNER JOIN PAT_MAP_PatientSchemes map ON map.PatientId = visit.PatientId AND map.SchemeId = visit.SchemeId --this is done as we have unique combination of patientId and PriceCategoryId in PAT_MAP_PriceCategory table
        --map.LatestPatientVisitId = visit.PatientVisitId 
	INNER JOIN MST_Department dept ON dept.DepartmentId = visit.DepartmentId
	INNER JOIN BIL_CFG_Scheme scheme ON scheme.SchemeId = visit.SchemeId
    LEFT JOIN MST_Municipality munc ON pat.MunicipalityId = munc.MunicipalityId
    LEFT JOIN ADT_PatientAdmission admission ON admission.PatientId = pat.PatientId AND admission.PatientVisitId = visit.PatientVisitId
    LEFT JOIN ADT_DischargeSummary disSummary ON disSummary.PatientVisitId = visit.PatientVisitId
    LEFT JOIN ADT_DischargeType dtype ON dtype.DischargeTypeId = disSummary.DischargeTypeId
    WHERE pat.PatientId IN (
            (SELECT PatientId FROM BIL_TXN_BillingTransaction
                        WHERE BillingTransactionId IN (SELECT VALUE FROM STRING_SPLIT(@BillTxnIdsCSV, ',')))
            UNION ALL 
            (SELECT PatientId FROM PHRM_TXN_Invoice
                        WHERE InvoiceId IN (SELECT VALUE FROM STRING_SPLIT(@InvIdsCSV, ','))))
            AND CASE 
            WHEN VisitType = 'inpatient'
                THEN 'inpatient'
            ELSE 'outpatient'
            END = @PatientType AND CONVERT(DATE, visit.CreatedOn) BETWEEN @FromDate
            AND @ToDate

    --Table:2--Invoice Information-----
    SELECT *
    FROM (
        SELECT txn.InvoiceNo 'InvoiceNumber'
            ,txn.InvoiceCode
            ,txn.InvoiceCode + Convert(VARCHAR(20), txn.InvoiceNo) AS 'InvoiceNumFormatted'
            ,txn.CreatedOn 'TransactionDate'
            ,txn.FiscalYearId
            ,txn.PaymentMode
            ,txn.PaymentDetails
            ,txn.BillStatus
            ,txn.TransactionType
            ,txn.InvoiceType
            ,ISNULL(txn.PrintCount, 0) 'PrintCount'
            ,--txn.SubTotal - 
            tbl3.TotalSubTotal 'SubTotal'
            ,txn.DiscountAmount
            ,txn.TaxableAmount
            ,txn.NonTaxableAmount
            ,--txn.TotalAmount - 
            tbl3.TotalAmount 'TotalAmount'
            ,txn.BillingTransactionId
            ,txn.PaidDate AS 'PaidDate'
            ,txn.Tender
            ,txn.Change
            ,txn.Remarks
            ,ISNULL(txn.IsInsuranceBilling, 0) AS 'IsInsuranceBilling'
            ,txn.ClaimCode
            ,txn.OrganizationId 'CrOrganizationId'
            ,crOrg.OrganizationName 'CrOrganizationName'
            ,usr.UserName
            ,cntr.CounterId
            ,cntr.CounterName
            ,txn.LabTypeName
            ,txn.PackageId
            ,pkg.BillingPackageName AS 'PackageName'
            ,ISNULL(txn.DepositAvailable, 0) AS 'DepositAvailable'
            ,ISNULL(txn.DepositUsed, 0) AS 'DepositUsed'
            ,ISNULL(txn.DepositReturnAmount, 0) AS 'DepositReturnAmount'
            ,ISNULL(txn.DepositBalance, 0) AS 'DepositBalance'
            ,(tbl3.TotalAmount - ISNULL(creditStatus.NetReceivableAmount,0)) AS 'ReceivedAmount' --txn.ReceivedAmount
            ,creditStatus.NetReceivableAmount
            ,txn.PatientId
            ,CONVERT(DATE, txn.CreatedOn) AS 'InvoiceDate'
            ,tbl3.Quantity AS 'Quantity'
        FROM BIL_TXN_BillingTransaction txn WITH (NOLOCK)
        LEFT JOIN (
            SELECT tbl2.BillingTransactionId
                ,SUM(ISNULL(TotalQuantity, 0)) 'Quantity'
                ,SUM(ISNULL(TotalSubTotal, 0)) 'TotalSubTotal'
                ,SUM(ISNULL(TotalAmount, 0)) 'TotalAmount'
            FROM (
                SELECT itms.BillingTransactionId
                    ,itms.BillingTransactionItemId
                    ,SUM(ISNULL(itms.Quantity, 0)) - SUM(ISNULL(tbl1.ReturnQuantity, 0)) 'TotalQuantity'
                    ,SUM(ISNULL(itms.SubTotal, 0)) - SUM(ISNULL(tbl1.RetSubTotal, 0)) 'TotalSubTotal'
                    ,SUM(ISNULL(itms.TotalAmount, 0)) - SUM(ISNULL(tbl1.RetTotal, 0)) 'TotalAmount'
                FROM (
                    SELECT BillingTransactionItemId
                        ,SUM(ISNULL(RetQuantity, 0)) 'ReturnQuantity'
                        ,SUM(ISNULL(RetSubTotal, 0)) 'RetSubTotal'
                        ,SUM(ISNULL(RetTotalAmount, 0)) 'RetTotal'
                    FROM BIL_TXN_InvoiceReturnItems
                    WHERE CONVERT(DATE, CreatedOn) BETWEEN @FromDate
                            AND @ToDate
                    GROUP BY BillingTransactionItemId
                    ) tbl1
                RIGHT JOIN BIL_TXN_BillingTransactionItems itms ON tbl1.BillingTransactionItemId = itms.BillingTransactionItemId
                WHERE CONVERT(DATE, itms.CreatedOn) BETWEEN @FromDate
                        AND @ToDate
                GROUP BY itms.BillingTransactionItemId
                    ,itms.BillingTransactionId
                ) tbl2
            GROUP BY tbl2.BillingTransactionId
            HAVING SUM(ISNULL(TotalQuantity, 0)) > 0
            ) tbl3 ON tbl3.BillingTransactionId = txn.BillingTransactionId
        LEFT JOIN BIL_TXN_CreditBillStatus creditStatus ON txn.BillingTransactionId = creditStatus.BillingTransactionId
        INNER JOIN RBAC_User usr ON txn.CreatedBy = usr.EmployeeId
        INNER JOIN BIL_CFG_Counter cntr ON txn.CounterId = cntr.CounterId
        LEFT JOIN BIL_MST_Credit_Organization crOrg ON txn.OrganizationId = crOrg.OrganizationId
        LEFT JOIN BIL_CFG_Packages pkg ON txn.PackageId = pkg.BillingPackageId
        WHERE txn.BillingTransactionId IN (
                SELECT VALUE
                FROM STRING_SPLIT(@BillTxnIdsCSV, ',')
                )
        ) tbl
    WHERE tbl.Quantity > 0

    --Table:3--InvoiceItems Information-----
    SELECT *
    FROM (
        SELECT item.BillingTransactionItemId
			,item.IsCopayment
			,item.DiscountPercent
			,item.ItemCode
            ,item.PatientId
            ,item.ServiceDepartmentId
            ,item.ItemId
            ,ServiceDepartmentName
            ,ItemName
            ,item.Price
            ,ISNULL(Quantity, 0) - ISNULL(ret.RetQuantity, 0) AS 'Quantity'
            ,ISNULL(SubTotal, 0) - ISNULL(ret.RetSubTotal, 0) AS 'SubTotal'
            ,DiscountAmount
            ,ISNULL(TotalAmount, 0) - ISNULL(ret.RetTotal, 0) AS 'TotalAmount'
            ,PerformerId
            ,PerformerName
            ,item.PrescriberId
            ,CASE 
                WHEN item.PrescriberId IS NULL
                    THEN ''
                ELSE emp.FullName
                END AS RequestedByName
            ,item.PriceCategory
            ,BillingTransactionId
            ,map.ItemLegalName
            ,map.ItemLegalCode AS 'ServiceCode'
        FROM BIL_TXN_BillingTransactionItems item WITH (NOLOCK)
        LEFT JOIN (
            SELECT BillingTransactionItemId
                ,SUM(ISNULL(RetQuantity, 0)) 'RetQuantity'
                ,SUM(ISNULL(RetSubTotal, 0)) 'RetSubTotal'
                ,SUM(ISNULL(RetTotalAmount, 0)) 'RetTotal'
            FROM BIL_TXN_InvoiceReturnItems
            GROUP BY BillingTransactionItemId
            ) ret ON item.BillingTransactionItemId = ret.BillingTransactionItemId
        LEFT JOIN EMP_Employee emp ON item.PrescriberId = emp.EmployeeId
        INNER JOIN BIL_CFG_PriceCategory cat ON cat.PriceCategoryId = item.PriceCategoryId
        LEFT JOIN BIL_MAP_PriceCategoryServiceItem map ON item.ServiceItemId = map.ServiceItemId AND item.ServiceDepartmentId = map.ServiceDepartmentId AND map.PriceCategoryId = cat.PriceCategoryId
        WHERE BillingTransactionId IN (
                SELECT VALUE
                FROM STRING_SPLIT(@BillTxnIdsCSV, ',')
                )
        ) tbl
    WHERE tbl.Quantity > 0


    --Need to handle Returns properly
    SELECT * FROM (
    SELECT 
        inv.InvoicePrintId as 'InvoiceNumber',
        'PH' + Convert(VARCHAR(20), inv.InvoicePrintId) AS 'InvoiceNumFormatted',
        (inv.TotalAmount - ISNULL(retInv.RetTotalAmount,0)) AS 'TotalAmount',
        (inv.TotalAmount - ISNULL(creditStatus.NetReceivableAmount,0)) AS 'ReceivedAmount',
        creditStatus.NetReceivableAmount,
        inv.ClaimCode,
        inv.PatientId,
        inv.InvoiceId,
        inv.CreateOn AS 'InvoiceDate'
    FROM PHRM_TXN_Invoice inv
    LEFT JOIN (
        SELECT SUM(ISNULL(TotalAmount,0)) 'RetTotalAmount'
            ,InvoiceId
        FROM PHRM_TXN_InvoiceReturn
        GROUP BY InvoiceId
        ) retInv ON retInv.InvoiceId = inv.InvoiceId
    JOIN PHRM_TXN_CreditBillStatus creditStatus ON creditStatus.InvoiceId = inv.InvoiceId
    JOIN PAT_PatientVisits visit ON visit.PatientVisitId = inv.PatientVisitId
	JOIN BIL_CFG_Scheme scheme on scheme.SchemeId = visit.SchemeId
	INNER JOIN (SELECT value AS 'SchemeId' FROM string_split(@SSFSchemeIdsCSV,',')) schemeIds 
								ON scheme.SchemeId = schemeIds.SchemeId
    --JOIN BIL_CFG_PriceCategory priceCat ON visit.PriceCategoryId = priceCat.PriceCategoryId
    WHERE --scheme.SchemeId IN (@SSFSchemeIdsCSV) AND 
	convert(DATE, inv.CreateOn) BETWEEN @FromDate
            AND @ToDate AND inv.VisitType = @PatientType AND inv.InvoiceId IN (
            SELECT VALUE
            FROM STRING_SPLIT(@InvIdsCSV, ',')
            )
        )tbl where tbl.NetReceivableAmount > 0

    --Table:5--PHRM InvoiceItems Information-----
    SELECT SalePrice AS 'UnitPrice'
        ,'ADJ02' AS 'ServiceCode'
        ,invItms.PatientId AS 'PatientId'
        ,ISNULL(Quantity, 0) - ISNULL(retItms.RetQty, 0) 'Quantity'
        ,inv.ClaimCode 'ClaimCode'
        ,inv.InvoiceId
		,invItms.ItemName
    FROM PHRM_TXN_Invoice inv
    JOIN PHRM_TXN_InvoiceItems invItms ON inv.InvoiceId = invItms.InvoiceId
    LEFT JOIN (
        SELECT SUM(ISNULL(ReturnedQty, 0)) 'RetQty'
            ,InvoiceItemId
        FROM PHRM_TXN_InvoiceReturnItems
        GROUP BY InvoiceItemId
        ) retItms ON retItms.InvoiceItemId = invItms.InvoiceItemId
		JOIN BIL_CFG_Scheme scheme on scheme.SchemeId = inv.SchemeId
		INNER JOIN (SELECT value AS 'SchemeId' FROM string_split(@SSFSchemeIdsCSV,',')) schemeIds 
								ON scheme.SchemeId = schemeIds.SchemeId
    --JOIN BIL_CFG_PriceCategory priceCat ON invItms.PriceCategoryId = priceCat.PriceCategoryId
    WHERE --scheme.SchemeId IN (@SSFSchemeIdsCSV) AND 
	convert(DATE, inv.CreateOn) BETWEEN @FromDate
            AND @ToDate AND inv.VisitType = @PatientType AND inv.InvoiceId IN (
            SELECT VALUE
            FROM STRING_SPLIT(@InvIdsCSV, ',')
            )

    --Table: 6 -- LAB Reports--------------------
    SELECT req.PatientId
        ,STRING_AGG(req.RequisitionId, ',') AS 'RequisitionIdCSV'
        ,txn.ClaimCode
    FROM BIL_TXN_BillingTransaction txn
    JOIN BIL_TXN_BillingTransactionItems billItem ON txn.BillingTransactionId = billItem.BillingTransactionId
    JOIN LAB_TestRequisition req ON billItem.ServiceItemId = req.ServiceItemId 
	AND billItem.BillingTransactionItemId = req.BillingTransactionItemId
	AND billItem.PatientVisitId = req.PatientVisitId
    WHERE txn.BillingTransactionId IN (
            SELECT VALUE
            FROM STRING_SPLIT(@BillTxnIdsCSV, ',')
            ) AND ServiceDepartmentId IN (
            SELECT ServiceDepartmentId
            FROM BIL_MST_ServiceDepartment
            WHERE IntegrationName = 'LAB'
            )
			AND req.LabReportId IS NOT NULL
			AND req.OrderStatus = 'report-generated'
    GROUP BY req.PatientId
        ,req.LabReportId
        ,txn.ClaimCode

    --Table: 7 -- Radiology Reports--------------------
    SELECT req.PatientId
        ,req.ImagingRequisitionId AS 'RequisitionIdCSV'
        ,txn.ClaimCode
    FROM BIL_TXN_BillingTransaction txn
    JOIN BIL_TXN_BillingTransactionItems billItem ON txn.BillingTransactionId = billItem.BillingTransactionId
    JOIN RAD_PatientImagingRequisition req ON billItem.ServiceItemId = req.ServiceItemId
	AND billItem.BillingTransactionItemId = req.BillingTransactionItemId
	AND billItem.PatientVisitId = req.PatientVisitId
    WHERE txn.BillingTransactionId IN (
            SELECT VALUE
            FROM STRING_SPLIT(@BillTxnIdsCSV, ',')
            ) AND ServiceDepartmentId IN (
            SELECT ServiceDepartmentId
            FROM BIL_MST_ServiceDepartment
            WHERE IntegrationName = 'Radiology'
            ) 
			AND req.IsReportSaved = 1
    GROUP BY req.PatientId
    ,req.ImagingRequisitionId
    ,txn.ClaimCode

	--Table 8: BillingInvoiceReturns
	SELECT 
		ret.BillReturnId AS 'ReturnId',
		ret.CreditNoteNumber AS 'CreditNoteNumber',
		CONCAT('CRN', CONVERT(VARCHAR(20), ret.CreditNoteNumber)) AS 'CreditNoteNumberFormatted',
		ret.TotalAmount,
		txn.ClaimCode,
		ret.PatientId,
		'Billing' AS 'ModuleName'
	FROM BIL_TXN_BillingTransaction txn 
		INNER JOIN (SELECT VALUE FROM STRING_SPLIT(@BillTxnIdsCSV, ',')) innerTxn ON txn.BillingTransactionId = innerTxn.value
		INNER JOIN BIL_TXN_InvoiceReturn  ret ON txn.BillingTransactionId = ret.BillingTransactionId

	--Table 9: PharmacyInvoiceReturns
	SELECT 
		ret.InvoiceReturnId AS 'ReturnId',
		ret.CreditNoteID AS 'CreditNoteNumber',
		CONCAT('CR-PH', CONVERT(VARCHAR(20), ret.CreditNoteID)) AS 'CreditNoteNumberFormatted',
		ret.TotalAmount,
		txn.ClaimCode,
		ret.PatientId,
		'Pharmacy' AS 'ModuleName'
	FROM PHRM_TXN_Invoice txn 
		INNER JOIN (SELECT VALUE FROM STRING_SPLIT(@InvIdsCSV, ',')) innerTxn ON txn.InvoiceId = innerTxn.value
		INNER JOIN PHRM_TXN_InvoiceReturn  ret ON txn.InvoiceId = ret.InvoiceReturnId
END