CREATE PROCEDURE [dbo].[SP_Report_INCTV_Doc_ItemGroupSummary]  --EXEC SP_Report_INCTV_Doc_ItemGroupSummary '2020-03-01','2020-03-17',112
	@FromDate date = NULL,
    @ToDate date = NULL,
    @EmployeeId int = NULL,
	@IsRefferalOnly BIT = 0
AS

/*
Author: 18Mar'20/Pratik 
Description: To get incentive report group by Items for Selected Doctor between selected range.
Change History
S.No.   Date/Author							Remarks
1.     18Mar'20/Pratik						Initial Draft
2.     6June'21/Pratik						Correcting Total Qty of Incentive Fraction Item
3.     23Aug'22/Dev Narayan					Added filter IncentiveType = 'referral' for new Report ->
											'Incentive Referral Summary'
*/

BEGIN
	
SELECT ItemName,
	--Count(*) 'TotalQty_old',
	SUM(Case WHEN ISNULL(IsReturnTxn,0)=0 THEN 1 ELSE -1 END) 'TotalQty',
	SUM(TotalBillAmount) 'TotalBillAmt',
	SUm(IncentiveAmount) 'TotalIncentiveAmount', SUM(TDSAmount) 'TotalTDSAmount'

FROM INCTV_TXN_IncentiveFractionItem incItm

WHERE  IncentiveReceiverId = @EmployeeId 
AND Convert(Date,incItm.TransactionDate) Between @FromDate AND @ToDate
and ISNULL(IsActive,0)=1
AND ((@IsRefferalOnly = 1 AND incItm.IncentiveType = 'referral')
OR (@IsRefferalOnly = 0)
)

Group by ItemName
END