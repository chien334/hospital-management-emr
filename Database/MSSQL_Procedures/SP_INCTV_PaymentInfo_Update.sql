--End:Sud-17Mar'20-- For incentive-TDS Percentage---

--Anish: Start: 18 March, Bill PaymentInfo update done from SP----
CREATE PROCEDURE [dbo].[SP_INCTV_PaymentInfo_Update]  --EXEC SP_Report_INCTV_ReferralItemsSummary '2020-01-17','2020-02-17',93
	@FromDate date = NULL,
    @ToDate date = NULL,
    @EmployeeId int = NULL,
	@paymentInfoId int = NULL
AS
BEGIN
	Update INCTV_TXN_IncentiveFractionItem set IsPaymentProcessed=1, PaymentInfoId=@paymentInfoId
	WHERE IncentiveReceiverId = @EmployeeId AND Convert(Date,TransactionDate) Between @FromDate AND @ToDate;
	
	select 'success' as Result
END