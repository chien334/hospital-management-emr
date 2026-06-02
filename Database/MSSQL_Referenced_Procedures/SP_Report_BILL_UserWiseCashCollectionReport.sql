/*
FileName: [SP_Report_BILL_UserWiseCashCollectionReport] 
CreatedBy/date: Aniket/17-10-2021
Description: To get the Details of User Wise Cash Collection report
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1.    Aniket/17-10-2021                    created the script
*/
Create PROCEDURE [dbo].[SP_Report_BILL_UserWiseCashCollectionReport]
	@FromDate DATETIME = NULL,
	@ToDate DATETIME = NULL,
	@UserId INT = NULL
AS
BEGIN

SELECT
  ISNULL(OPD.UserName, IPD.UserName) 'UserName',
  ISNULL(OPD.SubTotal, 0) 'OP_Collection',
  ISNULL(OPD.Discount, 0) 'OP_Discount',
  ISNULL(OPD.Refund, 0) 'OP_Refund',
  ISNULL(OPD.ReturnDiscount, 0) 'OP_ReturnDiscount',
  ISNULL(OPD.NetTotal, 0) 'OP_NetTotal',
  ISNULL(IPD.SubTotal, 0) 'IP_Collection',
  ISNULL(IPD.Discount, 0) 'IP_Discount',
  ISNULL(IPD.Refund, 0) 'IP_Refund',
  ISNULL(IPD.ReturnDiscount, 0) 'IP_ReturnDiscount',
  ISNULL(IPD.NetTotal, 0) 'IP_NetTotal',
  ((ISNULL(OPD.NetTotal, 0) + ISNULL(IPD.NetTotal, 0))) + ((ISNULL(depOut.AdvanceReceived, 0) - ISNULL(depOut.AdvanceSettled, 0))) 'Grand_Total',
  ISNULL(depOut.AdvanceReceived, 0) 'DepositAmount',
  ISNULL(depOut.AdvanceSettled, 0) 'DepositReturn'

FROM (SELECT
		CASE
			WHEN UserId IS NOT NULL THEN UserName
			ELSE 'NoDoctor'
		END AS 'UserName',
		SUM(ISNULL(SubTotal, 0)) 'SubTotal',
		SUM(ISNULL(DiscountAmount, 0)) AS 'Discount',
		SUM(ISNULL(ReturnAmount, 0)) AS 'Refund',
		SUM(ISNULL(ReturnDiscount, 0)) AS 'ReturnDiscount',
		SUM(ISNULL(TotalAmount, 0) - ISNULL(ReturnAmount, 0)) AS 'NetTotal'
	FROM FN_BIL_GetTxnItemsInfoWithDateSeparationForUserCashCollectionReport(@FromDate, @ToDate)
	WHERE BillingType = 'OutPatient' AND BillStatus != 'cancelled'
		AND (ISNULL(@UserId, ISNULL(UserId, 0)) = ISNULL(UserId, 0))
	GROUP BY UserId,UserName) OPD
FULL OUTER JOIN (
	SELECT
		CASE
			WHEN UserId IS NOT NULL THEN UserName
			ELSE 'NoUser'
		END AS 'UserName',
		SUM(ISNULL(SubTotal, 0)) 'SubTotal',
		SUM(ISNULL(DiscountAmount, 0)) AS 'Discount',
		SUM(ISNULL(ReturnAmount, 0)) AS 'Refund',
		SUM(ISNULL(ReturnDiscount, 0)) AS 'ReturnDiscount',
		SUM(ISNULL(TotalAmount, 0) - ISNULL(ReturnAmount, 0)) AS 'NetTotal'
	FROM FN_BIL_GetTxnItemsInfoWithDateSeparationForUserCashCollectionReport(@FromDate, @ToDate) tbl
	WHERE BillingType = 'Inpatient' AND BillStatus != 'cancelled'
		AND (ISNULL(@UserId, ISNULL(UserId, 0)) = ISNULL(UserId, 0))
		AND (tbl.UserId = @UserId Or @UserId is null)
	GROUP BY UserId,UserName) IPD
ON OPD.UserName = IPD.UserName
LEFT JOIN 
(SELECT
        SUM(CASE WHEN DepositType = 'Deposit' THEN Amount ELSE 0 END) AS 'AdvanceReceived',
        SUM(CASE WHEN DepositType = 'depositdeduct' OR DepositType = 'ReturnDeposit' THEN Amount ELSE 0 END) AS 'AdvanceSettled',
		emp.FullName
    FROM BIL_TXN_Deposit as dep1
	join EMP_Employee as emp on dep1.CreatedBy= emp.EmployeeId
    WHERE CONVERT(date, dep1.CreatedOn) BETWEEN CONVERT(date, ISNULL(@FromDate, GETDATE())) AND CONVERT(date, ISNULL(@ToDate, GETDATE()))
	Group By FullName) as depOut on OPD.UserName = depOut.FullName
ORDER BY UserName

END