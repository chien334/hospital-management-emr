CREATE PROCEDURE [dbo].[SP_Report_APF_BillDetailReport] 
	 @FromDate DATE = NULL
	,@ToDate DATE = NULL
	,@billingType VARCHAR(20)=NULL
	,@ItemId INT = NULL
	,@UserId INT = NULL
	,@Rank VARCHAR(20)=NULL
	,@MembershipTypeId INT =NULL
	,@ServiceDepartmentId INT = NULL
AS
/*  
FileName: [SP_Report_APF_BillDetailReport]  
CreatedBy/date: Rohit/28Sept'22  
Description: To get details of sales and returnsales at item level  
Remarks:      
Change History  
S.No.    UpdatedBy/Date               Remarks  
1.       Rohit/28Sept'22             Created Initial Script  
*/
BEGIN
	DECLARE @IsInsurance BIT;

	IF (LOWER(@billingType) = 'insurance')
	BEGIN
		SET @IsInsurance = 1;
	END
	ELSE IF (LOWER(@billingType) = 'normal')
	BEGIN
		SET @IsInsurance = 0;
	END
	ELSE IF (LOWER(@billingType) = 'all')
	BEGIN
		SET @IsInsurance = NULL;
	END

	SELECT *
	FROM (
		SELECT Convert(DATE, txn.CreatedOn) 'TransactionDate'
			,txn.InvoiceCode + '-' + Convert(VARCHAR(20), txn.InvoiceNo) 'ReceiptNo'
			,CASE 
				WHEN txn.PaymentMode = 'credit'
					THEN 'CreditSales'
				ELSE 'CashSales'
				END AS BillingType
			,txnItm.VisitType 'VisitType'
			,p.PatientCode 'HospitalNumber'
			,p.ShortName 'PatientName'
			,srv.ServiceDepartmentName
			,txnItm.ItemName
			,p.Rank
			,ISNULL(memb.MembershipTypeName, 'General') 'MembershipType'
			,txnItm.Price
			,txnItm.Quantity
			,txnItm.SubTotal 'SubTotal'
			,txnItm.DiscountAmount 'DiscountAmount'
			,txnItm.TotalAmount 'TotalAmount'
			,txnItm.PerformerId
			,txnItm.PrescriberId
			,CASE 
				WHEN ISNULL(txnItm.PerformerId, 0) = 0
					THEN 'Unassigned'
				ELSE empAssign.FullName
				END AS Performer
			,CASE 
				WHEN ISNULL(txnItm.PrescriberId, 0) = 0
					THEN 'SELF'
				ELSE empRef.FullName
				END AS PrescriberName
			,txnItm.Remarks 'Remarks'
			,'NA' AS 'ReferenceReceiptNo'
			,empUsr.FullName AS 'UserName'  
		FROM BIL_TXN_BillingTransaction txn
		INNER JOIN BIL_TXN_BillingTransactionItems txnItm ON txn.BillingTransactionId = txnItm.BillingTransactionId
		INNER JOIN BIL_MST_ServiceDepartment srv ON txnItm.ServiceDepartmentId = srv.ServiceDepartmentId
		INNER JOIN PAT_Patient P ON txn.PatientId = p.PatientId
		INNER JOIN EMP_Employee empUsr ON empUsr.EmployeeId = txn.CreatedBy
		LEFT JOIN EMP_Employee empRef ON empRef.EmployeeId = txnItm.PrescriberId
		LEFT JOIN EMP_Employee empAssign ON empAssign.EmployeeId = txnItm.PerformerId
		LEFT JOIN PAT_CFG_MembershipType memb ON txnItm.DiscountSchemeId = memb.MembershipTypeId
		WHERE Convert(DATE, txn.CreatedOn) BETWEEN @FromDate AND @ToDate
			AND (txn.IsInsuranceBilling=@IsInsurance OR @IsInsurance IS NULL)
			AND (txnItm.ItemId=@ItemId OR @ItemId IS NULL)
			AND (empUsr.EmployeeId=@UserId OR @UserId IS NULL)
			AND (P.Rank=@Rank OR @Rank IS NULL)
			AND (memb.MembershipTypeId =@MembershipTypeId OR @MembershipTypeId IS NULL)
			AND (srv.ServiceDepartmentId=@ServiceDepartmentId OR @ServiceDepartmentId IS NULL)
		
		UNION ALL
		
		SELECT Convert(DATE, ret.CreatedOn) 'TransactionDate'
			,'CRN-' + Convert(VARCHAR(20), ret.CreditNoteNumber) 'CreditNoteNumber'
			,CASE 
				WHEN ret.PaymentMode = 'credit'
					THEN 'ReturnCreditSales'
				ELSE 'ReturnCashSales'
				END AS BillingType
			,retItm.VisitType 'VisitType'
			,p.PatientCode 'HospitalNumber'
			,p.ShortName 'PatientName'
			,srv.ServiceDepartmentName
			,retItm.ItemName
			,p.Rank
			,ISNULL(memb.MembershipTypeName, 'General') 'MembershipType'
			,retItm.Price
			,retItm.RetQuantity
			,retItm.RetSubTotal 'SubTotal'
			,retItm.RetDiscountAmount 'DiscountAmount'
			,retItm.RetTotalAmount 'TotalAmount'
			,retItm.PerformerId
			,retItm.PrescriberId
			,CASE 
				WHEN ISNULL(retItm.PerformerId, 0) = 0
					THEN 'Unassigned'
				ELSE empAssign.FullName
				END AS Performer
			,CASE 
				WHEN ISNULL(retItm.PrescriberId, 0) = 0
					THEN 'SELF'
				ELSE empRef.FullName
				END AS PrescriberName
			,retItm.RetRemarks 'Remarks'
			,ret.InvoiceCode + '-' + Convert(VARCHAR(20), ret.RefInvoiceNum) AS 'ReferenceReceiptNo'
			,empUsr.FullName AS 'UserName' 
		FROM BIL_TXN_InvoiceReturn ret
		INNER JOIN BIL_TXN_InvoiceReturnItems retItm ON ret.BillReturnId = retItm.BillReturnId
		INNER JOIN BIL_MST_ServiceDepartment srv ON retItm.ServiceDepartmentId = srv.ServiceDepartmentId
		INNER JOIN PAT_Patient P ON ret.PatientId = p.PatientId
		INNER JOIN EMP_Employee empUsr ON empUsr.EmployeeId = ret.CreatedBy
		LEFT JOIN EMP_Employee empRef ON empRef.EmployeeId = retItm.PrescriberId
		LEFT JOIN EMP_Employee empAssign ON empAssign.EmployeeId = retItm.PerformerId
		LEFT JOIN PAT_CFG_MembershipType memb ON retItm.DiscountSchemeId = memb.MembershipTypeId
		WHERE Convert(DATE, ret.CreatedOn) BETWEEN @FromDate AND @Todate
			AND (ret.IsInsuranceBilling=@IsInsurance OR @IsInsurance IS NULL)
			AND (retItm.ItemId=@ItemId OR @ItemId IS NULL)
			AND (empUsr.EmployeeId=@UserId OR @UserId IS NULL)
			AND (P.Rank=@Rank OR @Rank IS NULL)
			AND (memb.MembershipTypeId =@MembershipTypeId OR @MembershipTypeId IS NULL)
			AND (srv.ServiceDepartmentId=@ServiceDepartmentId OR @ServiceDepartmentId IS NULL)
		) itmDetails
	ORDER BY TransactionDate
END