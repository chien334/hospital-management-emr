CREATE PROCEDURE [dbo].[SP_Report_PHRM_Daily_StockValue]
AS
/*
*/
BEGIN
  Declare @Today date= Convert(date,getdate()) ,@StartDate datetime = Convert(date,getdate()-6)

  select d.Dates as 'Date',ISNULL(inv.Quantity,0) 'Quantity'
  from [FN_COMMON_GetAllDatesBetweenRange] (@StartDate,@Today) d
  LEFT JOIN   
	   (   select convert(date,createdOn) BillDate, Sum(isnull(Quantity,0)) Quantity
			from PHRM_StockTxnItems
			where InOut='out'
			group by convert(date,createdOn)
			
	  ) inv
ON d.Dates = inv.BillDate
  order by d.Dates DESC
End--end of SP