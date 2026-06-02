CREATE PROCEDURE [dbo].[SP_Report_BILDSB_DailyRevenueTrend]
AS
/*
  Need to check the data correctness of this storedProc: sudarshan:9Jul2017
*/
BEGIN
  declare @Today date= Convert(date,getdate()) ,@StartDate datetime = Convert(date,getdate()-6)

  select d.Dates as 'Date', 
  ISNULL(bil.TotalAmount,0) - ISNULL(billCancel.CancelAmount,0) - ISNULL(billRet.ReturnAmount,0)    'Revenue'
  from [FN_COMMON_GetAllDatesBetweenRange] (@StartDate,@Today) d

       LEFT JOIN   
	   (   select convert(date,createdOn) BillDate, sum(isnull(totalAmount,0)) TotalAmount
			from BIL_TXN_BillingTransactionItems
			group by convert(date,createdOn)
			
	  ) bil

	    ON d.Dates = bil.BillDate
		LEFT  JOIN
		( 
		   SELECT CONVERT(DATE,CancelledOn) CancelDate, sum(isnull(totalAmount,0)) CancelAmount
			FROM BIL_TXN_BillingTransactionItems
			WHERE  BillStatus='cancel' 
			 AND CONVERT(DATE,CancelledOn) BETWEEN @StartDate and @Today
			 GROUP BY CONVERT(DATE,CancelledOn) 

		) billCancel

		ON d.Dates=billCancel.CancelDate

		 LEFT  JOIN
		( 
		   select convert(date,ReturnDate)as ReturnDate,Sum(ISNULL(TotalAmount,0)) 'ReturnAmount' 
		   from BIL_TXN_BillingReturn
		   Where convert(date,ReturnDate) BETWEEN @StartDate and @Today
		   Group by convert(date,ReturnDate)

		) billRet
		ON d.Dates=billRet.ReturnDate


    order by d.Dates DESC


End--end of SP